function result = runZeroPadKSpaceCLI(inputSource, varargin)
% runZeroPadKSpaceCLI  Zero-pad MRI k-space data from scripts or the CLI.
%
% Examples:
%   result = runZeroPadKSpaceCLI(data, 'TargetSize', [256 256]);
%   result = runZeroPadKSpaceCLI(data, 'Padding', [32 32]);
%   result = runZeroPadKSpaceCLI('kspace.mat', 'VariableName', 'data', ...
%       'TargetSize', [256 256 128]);
%   padded = runZeroPadKSpaceCLI(data, 'TargetSize', [256 256], 'ReturnStruct', false);

options = parseOptions(varargin{:});
kspaceData = resolveInput(inputSource, options.VariableName);

if isempty(options.TargetSize) && isempty(options.Padding)
    error('runZeroPadKSpaceCLI:MissingSize', ...
        'Provide either TargetSize or Padding.');
end

inSize = size(kspaceData);
inSize(end+1:3) = 1;
spatialDims = min(3, max(1, nnz(inSize(1:3) > 1)));

if ~isempty(options.Padding)
    padding = double(options.Padding(:).');
    if any(mod(padding, 1) ~= 0) || any(padding < 0)
        error('runZeroPadKSpaceCLI:InvalidPadding', ...
            'Padding must contain non-negative integer values.');
    end

    if numel(padding) == 1
        padding = repmat(padding, 1, spatialDims);
    elseif numel(padding) ~= spatialDims
        error('runZeroPadKSpaceCLI:PaddingLengthMismatch', ...
            'Padding must be a scalar or match the inferred spatial dimensionality (%d).', spatialDims);
    end

    if isempty(options.TargetSize)
        targetSize = inSize(1:spatialDims) + 2 .* padding;
    else
        targetSize = validateTargetSize(options.TargetSize);
        targetSize = targetSize(1:spatialDims);
        expectedSize = inSize(1:spatialDims) + 2 .* padding;
        if any(targetSize ~= expectedSize)
            error('runZeroPadKSpaceCLI:InconsistentSizeOptions', ...
                'TargetSize and Padding do not describe the same output size.');
        end
    end
else
    targetSize = validateTargetSize(options.TargetSize);
end

[padded, info] = ZeroPadKSpace(kspaceData, targetSize, ...
    'Centered', options.Centered, ...
    'PadValue', options.PadValue);

if options.ReturnStruct
    result = struct();
    result.PaddedData = padded;
    result.Info = info;
    result.OriginalData = kspaceData;
    result.OriginalSize = size(kspaceData);
    result.TargetSize = size(padded);
    result.Options = options;
else
    result = padded;
end

end

function options = parseOptions(varargin)
defaults = struct();
defaults.TargetSize = [];
defaults.Padding = [];
defaults.Centered = true;
defaults.PadValue = 0;
defaults.VariableName = "";
defaults.ReturnStruct = true;

options = defaults;

if isempty(varargin)
    return;
end

if numel(varargin) == 1 && isstruct(varargin{1})
    userOptions = varargin{1};
    fieldNames = fieldnames(userOptions);
    for iField = 1:numel(fieldNames)
        fieldName = fieldNames{iField};
        if ~isfield(defaults, fieldName)
            error('runZeroPadKSpaceCLI:UnknownOption', 'Unknown option ''%s''.', fieldName);
        end
        options.(fieldName) = userOptions.(fieldName);
    end
elseif mod(numel(varargin), 2) == 0
    for iArg = 1:2:numel(varargin)
        rawName = varargin{iArg};
        if ~(ischar(rawName) || (isstring(rawName) && isscalar(rawName)))
            error('runZeroPadKSpaceCLI:InvalidNameValue', ...
                'Name-value options must use text option names.');
        end
        fieldName = char(string(rawName));
        if ~isfield(defaults, fieldName)
            error('runZeroPadKSpaceCLI:UnknownOption', 'Unknown option ''%s''.', fieldName);
        end
        options.(fieldName) = varargin{iArg + 1};
    end
else
    error('runZeroPadKSpaceCLI:InvalidOptionsInput', ...
        'Options must be provided either as a single struct or as name-value pairs.');
end

options.TargetSize = options.TargetSize;
options.Padding = options.Padding;
options.Centered = logical(options.Centered);
options.PadValue = options.PadValue;
options.VariableName = string(options.VariableName);
options.ReturnStruct = logical(options.ReturnStruct);

end

function targetSize = validateTargetSize(targetSize)
if isempty(targetSize)
    error('runZeroPadKSpaceCLI:MissingTargetSize', ...
        'TargetSize is required when Padding is not provided.');
end

validateattributes(targetSize, {'numeric'}, {'vector', 'real', 'finite', 'positive'}, ...
    mfilename, 'TargetSize');
targetSize = double(targetSize(:).');

if any(mod(targetSize, 1) ~= 0)
    error('runZeroPadKSpaceCLI:NonIntegerTargetSize', ...
        'TargetSize must contain integer values only.');
end

if numel(targetSize) < 1 || numel(targetSize) > 3
    error('runZeroPadKSpaceCLI:InvalidTargetSize', ...
        'TargetSize must contain 1, 2, or 3 elements.');
end

end

function data = resolveInput(inputSource, variableName)
if isnumeric(inputSource) || islogical(inputSource)
    data = inputSource;
    return;
end

if isstruct(inputSource)
    candidateFields = {'kspaceData', 'kspace', 'KSpace', 'rawdata', 'rawData', 'data'};
    for iField = 1:numel(candidateFields)
        fieldName = candidateFields{iField};
        if isfield(inputSource, fieldName)
            data = inputSource.(fieldName);
            return;
        end
    end
    error('runZeroPadKSpaceCLI:InvalidStructInput', ...
        'Struct input must contain one of: kspaceData, kspace, rawdata, or data.');
end

if ~(ischar(inputSource) || (isstring(inputSource) && isscalar(inputSource)))
    error('runZeroPadKSpaceCLI:InvalidInputSource', ...
        'inputSource must be a numeric array, struct, or .mat file path.');
end

filePath = char(string(inputSource));
if ~isfile(filePath)
    error('runZeroPadKSpaceCLI:InputNotFound', 'Input file does not exist: %s', filePath);
end

[~,~,ext] = fileparts(filePath);
if ~strcmpi(ext, '.mat')
    error('runZeroPadKSpaceCLI:UnsupportedFileType', ...
        'Only MAT files are supported when inputSource is a file path.');
end

S = load(filePath);
if strlength(variableName) > 0
    varName = char(variableName);
    if ~isfield(S, varName)
        error('runZeroPadKSpaceCLI:VariableNotFound', ...
            'Variable ''%s'' was not found in %s.', varName, filePath);
    end
    data = S.(varName);
    return;
end

fieldNames = fieldnames(S);
numericIdx = find(structfun(@(v) isnumeric(v) || islogical(v), S), 1, 'first');
if isempty(numericIdx)
    error('runZeroPadKSpaceCLI:NoNumericData', ...
        'MAT file contains no numeric or logical variables.');
end

data = S.(fieldNames{numericIdx});

end