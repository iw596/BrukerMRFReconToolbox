function [imageFile, mapFile, samplingMaskFile, bundleFile] = saveResultOutputs(result, saveBasePath, settings, saveBundle, saveImages, saveMaps)
% saveImages and saveMaps are optional booleans (default true each).
if nargin < 5 || isempty(saveImages)
    saveImages = true;
end
if nargin < 6 || isempty(saveMaps)
    saveMaps = true;
end

[saveFolder, saveStem, ~] = fileparts(saveBasePath);
if isempty(saveFolder)
    saveFolder = pwd;
end
if isempty(saveStem)
    saveStem = ['mrf_recon_' datestr(now, 'yyyymmdd_HHMMSS')];
end

imageFile = '';
mapFile = '';
samplingMaskFile = '';
bundleFile = '';

mask = [];
if isfield(result, 'mask') && ~isempty(result.mask)
    mask = logical(result.mask);
end

if saveImages
    imageFile = fullfile(saveFolder, [saveStem '_images.mat']);
    images = [];
    samplingmask = [];
    if isfield(result, 'images')
        images = result.images;
    end
    if isfield(result, 'samplingmask')
        samplingmask = result.samplingmask;
    end
    save(imageFile, 'images', 'samplingmask', 'mask', '-v7.3');

    if ~isempty(samplingmask)
        samplingMaskFile = fullfile(saveFolder, [saveStem '_samplingmask.mat']);
        save(samplingMaskFile, 'samplingmask', '-v7.3');
    end
end

if saveMaps && isfield(result, 'ParameterMaps') && ~isempty(result.ParameterMaps)
    mapFile = fullfile(saveFolder, [saveStem '_maps.mat']);
    maps = result.ParameterMaps;
    if ~isempty(mask)
        maps.mask = mask;
    end
    matching = [];
    if isfield(result, 'Matching')
        matching = result.Matching;
    end
    save(mapFile, 'maps', 'matching', 'mask', '-v7.3');
end

if saveBundle
    bundleFile = fullfile(saveFolder, [saveStem '_recon_result.mat']);
    bundle = struct();
    bundle.Timestamp = datestr(now, 31);
    bundle.Status = getfield_default_local(result, 'Status', 'Completed');
    bundle.Log = getfield_default_local(result, 'Log', {});
    bundle.DictionaryPath = getfield_default_local(result, 'DictionaryPath', '');
    bundle.Settings = settings;
    bundle.OutputFiles = struct('Images', imageFile, 'Maps', mapFile, 'SamplingMask', samplingMaskFile);
    bundle.SubspaceSummary = struct( ...
        'RetainedImages', getfield_default_local(result, 'SubspaceImageCount', []), ...
        'RetainedComponents', getfield_default_local(result, 'SubspaceRetainedComponents', []), ...
        'TotalComponents', getfield_default_local(result, 'SubspaceTotalComponents', []), ...
        'RetentionPercent', getfield_default_local(result, 'SubspaceComponentRetentionPct', []));
    if isfield(result, 'Matching') && isstruct(result.Matching)
        bundle.MatchingSummary = struct('HasB1Map', isfield(result.Matching, 'MRFB1Map'), ...
            'HasIndexMap', isfield(result.Matching, 'indexMap'));
    else
        bundle.MatchingSummary = struct();
    end
    save(bundleFile, 'bundle', '-v7.3');
end
end

function value = getfield_default_local(s, field, defaultValue)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    value = s.(field);
else
    value = defaultValue;
end
end
