function context = buildMRFReconContext(settings)
% buildMRFReconContext  Normalise GUI settings into a reconstruction context.

context = struct();
context.Settings = settings;
context.Dimensionality = lower(string(getfield_default(settings, 'Dimensionality', '2D')));
context.RegularizationMode = string(getfield_default(settings, 'RegularizationMode', 'Locally-low rank'));
context.Lambda = getfield_default(settings, 'Lambda', 0.01);
context.EstimateMask = logical(getfield_default(settings, 'EstimateMask', false));
context.OuterIterations = round(getfield_default(settings, 'OuterIterations', 10));
context.InnerIterations = round(getfield_default(settings, 'InnerIterations', 5));
context.Rho = getfield_default(settings, 'Rho', 1);
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
end

function value = getfield_default(s, field, defaultValue)
if isstruct(s) && isfield(s, field) && ~isempty(s.(field))
    value = s.(field);
else
    value = defaultValue;
end
end
