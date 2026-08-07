function context = buildMRFReconContext(settings)
% buildMRFReconContext  Normalise GUI settings into a reconstruction context.

context = struct();
context.Settings = settings;
context.Dimensionality = lower(string(getfield_default(settings, 'Dimensionality', '2D')));
context.RegularizationModes = normalizeRegularizationModes(settings);
context.RegularizationMode = context.RegularizationModes(1);
context.RegularizationWeights = normalizeRegularizationWeights(settings, context.RegularizationModes);
context.Lambda = getfield_default(settings, 'Lambda', 0.01);
context.EstimateMask = logical(getfield_default(settings, 'EstimateMask', false));
context.OuterIterations = round(getfield_default(settings, 'OuterIterations', 10));
context.InnerIterations = round(getfield_default(settings, 'InnerIterations', 5));
context.Rho = getfield_default(settings, 'Rho', 1);
context.DataScalingMode = normalizeScalingMode(getfield_default(settings, 'DataScalingMode', 'off'));
context.DataScalingPercentile = double(getfield_default(settings, 'DataScalingPercentile', 99));
context.DataScalingFactor = double(getfield_default(settings, 'DataScalingFactor', NaN));
context.SubspaceComponentRetentionPct = getfield_default(settings, 'SubspaceComponentRetentionPct', 100);
context.BlockSize = round(getfield_default(settings, 'BlockSize', 8));
context.Stride = round(getfield_default(settings, 'Stride', 4));
context.LoadDir = getfield_default(settings, 'LoadDir', '');
context.MethodPath = getfield_default(settings, 'MethodPath', '');
context.DictionaryPath = getfield_default(settings, 'DictionaryPath', '');
context.MethodParams = getfield_default(settings, 'MethodParams', struct());
context.DataPath = getfield_default(settings, 'DataPath', '');
context.DataSize = getfield_default(settings, 'DataSize', []);
context.DataDimensions = getfield_default(settings, 'DataDimensions', []);
context.DataPoints = getfield_default(settings, 'DataPoints', []);
context.LUTSize = getfield_default(settings, 'LUTSize', []);
context.DictionarySize = getfield_default(settings, 'DictionarySize', []);
context.Timestamp = datetime('now');

if isempty(context.MethodParams)
    context.MethodParams = struct();
end

if ~isfinite(context.SubspaceComponentRetentionPct)
    context.SubspaceComponentRetentionPct = 100;
end
context.SubspaceComponentRetentionPct = min(max(double(context.SubspaceComponentRetentionPct), 1), 100);

if ~isfinite(context.DataScalingPercentile)
    context.DataScalingPercentile = 99;
end
context.DataScalingPercentile = min(max(context.DataScalingPercentile, 50), 100);

if isempty(context.DataScalingFactor) || ~isfinite(context.DataScalingFactor) || context.DataScalingFactor <= 0
    context.DataScalingFactor = NaN;
end
end

function regModes = normalizeRegularizationModes(settings)
rawModes = {};

if isstruct(settings) && isfield(settings, 'RegularizationModes') && ~isempty(settings.RegularizationModes)
    rawModes = settings.RegularizationModes;
elseif isstruct(settings) && isfield(settings, 'RegularizationMode') && ~isempty(settings.RegularizationMode)
    rawModes = settings.RegularizationMode;
end

if ischar(rawModes)
    regModes = string({rawModes});
elseif isstring(rawModes)
    regModes = string(rawModes(:));
elseif iscell(rawModes)
    regModes = string(rawModes(:));
else
    regModes = string.empty(0, 1);
end

regModes = strtrim(regModes);
regModes(regModes == "") = [];
if isempty(regModes)
    regModes = "Locally-low rank";
end
regModes = unique(regModes, 'stable');
end

function weights = normalizeRegularizationWeights(settings, regModes)
nModes = numel(regModes);
weights = ones(nModes, 1);

if ~(isstruct(settings) && isfield(settings, 'RegularizationWeights'))
    return;
end

raw = settings.RegularizationWeights;
if isempty(raw)
    return;
end

if ischar(raw) || (isstring(raw) && isscalar(raw))
    raw = str2num(char(raw)); %#ok<ST2NM>
end

if ~isnumeric(raw)
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

function mode = normalizeScalingMode(rawMode)
mode = lower(strtrim(char(string(rawMode))));
switch mode
    case {'off', 'none'}
        mode = 'off';
    case {'global', 'global-robust'}
        mode = 'global';
    case {'perframe', 'per-frame', 'frame'}
        mode = 'per-frame';
    case {'manual'}
        mode = 'manual';
    otherwise
        mode = 'off';
end
end

function value = getfield_default(s, field, defaultValue)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    value = s.(field);
else
    value = defaultValue;
end
end
