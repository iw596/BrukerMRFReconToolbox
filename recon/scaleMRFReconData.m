function [dataScaled, scaling] = scaleMRFReconData(data, context)
% scaleMRFReconData  Optional k-space scaling for iterative reconstruction.
%
%   Modes:
%     - off: no scaling
%     - global: robust scalar from all k-space points
%     - per-frame: robust scalar per temporal frame (dim 4)
%     - manual: use DataScalingFactor from context

scaling = struct();
scaling.Mode = 'off';
scaling.Applied = false;
scaling.Percentile = 99;
scaling.GlobalScale = 1;
scaling.FrameScales = [];
scaling.Message = 'Scaling disabled.';

if nargin < 2
    context = struct();
end

dataScaled = data;
if isempty(data)
    scaling.Message = 'Scaling skipped: input data is empty.';
    return;
end

mode = lower(strtrim(char(getfield_default(context, 'DataScalingMode', 'off'))));
if isempty(mode)
    mode = 'off';
end

pct = double(getfield_default(context, 'DataScalingPercentile', 99));
if ~isfinite(pct)
    pct = 99;
end
pct = min(max(pct, 50), 100);
scaling.Percentile = pct;

switch mode
    case {'off', 'none'}
        scaling.Mode = 'off';
        return;

    case {'manual'}
        manualScale = double(getfield_default(context, 'DataScalingFactor', NaN));
        if ~isfinite(manualScale) || manualScale <= 0
            manualScale = 1;
            scaling.Message = 'Manual scaling requested but factor was invalid. Using 1.';
        else
            scaling.Message = sprintf('Manual scaling applied with factor %.6g.', manualScale);
        end

        dataScaled = data ./ manualScale;
        scaling.Mode = 'manual';
        scaling.Applied = true;
        scaling.GlobalScale = manualScale;

    case {'global', 'global-robust'}
        scaleVal = robustScaleEstimate(data, pct);
        dataScaled = data ./ scaleVal;

        scaling.Mode = 'global';
        scaling.Applied = true;
        scaling.GlobalScale = scaleVal;
        scaling.Message = sprintf('Global scaling applied using p%.1f = %.6g.', pct, scaleVal);

    case {'perframe', 'per-frame', 'frame'}
        if ndims(data) < 4
            scaleVal = robustScaleEstimate(data, pct);
            dataScaled = data ./ scaleVal;

            scaling.Mode = 'global';
            scaling.Applied = true;
            scaling.GlobalScale = scaleVal;
            scaling.Message = sprintf('Per-frame requested but data has <4 dims; used global p%.1f = %.6g.', pct, scaleVal);
            return;
        end

        nFrames = size(data, 4);
        scales = ones(nFrames, 1);

        for iFrame = 1:nFrames
            frameData = data(:, :, :, iFrame);
            scales(iFrame) = robustScaleEstimate(frameData, pct);
            dataScaled(:, :, :, iFrame) = frameData ./ scales(iFrame);
        end

        scaling.Mode = 'per-frame';
        scaling.Applied = true;
        scaling.FrameScales = scales;
        scaling.Message = sprintf('Per-frame scaling applied using p%.1f.', pct);

    otherwise
        scaling.Mode = 'off';
        scaling.Message = sprintf('Unknown scaling mode ''%s''. Scaling disabled.', mode);
end
end

function scaleVal = robustScaleEstimate(x, pct)
vals = abs(double(x(:)));
vals = vals(isfinite(vals));

if isempty(vals)
    scaleVal = 1;
    return;
end

if pct >= 100
    scaleVal = max(vals);
else
    scaleVal = prctile(vals, pct);
end

if ~isfinite(scaleVal) || scaleVal <= 0
    scaleVal = max(vals);
end
if ~isfinite(scaleVal) || scaleVal <= 0
    scaleVal = 1;
end
end

function value = getfield_default(s, field, defaultValue)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    value = s.(field);
else
    value = defaultValue;
end
end
