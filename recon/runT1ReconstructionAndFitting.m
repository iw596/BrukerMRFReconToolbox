function result = runT1ReconstructionAndFitting(data, MRFParams, settings, context, geometry, regularizer, runtimeOptions)
% runT1ReconstructionAndFitting  Skeleton pathway for T1 target.
%
% This helper performs:
%   1) reconstruction (direct or iterative skeleton)
%   2) T1 fitting from reconstructed magnitude time series
%
% The implementation is intentionally conservative and keeps extensive
% fallback behavior while the final T1 fitting workflow is refined.

if nargin < 7 || isempty(runtimeOptions)
    runtimeOptions = struct();
end

if strcmp(settings.MRFReconMode, 'Direct')
    disp("Direct reconstruction for T1 target")
    result = runDirectMRFReconstruction(data, context, geometry);
else
    disp("Iterative reconstruction skeleton for T1 target")
    result = runADMMReconstruction(context, geometry, regularizer);
end

if isempty(result) || ~isstruct(result)
    result = struct();
end
if ~isfield(result, 'Log') || isempty(result.Log)
    result.Log = {};
end

if ~isfield(result, 'images') || isempty(result.images)
    result.Log{end+1} = 'T1 fitting skipped: reconstructed images are unavailable.';
    return;
end

imgs = abs(double(result.images));
if ndims(imgs) < 4 || size(imgs, 4) < 2
    result.Log{end+1} = 'T1 fitting skipped: expected a time series in dimension 4 with at least two points.';
    return;
end

ti = resolveInversionTimes(MRFParams, settings, size(imgs, 4));
if isempty(ti)
    result.Log{end+1} = 'T1 fitting skipped: inversion times are unavailable or invalid.';
    return;
end

if isfield(runtimeOptions, 'T1FittingProgressCallback')
    progressCb = runtimeOptions.T1FittingProgressCallback;
else
    progressCb = [];
end

[nx, ny, nz, ~] = size(imgs);
t1Map = zeros(nx, ny, nz, 'like', imgs);

if ~isempty(progressCb)
    callT1Progress(progressCb, 0, nz);
end

for sliceIdx = 1:nz
    sliceSeries = squeeze(imgs(:, :, sliceIdx, :));
    if ndims(sliceSeries) < 3
        t1Map(:, :, sliceIdx) = NaN(nx, ny);
        continue;
    end

    try
        sliceT1 = InversionRecoveryT1Fitting(sliceSeries, ti, ones(nx, ny));
    catch
        try
            sliceT1 = T1Fitting(sliceSeries, ti, ones(nx, ny));
        catch
            sliceT1 = NaN(nx, ny);
        end
    end

    if ~isequal(size(sliceT1), [nx, ny])
        fixedSlice = NaN(nx, ny);
        limX = min(nx, size(sliceT1, 1));
        limY = min(ny, size(sliceT1, 2));
        fixedSlice(1:limX, 1:limY) = double(sliceT1(1:limX, 1:limY));
        sliceT1 = fixedSlice;
    end

    t1Map(:, :, sliceIdx) = double(sliceT1);

    if ~isempty(progressCb)
        callT1Progress(progressCb, sliceIdx, nz);
    end
end

if nz == 1
    t1Map = squeeze(t1Map);
end

if ~isfield(result, 'ParameterMaps') || ~isstruct(result.ParameterMaps)
    result.ParameterMaps = struct();
end
result.ParameterMaps.T1 = t1Map;
result.T1Fitting = struct();
result.T1Fitting.Method = 'InversionRecoveryT1Fitting/T1Fitting (skeleton fallback)';
result.T1Fitting.InversionTimes = ti;
result.T1Fitting.NSlices = nz;
result.Log{end+1} = sprintf('T1 fitting skeleton completed (%d slice(s), %d inversion time points).', nz, numel(ti));
end

function ti = resolveInversionTimes(MRFParams, settings, nTime)
ti = [];

candidates = {'InvTimes', 'TI', 'InversionTimes'};
for i = 1:numel(candidates)
    f = candidates{i};
    if isstruct(MRFParams) && isfield(MRFParams, f) && ~isempty(MRFParams.(f))
        ti = double(MRFParams.(f)(:));
        break;
    end
end

if isempty(ti) && isstruct(settings)
    for i = 1:numel(candidates)
        f = candidates{i};
        if isfield(settings, f) && ~isempty(settings.(f))
            ti = double(settings.(f)(:));
            break;
        end
    end
end

if isempty(ti)
    return;
end

ti = ti(isfinite(ti));
ti = ti(:);

if isempty(ti)
    return;
end

if numel(ti) ~= nTime
    minLen = min(numel(ti), nTime);
    ti = ti(1:minLen);
end
end

function callT1Progress(progressCb, completedSlices, totalSlices)
if isempty(progressCb)
    return;
end

try
    progressCb(double(completedSlices), double(totalSlices));
catch
    % Ignore progress callback errors to keep fitting robust.
end
end
