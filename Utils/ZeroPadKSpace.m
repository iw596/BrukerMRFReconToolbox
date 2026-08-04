%% ZeroPadKSpace  Centered zero-padding for MRI k-space data.
% padded = ZeroPadKSpace(kspaceData, targetSize) pads the input array in
% the first 1, 2, or 3 spatial dimensions so the output matches targetSize.
% Trailing dimensions are preserved unchanged.

function [padded, info] = ZeroPadKSpace(kspaceData, targetSize, varargin)

options = parseOptions(varargin{:});

if ~(isnumeric(kspaceData) || islogical(kspaceData))
    error('ZeroPadKSpace:InvalidInputType', ...
        'kspaceData must be numeric or logical.');
end

if isempty(kspaceData)
    error('ZeroPadKSpace:EmptyInput', 'kspaceData must not be empty.');
end

validateattributes(targetSize, {'numeric'}, {'vector', 'real', 'finite', 'positive'}, ...
    mfilename, 'targetSize', 2);
targetSize = double(targetSize(:).');

if any(mod(targetSize, 1) ~= 0)
    error('ZeroPadKSpace:NonIntegerTargetSize', ...
        'targetSize must contain integer values only.');
end

if numel(targetSize) < 1 || numel(targetSize) > 3
    error('ZeroPadKSpace:InvalidTargetSize', ...
        'targetSize must contain 1, 2, or 3 elements.');
end

inSize = size(kspaceData);
inSize(end+1:3) = 1;

if numel(targetSize) == 1
    spatialDims = find(inSize(1:3) > 1, 1, 'first');
    if isempty(spatialDims)
        spatialDims = 1;
    end

    if nnz(inSize(1:3) > 1) > 1
        error('ZeroPadKSpace:Ambiguous1DInput', ...
            ['1D padding requires only one non-singleton spatial dimension ' ...
             'within the first three dimensions.']);
    end

    padDims = spatialDims;
    requestedSpatialSize = inSize(1:3);
    requestedSpatialSize(padDims) = targetSize;
else
    padDims = 1:numel(targetSize);
    requestedSpatialSize = inSize(1:3);
    requestedSpatialSize(padDims) = targetSize;
end

if any(inSize(padDims) > requestedSpatialSize(padDims))
    error('ZeroPadKSpace:TargetTooSmall', ...
        'targetSize must be greater than or equal to the input size along padded dimensions.');
end

outSize = [requestedSpatialSize, inSize(4:end)];
padded = zeros(outSize, 'like', kspaceData);
if options.PadValue ~= 0
    padded(:) = cast(options.PadValue, 'like', kspaceData);
end

padBefore = zeros(1, 3);
padAfter = zeros(1, 3);
if options.Centered
    for dimIndex = padDims
        totalPad = requestedSpatialSize(dimIndex) - inSize(dimIndex);
        padBefore(dimIndex) = floor(totalPad / 2);
        padAfter(dimIndex) = totalPad - padBefore(dimIndex);
    end
end

idx = cell(1, numel(outSize));
for dimIndex = 1:3
    idx{dimIndex} = padBefore(dimIndex) + (1:inSize(dimIndex));
end
for dimIndex = 4:numel(outSize)
    idx{dimIndex} = 1:inSize(dimIndex);
end

padded(idx{:}) = kspaceData;

if nargout > 1
    info = struct();
    info.Centered = logical(options.Centered);
    info.PadValue = options.PadValue;
    info.OriginalSize = size(kspaceData);
    info.OriginalSpatialSize = inSize(1:3);
    info.RequestedSpatialSize = requestedSpatialSize;
    info.OutputSize = outSize;
    info.PadBefore = padBefore;
    info.PadAfter = padAfter;
    info.PaddedDimensions = padDims;
end

end

function options = parseOptions(varargin)
options.Centered = true;
options.PadValue = 0;

if isempty(varargin)
    return;
end

if mod(numel(varargin), 2) ~= 0
    error('ZeroPadKSpace:InvalidOptions', 'Options must be provided as name-value pairs.');
end

for iArg = 1:2:numel(varargin)
    rawName = varargin{iArg};
    rawValue = varargin{iArg + 1};

    if ~(ischar(rawName) || (isstring(rawName) && isscalar(rawName)))
        error('ZeroPadKSpace:InvalidOptionName', 'Option names must be text scalars.');
    end

    switch lower(char(string(rawName)))
        case 'centered'
            options.Centered = logical(rawValue);
        case 'padvalue'
            options.PadValue = rawValue;
        otherwise
            error('ZeroPadKSpace:UnknownOption', 'Unknown option ''%s''.', char(string(rawName)));
    end
end

end