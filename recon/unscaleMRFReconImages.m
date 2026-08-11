function images = unscaleMRFReconImages(images, scaling)
% unscaleMRFReconImages  Restore image-domain scale after iterative recon.

if nargin < 2 || isempty(scaling) || ~isstruct(scaling)
    return;
end

if ~isfield(scaling, 'Applied') || ~logical(scaling.Applied)
    return;
end

mode = lower(strtrim(char(getfield_default(scaling, 'Mode', 'off'))));
switch mode
    case {'global', 'manual'}
        scaleVal = double(getfield_default(scaling, 'GlobalScale', 1));
        if isfinite(scaleVal) && scaleVal > 0
            images = images .* scaleVal;
        end

    case {'per-frame'}
        frameScales = double(getfield_default(scaling, 'FrameScales', []));
        if isempty(frameScales) || ndims(images) < 4
            return;
        end

        nApply = min(numel(frameScales), size(images, 4));
        for iFrame = 1:nApply
            scaleVal = frameScales(iFrame);
            if isfinite(scaleVal) && scaleVal > 0
                images(:, :, :, iFrame) = images(:, :, :, iFrame) .* scaleVal;
            end
        end
end
end

function value = getfield_default(s, field, defaultValue)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    value = s.(field);
else
    value = defaultValue;
end
end
