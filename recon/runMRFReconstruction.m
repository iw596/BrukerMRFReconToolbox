function result = runMRFReconstruction(MRFParams,settings,runtimeOptions)
% runMRFReconstruction  Skeleton entry point for 2D/3D MRF reconstruction.
%
%   This function wires the reconstruction pipeline together:
%   - build a reconstruction context
%   - build the geometry abstraction (2D or 3D)
%   - build the selected regularizer
%   - run the ADMM skeleton solver
%
%   The implementation is intentionally modular so new data models and
%   regularizers can be added without changing the GUI.

context = buildMRFReconContext(settings);
geometry = buildMRFReconGeometry(context);
regularizer = buildMRFReconRegularizer(context);
reconTarget = string(getfield_default(settings, 'ReconstructionTarget', 'MRF'));

if nargin < 3 || isempty(runtimeOptions)
    runtimeOptions = struct();
end

disp("Preparing MRF data for reconstruction....")
[data, samplingmask] = prepareMRFData(MRFParams);

disp("Starting reconstruction...")

if strcmpi(reconTarget, 'T1')
    result = runT1ReconstructionAndFitting(data, MRFParams, settings, context, geometry, regularizer, runtimeOptions);
else
    if strcmp(settings.MRFReconMode, 'Direct')
        %% Direct recon pathway
        disp("Direct reconstruction of MRF data pathway")
        result = runDirectMRFReconstruction(data,context, geometry);
    else
        %% Sub-space recon pathway
        result = runADMMReconstruction(context, geometry, regularizer);
    end
end
if isempty(result) || ~isstruct(result)
    result = struct();
end
if ~isfield(result, 'Status') || isempty(result.Status)
    result.Status = 'Completed';
end
if ~isfield(result, 'Log') || isempty(result.Log)
    result.Log = {'Reconstruction completed.'};
end
result.samplingmask = samplingmask;

if logical(getfield_default(settings, 'EstimateMask', false)) && isfield(result, 'images') && ~isempty(result.images)
    result.mask = buildThresholdMask(result.images);
    if islogical(result.mask) && any(result.mask(:))
        result.Log{end+1} = 'Binary mask estimated from mean reconstructed image magnitude time series.';
    else
        result.Log{end+1} = 'Binary mask estimation produced an empty mask.';
    end
end

disp("Reconstruction finished...")


%% Perform dictionary matching
if strcmpi(reconTarget, 'MRF')
    disp("Starting dictionary matching....")

    if ~isfield(result, 'images') || isempty(result.images)
        error('runMRFReconstruction:MissingReconImages', ...
            'No reconstructed images available for dictionary matching.');
    end

    dictionaryPath = getfield_default(settings, 'DictionaryPath', '');
    if isempty(dictionaryPath) || ~isfile(dictionaryPath)
        error('runMRFReconstruction:DictionaryRequired', ...
            'A valid dictionary file must be loaded before MRF matching.');
    end

    S = load(dictionaryPath);
    if ~isfield(S, 'dict') || ~isfield(S, 'LUT')
        error('runMRFReconstruction:InvalidDictionaryFile', ...
            'Dictionary MAT file must contain variables named "dict" and "LUT".');
    end

    matchOptions = struct();
    matchOptions.EstimateB1Map = logical(getfield_default(settings, 'EstimateB1Map', false));
    matchOptions.B1Map = getfield_default(settings, 'B1Map', []);
    matchOptions.parallelFlag = logical(getfield_default(settings, 'ParallelMatching', false));
    matchOptions.ExportComplexM0 = logical(getfield_default(settings, 'SaveComplexM0', false));
    matchOptions.ProgressCallback = getfield_default(runtimeOptions, 'MatchingProgressCallback', []);
    matchOptions.ProgressUpdateInterval = getfield_default(runtimeOptions, 'MatchingProgressUpdateInterval', []);

    % Call with name-value pairs instead of struct to ensure compatibility
    matchRes = MRFDictMatching(result.images, S.dict, S.LUT, ...
        'EstimateB1Map', matchOptions.EstimateB1Map, ...
        'B1Map', matchOptions.B1Map, ...
        'parallelFlag', matchOptions.parallelFlag, ...
        'ExportComplexM0', matchOptions.ExportComplexM0, ...
        'ProgressCallback', matchOptions.ProgressCallback, ...
        'ProgressUpdateInterval', matchOptions.ProgressUpdateInterval);
    result.Matching = matchRes;
    result.ParameterMaps = buildParameterMaps(matchRes);
    if isfield(result, 'mask') && ~isempty(result.mask)
        result.ParameterMaps.mask = logical(result.mask);
    end
    result.DictionaryPath = dictionaryPath;

    result.Log{end+1} = sprintf('Dictionary matched using %s.', dictionaryPath);
    disp("Dictionary matching finished...")
elseif strcmpi(reconTarget, 'T1')
    if ~isfield(result, 'ParameterMaps') || ~isstruct(result.ParameterMaps) || ~isfield(result.ParameterMaps, 'T1')
        result.Log{end+1} = 'T1 target selected: fitting pathway executed but no T1 map was generated.';
    else
        result.Log{end+1} = 'T1 target selected: reconstruction and T1 fitting pathway executed.';
    end
else
    result.Log{end+1} = 'Dictionary matching skipped (target is not MRF).';
end

if logical(getfield_default(settings, 'SaveOutputs', false))
    saveBasePath = getfield_default(settings, 'SaveBasePath', '');
    if isempty(saveBasePath)
        saveBasePath = fullfile(pwd, ['mrf_recon_' datestr(now, 'yyyymmdd_HHMMSS')]);
    end
    saveBundle = logical(getfield_default(settings, 'SaveResultBundle', false));
    [imageFile, mapFile, bundleFile] = saveResultOutputs(result, saveBasePath, settings, saveBundle);
    result.OutputFiles = struct('Images', imageFile, 'Maps', mapFile, 'Bundle', bundleFile);
    result.Log{end+1} = sprintf('Saved images to %s', imageFile);
    if ~isempty(mapFile)
        result.Log{end+1} = sprintf('Saved maps to %s', mapFile);
    end
    if ~isempty(bundleFile)
        result.Log{end+1} = sprintf('Saved recon bundle to %s', bundleFile);
    end
end

end

function mask = buildThresholdMask(images)
mask = [];
if isempty(images)
    return;
end

imgAbs = abs(double(images));
if ndims(imgAbs) >= 4
    % Estimate mask from the mean signal across the MRF time-series dimension.
    refImg = mean(imgAbs, 4);
else
    refImg = imgAbs;
end

finiteVals = refImg(isfinite(refImg));
if isempty(finiteVals)
    return;
end

threshold = 0.05 * max(finiteVals);
if ~isfinite(threshold) || threshold <= 0
    mask = false(size(refImg));
    return;
end

mask = refImg > threshold;
mask = logical(mask);
end

function parameterMaps = buildParameterMaps(matchRes)
parameterMaps = struct();
if isempty(matchRes) || ~isstruct(matchRes)
    return;
end
if isfield(matchRes, 'MRFT1Map')
    parameterMaps.T1 = matchRes.MRFT1Map;
end
if isfield(matchRes, 'MRFT2Map')
    parameterMaps.T2 = matchRes.MRFT2Map;
end
if isfield(matchRes, 'MRFM0Map')
    parameterMaps.M0 = matchRes.MRFM0Map;
end
if isfield(matchRes, 'MRFB1Map')
    parameterMaps.B1 = matchRes.MRFB1Map;
end
if isfield(matchRes, 'indexMap')
    parameterMaps.Index = matchRes.indexMap;
end
end

function value = getfield_default(s, field, defaultValue)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    value = s.(field);
else
    value = defaultValue;
end
end
