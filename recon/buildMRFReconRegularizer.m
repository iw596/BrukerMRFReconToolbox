function regularizer = buildMRFReconRegularizer(context)
% buildMRFReconRegularizer  Create regularizer skeleton(s) for ADMM.
%
%   The returned struct supports one or more regularizer components. Prox
%   and Evaluate are placeholders and can be replaced by true operators.

modes = string(context.RegularizationModes);
if isempty(modes)
    modes = string(context.RegularizationMode);
end

weights = resolveRegularizationWeights(context, numel(modes));

components = cell(numel(modes), 1);
for iMode = 1:numel(modes)
    components{iMode} = buildSingleRegularizer(modes(iMode), context, weights(iMode));
end

if numel(components) == 1
    regularizer = components{1};
    regularizer.Components = components;
    regularizer.Weights = weights;
    return;
end

regularizer = struct();
regularizer.Mode = modes;
regularizer.Lambda = context.Lambda;
regularizer.Weights = weights;
regularizer.Components = components;
regularizer.Prox = @(x, rho) compositeProx(components, x, rho);
regularizer.Evaluate = @(x) compositeEvaluate(components, x);
regularizer.Description = ['Combined regularizers: ' char(strjoin(modes, ', '))];
end

function regularizer = buildSingleRegularizer(modeName, context, weight)
mode = lower(strtrim(char(modeName)));

regularizer = struct();
regularizer.Mode = string(modeName);
regularizer.Lambda = context.Lambda;
regularizer.Weight = double(weight);
regularizer.EffectiveLambda = regularizer.Lambda * regularizer.Weight;
regularizer.Prox = [];
regularizer.Evaluate = [];
regularizer.Description = '';

switch mode
    case 'locally-low rank'
        regularizer.Description = 'Locally low-rank regularizer';
        regularizer.BlockSize = context.BlockSize;
        regularizer.Stride = context.Stride;
        regularizer.Prox = @(x, rho) llrProxND(x, rho, regularizer.Lambda, regularizer.Weight, context, regularizer.BlockSize, regularizer.Stride);
        regularizer.Evaluate = @(x) llrEvaluateND(x, context, regularizer.BlockSize, regularizer.Stride);

    case 'wavelet'
        regularizer.Description = 'Wavelet sparsity regularizer';
        [waveletName, waveletLevels] = resolveWaveletSettings(context);
        regularizer.WaveletName = waveletName;
        regularizer.WaveletLevels = waveletLevels;
        regularizer.Prox = @(x, rho) waveletProxND(x, rho, regularizer.Lambda, regularizer.Weight, context, waveletName, waveletLevels);
        regularizer.Evaluate = @(x) waveletEvaluateND(x, context, waveletName, waveletLevels);

    case 'total variation'
        regularizer.Description = 'Total variation regularizer';
        regularizer.Prox = @(x, rho) tvProxND(x, rho, regularizer.Lambda, regularizer.Weight, context);
        regularizer.Evaluate = @(x) tvEvaluateND(x, context);

    otherwise
        error('buildMRFReconRegularizer:UnknownMode', ...
            'Unknown regularizer mode: %s', char(modeName));
end
end

function weights = resolveRegularizationWeights(context, nModes)
weights = ones(nModes, 1);
if ~(isstruct(context) && isfield(context, 'RegularizationWeights'))
    return;
end

raw = context.RegularizationWeights;
if isempty(raw)
    return;
end

raw = double(raw(:));
raw = raw(isfinite(raw) & raw > 0);
if isempty(raw)
    return;
end

if numel(raw) == 1
    weights = repmat(raw, nModes, 1);
else
    nCopy = min(numel(raw), nModes);
    weights(1:nCopy) = raw(1:nCopy);
end
end

function xOut = compositeProx(components, xIn, rho)
xOut = xIn;
for iComp = 1:numel(components)
    xOut = components{iComp}.Prox(xOut, rho);
end
end

function value = compositeEvaluate(components, x)
value = 0;
for iComp = 1:numel(components)
    value = value + components{iComp}.Evaluate(x);
end
end

function [waveletName, waveletLevels] = resolveWaveletSettings(context)
waveletName = 'db2';
waveletLevels = [];

if isstruct(context) && isfield(context, 'Settings') && isstruct(context.Settings)
    settings = context.Settings;
    if isfield(settings, 'WaveletName') && ~isempty(settings.WaveletName)
        waveletName = char(string(settings.WaveletName));
    end
    if isfield(settings, 'WaveletLevels') && ~isempty(settings.WaveletLevels)
        waveletLevels = double(settings.WaveletLevels);
    end
end

if isempty(waveletName)
    waveletName = 'db2';
end

if ~isempty(waveletLevels)
    waveletLevels = round(waveletLevels(1));
    if ~isfinite(waveletLevels) || waveletLevels < 1
        waveletLevels = [];
    end
end
end

function xOut = waveletProxND(xIn, rho, lambda, weight, context, waveletName, waveletLevels)
xOut = xIn;
if isempty(xIn)
    return;
end

if isempty(rho) || ~isfinite(rho) || rho <= 0
    rho = 1;
end
tau = double(lambda) * double(weight) / double(rho);
if ~isfinite(tau) || tau <= 0
    return;
end

[spatialDims, spatialSize, nExtra] = getSpatialLayout(size(xIn), context);
if isempty(spatialDims) || any(spatialSize < 2)
    xOut = softThresholdComplex(xIn, tau);
    return;
end

xReshaped = reshape(xIn, [spatialSize, nExtra]);
xProcessed = xReshaped;
for iVol = 1:nExtra
    xProcessed(:, :, :, iVol) = waveletShrinkOneVolume( ...
        xReshaped(:, :, :, iVol), tau, waveletName, waveletLevels, numel(spatialDims));
end

xOut = reshape(xProcessed, size(xIn));
end

function value = waveletEvaluateND(xIn, context, waveletName, waveletLevels)
value = 0;
if isempty(xIn)
    return;
end

[spatialDims, spatialSize, nExtra] = getSpatialLayout(size(xIn), context);
if isempty(spatialDims) || any(spatialSize < 2)
    value = sum(abs(xIn(:)));
    return;
end

xReshaped = reshape(xIn, [spatialSize, nExtra]);
for iVol = 1:nExtra
    coeffs = waveletDecomposeOneVolume(xReshaped(:, :, :, iVol), waveletName, waveletLevels, numel(spatialDims));
    if isempty(coeffs)
        value = value + sum(abs(xReshaped(:, :, :, iVol)), 'all');
    else
        for iLevel = 2:numel(coeffs)
            detailStruct = coeffs{iLevel};
            detailFields = fieldnames(detailStruct);
            for iField = 1:numel(detailFields)
                value = value + sum(abs(detailStruct.(detailFields{iField})), 'all');
            end
        end
    end
end
end

function xOut = llrProxND(xIn, rho, lambda, weight, context, blockSize, stride)
xOut = xIn;
if isempty(xIn)
    return;
end

if isempty(rho) || ~isfinite(rho) || rho <= 0
    rho = 1;
end
tau = double(lambda) * double(weight) / double(rho);
if ~isfinite(tau) || tau <= 0
    return;
end

[spatialDims, spatialSize, nExtra] = getSpatialLayout(size(xIn), context);
if isempty(spatialDims)
    return;
end

nSpatialDims = numel(spatialDims);
if nExtra < 1
    nExtra = 1;
end

xReshaped = reshape(xIn, [spatialSize, nExtra]);
accum = zeros(size(xReshaped), 'like', xReshaped);
weightMap = zeros(spatialSize, 'double');

blockVec = resolveSpatialParam(blockSize, nSpatialDims);
strideVec = resolveSpatialParam(stride, nSpatialDims);

startX = buildStartIndices(spatialSize(1), blockVec(1), strideVec(1));
startY = buildStartIndices(spatialSize(2), blockVec(2), strideVec(2));
if nSpatialDims == 3
    startZ = buildStartIndices(spatialSize(3), blockVec(3), strideVec(3));
else
    startZ = 1;
end

for ix0 = startX
    ix = ix0:min(ix0 + blockVec(1) - 1, spatialSize(1));
    for iy0 = startY
        iy = iy0:min(iy0 + blockVec(2) - 1, spatialSize(2));
        for iz0 = startZ
            if nSpatialDims == 3
                iz = iz0:min(iz0 + blockVec(3) - 1, spatialSize(3));
            else
                iz = 1;
            end

            block = xReshaped(ix, iy, iz, :);
            mat = reshape(block, [], nExtra);

            [U, S, V] = svd(mat, 'econ');
            sing = diag(S);
            sing = max(sing - tau, 0);
            keep = sing > 0;

            if any(keep)
                rec = U(:, keep) * (diag(sing(keep)) * V(:, keep)');
            else
                rec = zeros(size(mat), 'like', mat);
            end

            blockRec = reshape(rec, [numel(ix), numel(iy), numel(iz), nExtra]);
            accum(ix, iy, iz, :) = accum(ix, iy, iz, :) + blockRec;
            weightMap(ix, iy, iz) = weightMap(ix, iy, iz) + 1;
        end
    end
end

weightMap(weightMap <= 0) = 1;
xReshaped = bsxfun(@rdivide, accum, weightMap);
xOut = reshape(xReshaped, size(xIn));
end

function value = llrEvaluateND(xIn, context, blockSize, stride)
value = 0;
if isempty(xIn)
    return;
end

[spatialDims, spatialSize, nExtra] = getSpatialLayout(size(xIn), context);
if isempty(spatialDims)
    return;
end

nSpatialDims = numel(spatialDims);
if nExtra < 1
    nExtra = 1;
end

xReshaped = reshape(xIn, [spatialSize, nExtra]);
blockVec = resolveSpatialParam(blockSize, nSpatialDims);
strideVec = resolveSpatialParam(stride, nSpatialDims);

startX = buildStartIndices(spatialSize(1), blockVec(1), strideVec(1));
startY = buildStartIndices(spatialSize(2), blockVec(2), strideVec(2));
if nSpatialDims == 3
    startZ = buildStartIndices(spatialSize(3), blockVec(3), strideVec(3));
else
    startZ = 1;
end

for ix0 = startX
    ix = ix0:min(ix0 + blockVec(1) - 1, spatialSize(1));
    for iy0 = startY
        iy = iy0:min(iy0 + blockVec(2) - 1, spatialSize(2));
        for iz0 = startZ
            if nSpatialDims == 3
                iz = iz0:min(iz0 + blockVec(3) - 1, spatialSize(3));
            else
                iz = 1;
            end

            block = xReshaped(ix, iy, iz, :);
            mat = reshape(block, [], nExtra);
            value = value + sum(svd(mat, 'econ'));
        end
    end
end
end

function xOut = tvProxND(xIn, rho, lambda, weight, context)
xOut = xIn;
if isempty(xIn)
    return;
end

if isempty(rho) || ~isfinite(rho) || rho <= 0
    rho = 1;
end
tau = double(lambda) * double(weight) / double(rho);
if ~isfinite(tau) || tau <= 0
    return;
end

nIter = 25;
if isstruct(context) && isfield(context, 'Settings') && isstruct(context.Settings)
    candidate = getfield_default(context.Settings, 'TVIterations', nIter);
    candidate = double(candidate);
    if isfinite(candidate) && candidate >= 1
        nIter = round(candidate);
    end
end

[spatialDims, spatialSize, nExtra] = getSpatialLayout(size(xIn), context);
if isempty(spatialDims)
    return;
end

nSpatialDims = numel(spatialDims);
if nExtra < 1
    nExtra = 1;
end

xReshaped = reshape(xIn, [spatialSize, nExtra]);
for iVol = 1:nExtra
    vol = xReshaped(:, :, :, iVol);
    if isreal(vol)
        xReshaped(:, :, :, iVol) = tvDenoiseROF(vol, tau, nSpatialDims, nIter);
    else
        realPart = tvDenoiseROF(real(vol), tau, nSpatialDims, nIter);
        imagPart = tvDenoiseROF(imag(vol), tau, nSpatialDims, nIter);
        xReshaped(:, :, :, iVol) = complex(realPart, imagPart);
    end
end

xOut = reshape(xReshaped, size(xIn));
end

function value = tvEvaluateND(xIn, context)
value = 0;
if isempty(xIn)
    return;
end

[spatialDims, spatialSize, nExtra] = getSpatialLayout(size(xIn), context);
if isempty(spatialDims)
    return;
end

nSpatialDims = numel(spatialDims);
if nExtra < 1
    nExtra = 1;
end

xReshaped = reshape(xIn, [spatialSize, nExtra]);
for iVol = 1:nExtra
    g = gradientND(xReshaped(:, :, :, iVol), nSpatialDims);
    value = value + sum(abs(g(:)));
end
end

function out = tvDenoiseROF(f, weight, nSpatialDims, nIter)
if weight <= 0
    out = f;
    return;
end

p = zeros([size(f), nSpatialDims], 'like', f);
sigma = 1 / (2 * nSpatialDims);

for iIter = 1:nIter
    divP = divergenceND(p, nSpatialDims);
    u = divP - (f ./ weight);
    g = gradientND(u, nSpatialDims);
    gNorm = sqrt(sum(g .* g, nSpatialDims + 1));
    denom = 1 + sigma .* gNorm;

    for iDim = 1:nSpatialDims
        pComp = p(:, :, :, iDim) + sigma .* g(:, :, :, iDim);
        p(:, :, :, iDim) = pComp ./ denom;
    end
end

out = f - weight .* divergenceND(p, nSpatialDims);
end

function g = gradientND(x, nSpatialDims)
g = zeros([size(x), nSpatialDims], 'like', x);

for iDim = 1:nSpatialDims
    shifted = circshift(x, -1, iDim);
    d = shifted - x;

    idxLast = repmat({':'}, 1, ndims(x));
    idxLast{iDim} = size(x, iDim);
    d(idxLast{:}) = 0;

    g(:, :, :, iDim) = d;
end
end

function divVal = divergenceND(p, nSpatialDims)
targetSize = size(p);
targetSize = targetSize(1:end-1);
divVal = zeros(targetSize, 'like', p);

for iDim = 1:nSpatialDims
    pComp = p(:, :, :, iDim);
    back = pComp - circshift(pComp, 1, iDim);

    idxFirst = repmat({':'}, 1, ndims(pComp));
    idxFirst{iDim} = 1;
    back(idxFirst{:}) = pComp(idxFirst{:});

    divVal = divVal + back;
end
end

function paramVec = resolveSpatialParam(raw, nSpatialDims)
if isempty(raw) || ~isnumeric(raw)
    raw = 1;
end
raw = round(double(raw(:)));
raw(~isfinite(raw) | raw < 1) = 1;

if numel(raw) == 1
    paramVec = repmat(raw, nSpatialDims, 1);
else
    paramVec = ones(nSpatialDims, 1);
    nCopy = min(numel(raw), nSpatialDims);
    paramVec(1:nCopy) = raw(1:nCopy);
end
end

function starts = buildStartIndices(n, blockSize, stride)
if n <= blockSize
    starts = 1;
    return;
end

starts = 1:stride:(n - blockSize + 1);
lastStart = n - blockSize + 1;
if starts(end) ~= lastStart
    starts = [starts, lastStart];
end
end

function outVol = waveletShrinkOneVolume(inVol, tau, waveletName, waveletLevels, nSpatialDims)
coeffs = waveletDecomposeOneVolume(inVol, waveletName, waveletLevels, nSpatialDims);
if isempty(coeffs)
    outVol = softThresholdComplex(inVol, tau);
    return;
end

for iLevel = 2:numel(coeffs)
    detailStruct = coeffs{iLevel};
    detailFields = fieldnames(detailStruct);
    for iField = 1:numel(detailFields)
        fieldName = detailFields{iField};
        detailStruct.(fieldName) = softThresholdComplex(detailStruct.(fieldName), tau);
    end
    coeffs{iLevel} = detailStruct;
end

outVol = waverecn(coeffs, waveletName);
if ~isequal(size(outVol), size(inVol))
    outVol = cropToSize(outVol, size(inVol));
end
end

function coeffs = waveletDecomposeOneVolume(inVol, waveletName, waveletLevels, nSpatialDims)
coeffs = [];
if exist('wavedecn', 'file') ~= 2 || exist('waverecn', 'file') ~= 2
    return;
end

level = resolveWaveletLevel(size(inVol), waveletName, waveletLevels, nSpatialDims);
if level < 1
    return;
end

coeffs = wavedecn(inVol, level, waveletName);
end

function level = resolveWaveletLevel(volSize, waveletName, requestedLevel, nSpatialDims)
spatialSize = double(volSize(1:nSpatialDims));
minDim = min(spatialSize);
if isempty(minDim) || minDim < 2
    level = 0;
    return;
end

maxLevel = max(1, floor(log2(minDim)) - 1);

if exist('wmaxlev', 'file') == 2
    try
        if nSpatialDims == 2
            maxLevel = max(1, wmaxlev(spatialSize, waveletName));
        else
            maxLevel = max(1, min(wmaxlev(spatialSize(1:2), waveletName), floor(log2(spatialSize(3)))));
        end
    catch
        % Fall back to conservative level estimate.
    end
end

if isempty(requestedLevel)
    level = min(3, maxLevel);
else
    level = min(maxLevel, max(1, round(double(requestedLevel(1)))));
end
end

function [spatialDims, spatialSize, nExtra] = getSpatialLayout(inputSize, context)
is3D = isstruct(context) && isfield(context, 'Dimensionality') && strcmpi(string(context.Dimensionality), "3d");

if is3D
    spatialDims = 1:3;
else
    spatialDims = 1:2;
end

if numel(inputSize) < numel(spatialDims)
    spatialDims = [];
    spatialSize = inputSize;
    nExtra = 1;
    return;
end

inputSize = [inputSize, ones(1, max(0, numel(spatialDims) + 1 - numel(inputSize)))];
spatialSize = inputSize(spatialDims);

extraDims = inputSize(numel(spatialDims)+1:end);
if isempty(extraDims)
    nExtra = 1;
else
    nExtra = prod(extraDims);
end

if numel(spatialSize) == 2
    spatialSize = [spatialSize 1];
end
end

function value = getfield_default(s, field, defaultValue)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    value = s.(field);
else
    value = defaultValue;
end
end

function y = softThresholdComplex(x, tau)
mag = abs(x);
y = zeros(size(x), 'like', x);
mask = mag > tau;
if any(mask(:))
    y(mask) = ((mag(mask) - tau) ./ mag(mask)) .* x(mask);
end
end

function cropped = cropToSize(inputVol, targetSize)
idx = cell(1, numel(targetSize));
for iDim = 1:numel(targetSize)
    idx{iDim} = 1:min(targetSize(iDim), size(inputVol, iDim));
end
cropped = inputVol(idx{:});

if ~isequal(size(cropped), targetSize)
    padded = zeros(targetSize, 'like', inputVol);
    idx = cell(1, numel(targetSize));
    for iDim = 1:numel(targetSize)
        idx{iDim} = 1:size(cropped, iDim);
    end
    padded(idx{:}) = cropped;
    cropped = padded;
end
end
