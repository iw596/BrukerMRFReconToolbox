function regularizer = buildMRFReconRegularizer(context)
% buildMRFReconRegularizer  Create regularizer skeleton(s) for ADMM.
%
%   The returned struct supports one or more regularizer components. Prox
%   and Evaluate are placeholders and can be replaced by true operators.

modes = string(context.RegularizationModes);
if isempty(modes)
    modes = string(context.RegularizationMode);
end

components = cell(numel(modes), 1);
for iMode = 1:numel(modes)
    components{iMode} = buildSingleRegularizer(modes(iMode), context);
end

if numel(components) == 1
    regularizer = components{1};
    return;
end

regularizer = struct();
regularizer.Mode = modes;
regularizer.Lambda = context.Lambda;
regularizer.Components = components;
regularizer.Prox = @(x, rho) compositeProx(components, x, rho);
regularizer.Evaluate = @(x) compositeEvaluate(components, x);
regularizer.Description = ['Combined regularizers: ' char(strjoin(modes, ', '))];
end

function regularizer = buildSingleRegularizer(modeName, context)
mode = lower(strtrim(char(modeName)));

regularizer = struct();
regularizer.Mode = string(modeName);
regularizer.Lambda = context.Lambda;
regularizer.Prox = [];
regularizer.Evaluate = [];
regularizer.Description = '';

switch mode
    case 'locally-low rank'
        regularizer.Description = 'Locally low-rank regularizer';
        regularizer.BlockSize = context.BlockSize;
        regularizer.Stride = context.Stride;
        regularizer.Prox = @(x, rho) x;  % TODO: singular-value thresholding on patches
        regularizer.Evaluate = @(x) 0;

    case 'wavelet'
        regularizer.Description = 'Wavelet sparsity regularizer';
        [waveletName, waveletLevels] = resolveWaveletSettings(context);
        regularizer.WaveletName = waveletName;
        regularizer.WaveletLevels = waveletLevels;
        regularizer.Prox = @(x, rho) waveletProxND(x, rho, regularizer.Lambda, context, waveletName, waveletLevels);
        regularizer.Evaluate = @(x) waveletEvaluateND(x, context, waveletName, waveletLevels);

    case 'total variation'
        regularizer.Description = 'Total variation regularizer';
        regularizer.Prox = @(x, rho) x;  % TODO: TV proximal operator
        regularizer.Evaluate = @(x) 0;

    otherwise
        error('buildMRFReconRegularizer:UnknownMode', ...
            'Unknown regularizer mode: %s', char(modeName));
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

function xOut = waveletProxND(xIn, rho, lambda, context, waveletName, waveletLevels)
xOut = xIn;
if isempty(xIn)
    return;
end

if isempty(rho) || ~isfinite(rho) || rho <= 0
    rho = 1;
end
tau = double(lambda) / double(rho);
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
