function res = MRFDictMatching(imgs,dict,LUT,options)
    arguments
        imgs = [];
        dict = [];
        LUT = [];
        options.EstimateB1Map = false;
        options.B1Map = [];
        options.parallelFlag = false;
        options.ExportComplexM0 = false;
        options.ProgressCallback = [];
        options.ProgressUpdateInterval = [];
    end
    
    
    %% Extract spatial dimensions
    [NRO,NPE,NSLI,NTime] = size(imgs);

    %% Handle B1 map
    if (isempty(options.B1Map))
        B1Map = ones([NRO,NPE,NSLI]); % Assume perfect B1 field
    else
        B1Map = options.B1Map;
    end

    %% Normalise the dictioanry
    dictNorm = NormaliseMRFDictionary(dict);
    dictEnergy = sum(abs(dict).^2, 1);

    %% Preallocate outputs
    T1Map = zeros(NRO, NPE, NSLI, 'like', real(imgs));
    T2Map = zeros(NRO, NPE, NSLI, 'like', real(imgs));
    M0Map = zeros(NRO, NPE, NSLI, 'like', real(imgs));
    exportComplexM0 = logical(options.ExportComplexM0);
    if exportComplexM0
        M0MapComplex = complex(zeros(NRO, NPE, NSLI, 'like', real(imgs)), zeros(NRO, NPE, NSLI, 'like', real(imgs)));
    end
    indexMap = zeros(NRO, NPE, NSLI);
    MRFMask = zeros(NRO, NPE, NSLI);
    if (options.EstimateB1Map == true)
        MRFB1Map = zeros(NRO, NPE, NSLI, 'like', real(imgs));
    end

    if size(LUT,2) < 2
        error('MRFDictMatching:InvalidLUT', 'LUT must have at least 2 columns (T1, T2).');
    end
    if (options.EstimateB1Map == false) && size(LUT,2) < 3
        error('MRFDictMatching:InvalidLUT', 'LUT must have 3 columns (T1, T2, B1) when B1 is not estimated.');
    end

    if ~options.EstimateB1Map
        [uniqueB1Values, ~, lutB1Group] = unique(LUT(:,3), 'sorted');
        nB1Groups = numel(uniqueB1Values);
        dictByB1 = cell(nB1Groups, 1);
        lutByB1 = cell(nB1Groups, 1);
        globalIdxByB1 = cell(nB1Groups, 1);

        for b1Group = 1:nB1Groups
            groupIdx = find(lutB1Group == b1Group);
            globalIdxByB1{b1Group} = groupIdx;
            dictByB1{b1Group} = dictNorm(:, groupIdx);
            lutByB1{b1Group} = LUT(groupIdx, :);
        end

        [~, nearestB1GroupMap] = min(abs(reshape(B1Map, [], 1) - reshape(uniqueB1Values, 1, [])), [], 2);
        nearestB1GroupMap = reshape(nearestB1GroupMap, [NRO, NPE, NSLI]);
    end

    useParallel = logical(options.parallelFlag) && ensureThreadedParfor();
    progressCallback = options.ProgressCallback;
    progressTotal = NRO;
    progressStride = resolveProgressStride(progressTotal, options.ProgressUpdateInterval);

    if ~isempty(progressCallback)
        callProgressCallback(progressCallback, 0, progressTotal);
    end

    progressQueue = [];
    if useParallel && ~isempty(progressCallback)
        progressTracker('reset', progressStride, progressTotal, progressCallback);
        progressQueue = parallel.pool.DataQueue;
        afterEach(progressQueue, @(~) progressTracker('tick'));
    end
    
    %% Begin matching
  
    if ~options.EstimateB1Map
        if ~useParallel
            for i = 1:NRO
                rowSignals = reshape(permute(imgs(i,:,:,:), [4, 2, 3, 1]), NTime, []);
                rowB1Groups = reshape(nearestB1GroupMap(i,:,:), 1, []);

                [rowT1, rowT2, rowM0, rowM0Complex, rowMask, rowIndex] = matchB1BinnedRow( ...
                    rowSignals, rowB1Groups, dictByB1, globalIdxByB1, LUT, dict, dictEnergy, exportComplexM0);

                T1Map(i,:,:) = reshape(rowT1, [1, NPE, NSLI]);
                T2Map(i,:,:) = reshape(rowT2, [1, NPE, NSLI]);
                M0Map(i,:,:) = reshape(rowM0, [1, NPE, NSLI]);
                if exportComplexM0
                    M0MapComplex(i,:,:) = reshape(rowM0Complex, [1, NPE, NSLI]);
                end
                MRFMask(i,:,:) = reshape(rowMask, [1, NPE, NSLI]);
                indexMap(i,:,:) = reshape(rowIndex, [1, NPE, NSLI]);

                if ~isempty(progressCallback) && (mod(i, progressStride) == 0 || i == progressTotal)
                    callProgressCallback(progressCallback, i, progressTotal);
                end
            end
        else
            parfor i = 1:NRO
                rowSignals = reshape(permute(imgs(i,:,:,:), [4, 2, 3, 1]), NTime, []);
                rowB1Groups = reshape(nearestB1GroupMap(i,:,:), 1, []);

                [rowT1, rowT2, rowM0, rowM0Complex, rowMask, rowIndex] = matchB1BinnedRow( ...
                    rowSignals, rowB1Groups, dictByB1, globalIdxByB1, LUT, dict, dictEnergy, exportComplexM0);

                T1Map(i,:,:) = reshape(rowT1, [1, NPE, NSLI]);
                T2Map(i,:,:) = reshape(rowT2, [1, NPE, NSLI]);
                M0Map(i,:,:) = reshape(rowM0, [1, NPE, NSLI]);
                if exportComplexM0
                    M0MapComplex(i,:,:) = reshape(rowM0Complex, [1, NPE, NSLI]);
                end
                MRFMask(i,:,:) = reshape(rowMask, [1, NPE, NSLI]);
                indexMap(i,:,:) = reshape(rowIndex, [1, NPE, NSLI]);

                if ~isempty(progressQueue)
                    send(progressQueue, 1);
                end
            end
        end
    else
        if ~useParallel
            for i = 1:NRO
                for j = 1:NPE
                    for k = 1:NSLI
                        voxelSignal = squeeze(imgs(i,j,k,:));
                        % Scale pixel intensity by L2 norm
                        scaleFactor = sqrt(sum(abs(voxelSignal).^2));
                        if ~(isfinite(scaleFactor) && scaleFactor > 0)
                            continue;
                        end
                        normalized_mrfsignal = conj(voxelSignal)/scaleFactor;
                        % Take inner product of MRF signal and sub dictionary to
                        % calculate best match
                        inner_product = abs(squeeze(normalized_mrfsignal)' * (dictNorm));
                        [~, max_index] = max(inner_product);
                        % Save parameters
                        T1Map(i,j,k) = LUT(max_index,1);
                        T2Map(i,j,k) = LUT(max_index,2);
                        [m0Mag, m0Coef] = estimateM0Coefficient(voxelSignal, dict(:, max_index), dictEnergy(max_index));
                        M0Map(i,j,k) = m0Mag;
                        if exportComplexM0
                            M0MapComplex(i,j,k) = m0Coef;
                        end
                        MRFMask(i,j,k) = 1;
                        indexMap(i,j,k) = max_index;
                        MRFB1Map(i,j,k) = LUT(max_index,3);
                    end
                end

                if ~isempty(progressCallback) && (mod(i, progressStride) == 0 || i == progressTotal)
                    callProgressCallback(progressCallback, i, progressTotal);
                end
            end
        else
            parfor i = 1:NRO
                for j = 1:NPE
                    for k = 1:NSLI
                        voxelSignal = squeeze(imgs(i,j,k,:));
                        % Scale pixel intensity by L2 norm
                        scaleFactor = sqrt(sum(abs(voxelSignal).^2));
                        if ~(isfinite(scaleFactor) && scaleFactor > 0)
                            continue;
                        end
                        normalized_mrfsignal = conj(voxelSignal)/scaleFactor;
                        % Take inner product of MRF signal and sub dictionary to
                        % calculate best match
                        inner_product = abs(squeeze(normalized_mrfsignal)' * (dictNorm));
                        [~, max_index] = max(inner_product);
                        % Save parameters
                        T1Map(i,j,k) = LUT(max_index,1);
                        T2Map(i,j,k) = LUT(max_index,2);
                        [m0Mag, m0Coef] = estimateM0Coefficient(voxelSignal, dict(:, max_index), dictEnergy(max_index));
                        M0Map(i,j,k) = m0Mag;
                        if exportComplexM0
                            M0MapComplex(i,j,k) = m0Coef;
                        end
                        MRFMask(i,j,k) = 1;
                        indexMap(i,j,k) = max_index;
                        MRFB1Map(i,j,k) = LUT(max_index,3);
                    end
                end

                if ~isempty(progressQueue)
                    send(progressQueue, 1);
                end
            end
        end
    end

    if ~isempty(progressCallback)
        callProgressCallback(progressCallback, progressTotal, progressTotal);
    end
    progressTracker('clear');

    res.MRFT1Map = T1Map;
    res.MRFT2Map = T2Map;
    res.MRFM0Map = M0Map;
    if exportComplexM0
        res.MRFM0MapComplex = M0MapComplex;
    end
    res.indexMap = indexMap;
    res.MRFMask = MRFMask;
    if (options.EstimateB1Map == true)
        res.MRFB1Map = MRFB1Map;
    end
   
end

function tf = ensureThreadedParfor()
% ensureThreadedParfor  Ensure parfor executes on a thread pool.
% Returns true only when a threads pool is active and usable.

tf = false;

if isempty(which('gcp')) || isempty(which('parpool'))
    warning('MRFDictMatching:ParallelUnavailable', ...
        'Parallel Computing Toolbox is unavailable. Falling back to serial matching.');
    return;
end

try
    pool = gcp('nocreate');

    if isempty(pool)
        pool = parpool('threads');
    else
        isProcessPool = false;
        if isprop(pool, 'Type')
            isProcessPool = strcmpi(pool.Type, 'process');
        end

        if isProcessPool
            delete(pool);
            pool = parpool('threads');
        end
    end

    tf = ~isempty(pool);
catch ME
    warning('MRFDictMatching:ThreadPoolUnavailable', ...
        'Unable to start a thread pool for parfor (%s). Falling back to serial matching.', ME.message);
    tf = false;
end
end

function stride = resolveProgressStride(totalRows, requestedStride)
if ~isempty(requestedStride) && isfinite(requestedStride) && requestedStride >= 1
    stride = max(1, round(requestedStride));
    return;
end

stride = max(1, floor(double(totalRows) / 100));
end

function callProgressCallback(callbackFcn, completedRows, totalRows)
if isempty(callbackFcn)
    return;
end

try
    callbackFcn(double(completedRows), double(totalRows));
catch
    % Swallow callback errors to avoid interrupting matching.
end
end

function progressTracker(action, stride, totalRows, callbackFcn)
persistent completed rowStride rowTotal cb;

if nargin < 1 || isempty(action)
    return;
end

switch lower(string(action))
    case "reset"
        completed = 0;
        if nargin >= 2 && ~isempty(stride)
            rowStride = stride;
        else
            rowStride = 1;
        end
        if nargin >= 3 && ~isempty(totalRows)
            rowTotal = totalRows;
        else
            rowTotal = 1;
        end
        if nargin >= 4
            cb = callbackFcn;
        else
            cb = [];
        end

    case "tick"
        if isempty(completed)
            completed = 0;
        end
        completed = completed + 1;
        if isempty(rowStride)
            rowStride = 1;
        end
        if isempty(rowTotal)
            rowTotal = completed;
        end
        if mod(completed, rowStride) == 0 || completed >= rowTotal
            callProgressCallback(cb, completed, rowTotal);
        end

    case "clear"
        completed = [];
        rowStride = [];
        rowTotal = [];
        cb = [];
end
end

function [m0, coef] = estimateM0Coefficient(voxelSignal, dictAtom, dictAtomEnergy)
% Estimate proton density scale from the matched atom using closed-form LS.

if ~isfinite(dictAtomEnergy) || dictAtomEnergy <= 0
    m0 = 0;
    coef = complex(0);
    return;
end

coef = (dictAtom' * voxelSignal) / dictAtomEnergy;
if ~isfinite(real(coef)) || ~isfinite(imag(coef))
    m0 = 0;
    coef = complex(0);
else
    m0 = abs(coef);
end
end

function [rowT1, rowT2, rowM0, rowM0Complex, rowMask, rowIndex] = matchB1BinnedRow(rowSignals, rowB1Groups, dictByB1, globalIdxByB1, LUT, dict, dictEnergy, exportComplexM0)

nVoxels = size(rowSignals, 2);
rowT1 = zeros(1, nVoxels, 'like', real(rowSignals));
rowT2 = zeros(1, nVoxels, 'like', real(rowSignals));
rowM0 = zeros(1, nVoxels, 'like', real(rowSignals));
rowMask = zeros(1, nVoxels, 'like', real(rowSignals));
rowIndex = zeros(1, nVoxels);

if exportComplexM0
    rowM0Complex = complex(zeros(1, nVoxels, 'like', real(rowSignals)), zeros(1, nVoxels, 'like', real(rowSignals)));
else
    rowM0Complex = [];
end

scaleFactors = sqrt(sum(abs(rowSignals).^2, 1));
validVoxelMask = isfinite(scaleFactors) & (scaleFactors > 0);

if ~any(validVoxelMask)
    return;
end

nB1Groups = numel(dictByB1);
for b1Group = 1:nB1Groups
    groupVoxelMask = (rowB1Groups == b1Group) & validVoxelMask;
    if ~any(groupVoxelMask)
        continue;
    end

    groupVoxelIdx = find(groupVoxelMask);
    groupSignals = rowSignals(:, groupVoxelIdx);
    normalizedSignals = conj(groupSignals) ./ scaleFactors(groupVoxelIdx);

    subDictNorm = dictByB1{b1Group};
    innerProducts = abs(normalizedSignals' * subDictNorm);
    [~, localBestIdx] = max(innerProducts, [], 2);

    candidateGlobalIdx = globalIdxByB1{b1Group};
    matchedGlobalIdx = candidateGlobalIdx(localBestIdx);

    rowT1(groupVoxelIdx) = LUT(matchedGlobalIdx, 1);
    rowT2(groupVoxelIdx) = LUT(matchedGlobalIdx, 2);

    matchedAtoms = dict(:, matchedGlobalIdx);
    matchedEnergies = dictEnergy(matchedGlobalIdx);
    m0Coef = sum(conj(matchedAtoms) .* groupSignals, 1) ./ matchedEnergies;

    finiteCoefMask = isfinite(real(m0Coef)) & isfinite(imag(m0Coef));
    m0Coef(~finiteCoefMask) = complex(0);

    rowM0(groupVoxelIdx) = abs(m0Coef);
    if exportComplexM0
        rowM0Complex(groupVoxelIdx) = m0Coef;
    end

    rowMask(groupVoxelIdx) = 1;
    rowIndex(groupVoxelIdx) = matchedGlobalIdx;
end
end