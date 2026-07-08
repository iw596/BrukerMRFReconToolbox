function app = DebugReconImagesTab(imagesFile)
% DebugReconImagesTab  Open the Recon Images tab from a saved MAT file.
%
% Usage:
%   app = DebugReconImagesTab();
%   app = DebugReconImagesTab('C:\path\to\session_images.mat');
%
% This avoids rerunning reconstruction while iterating on Recon Images UI.

if nargin < 1 || isempty(imagesFile)
    [f, p] = uigetfile({'*.mat', 'MAT files (*.mat)'}, ...
        'Select saved reconstruction images MAT file');
    if isequal(f, 0)
        app = [];
        return;
    end
    imagesFile = fullfile(p, f);
end

if ~isfile(imagesFile)
    error('DebugReconImagesTab:FileNotFound', 'File not found: %s', imagesFile);
end

S = load(imagesFile);
images = extractImagesForDebug(S);

dimensionality = inferDimensionality(images);

app = GUI.MRFViewer();
app.ReconResult = struct();
app.ReconResult.images = images;

if isfield(S, 'mask') && ~isempty(S.mask)
    app.ReconResult.mask = logical(S.mask);
end

if ~isempty(app.ReconTabObj) && isvalid(app.ReconTabObj)
    app.ReconTabObj.ReconSettings.Dimensionality = dimensionality;
end

app.openReconstructionImagesTab();

disp(['Loaded debug images from: ' imagesFile]);
disp(['Inferred dimensionality: ' dimensionality]);
disp(['Image size: ' mat2str(size(images))]);
end

function images = extractImagesForDebug(S)
if isfield(S, 'images') && isnumeric(S.images)
    images = S.images;
    return;
end

names = fieldnames(S);
for i = 1:numel(names)
    value = S.(names{i});
    if isnumeric(value) && ~isempty(value)
        images = value;
        warning('DebugReconImagesTab:FallbackVariable', ...
            'Using variable "%s" as debug images.', names{i});
        return;
    end
end

error('DebugReconImagesTab:NoImageData', ...
    'No numeric image variable found. Expected a variable named "images".');
end

function dimensionality = inferDimensionality(images)
sz = size(images);
if numel(sz) < 4
    sz(4) = 1;
end
if numel(sz) < 3
    sz(3) = 1;
end

if sz(3) > 1
    dimensionality = '3D';
else
    dimensionality = '2D';
end
end
