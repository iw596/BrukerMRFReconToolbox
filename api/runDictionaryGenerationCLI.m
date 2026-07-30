function result = runDictionaryGenerationCLI(inputSource, varargin)
% runDictionaryGenerationCLI  Non-GUI entry point for dictionary generation.
%
% Usage examples:
%   result = runDictionaryGenerationCLI("datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/12", ...
%       struct('PrepListPath', "datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/12/MRFPrepList.txt", ...
%              'T1Values', 100:50:3000, 'T2Values', [10:5:120 140:20:400], ...
%              'B1Values', 0.8:0.05:1.2, 'ParallelSimulation', true));
%
%   params = LoadBrukerData("datasets/14", false);
%   prepList = [0 15 0; 1 40 0; 2 0 0];
%   result = runDictionaryGenerationCLI(params, struct('PrepList', prepList));
%   result = runDictionaryGenerationCLI(scanPath, 'PrepListPath', "...", 'ShowProgress', true);

options = parseOptions(varargin{:});

params = resolveMRFParams(inputSource, options.LoadData);
prepList = resolvePrepList(options);
FA = resolveFlipAngles(options, params);

T1Values = resolveNumericRange(options.T1Values, params, 'T1');
T2Values = resolveNumericRange(options.T2Values, params, 'T2');
B1Values = resolveB1Values(options.B1Values, params);

if isempty(prepList)
    error('runDictionaryGenerationCLI:PrepListRequired', ...
        'Prep list is required. Provide options.PrepList or options.PrepListPath.');
end
if isempty(FA)
    error('runDictionaryGenerationCLI:FARequired', ...
        'Flip-angle train is required. Provide options.FlipAngles, options.FAPath, or params.MRFFA.');
end

params = configureDictionaryParams(params, FA, options);

progressFcn = [];
if options.ShowProgress
    progressFcn = @printDictionaryProgress;
end

fprintf('DictionaryGenerationCLI: starting with %d T1, %d T2, %d B1 values.\n', ...
    numel(T1Values), numel(T2Values), numel(B1Values));

tic;
[dict, LUT] = SimulateFISPMRF( ...
    params, prepList, T1Values, T2Values, B1Values, ...
    options.RasterTime_us, options.NIsochromats, options.InstantInversion, progressFcn);  % Simulation runs here
elapsedSec = toc;

result = struct();
result.Dict = dict;
result.LUT = LUT;
result.Params = params;
result.ElapsedSec = elapsedSec;
result.Options = options;

if strlength(options.SavePath) > 0
    savePath = char(options.SavePath);
    saveFolder = fileparts(savePath);
    if ~isempty(saveFolder) && ~isfolder(saveFolder)
        mkdir(saveFolder);
    end

    generationParams = params; %#ok<NASGU>
    generationOptions = options; %#ok<NASGU>

    if options.SaveV73
        save(savePath, 'dict', 'LUT', 'generationParams', 'generationOptions', '-v7.3');
    else
        save(savePath, 'dict', 'LUT', 'generationParams', 'generationOptions');
    end
    result.SavePath = savePath;
    fprintf('DictionaryGenerationCLI: saved dictionary to %s\n', savePath);
end

fprintf('DictionaryGenerationCLI: completed in %.2f s. LUT entries: %d\n', ...
    elapsedSec, size(LUT,1));
end

function options = parseOptions(varargin)
defaults = struct();
defaults.T1Values = [];
defaults.T2Values = [];
defaults.B1Values = 1;
defaults.PrepList = [];
defaults.PrepListPath = "";
defaults.FlipAngles = [];
defaults.FAPath = "";
defaults.RasterTime_us = 10;
defaults.NIsochromats = 200;
defaults.InstantInversion = true;
defaults.ParallelSimulation = true;
defaults.ShowProgress = true;
defaults.SavePath = "";
defaults.SaveV73 = true;
defaults.LoadData = false;

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
            error('runDictionaryGenerationCLI:UnknownOption', ...
                'Unknown option ''%s''.', fieldName);
        end
        options.(fieldName) = userOptions.(fieldName);
    end
elseif mod(numel(varargin), 2) == 0
    for iArg = 1:2:numel(varargin)
        rawName = varargin{iArg};
        if ~(ischar(rawName) || (isstring(rawName) && isscalar(rawName)))
            error('runDictionaryGenerationCLI:InvalidNameValue', ...
                'Name-value options must use text option names.');
        end
        fieldName = char(string(rawName));
        if ~isfield(defaults, fieldName)
            error('runDictionaryGenerationCLI:UnknownOption', ...
                'Unknown option ''%s''.', fieldName);
        end
        options.(fieldName) = varargin{iArg + 1};
    end
else
    error('runDictionaryGenerationCLI:InvalidOptionsInput', ...
        ['Options must be provided either as a single struct or as ' ...
         'name-value pairs.']);
end

options.PrepListPath = string(options.PrepListPath);
options.FAPath = string(options.FAPath);
options.SavePath = string(options.SavePath);
options.RasterTime_us = double(options.RasterTime_us);
options.NIsochromats = double(options.NIsochromats);
options.InstantInversion = logical(options.InstantInversion);
options.ParallelSimulation = logical(options.ParallelSimulation);
options.ShowProgress = logical(options.ShowProgress);
options.SaveV73 = logical(options.SaveV73);
options.LoadData = logical(options.LoadData);
end

function params = resolveMRFParams(inputSource, loadDataFlag)
if isstruct(inputSource)
    params = inputSource;
    return;
end

if ~(ischar(inputSource) || (isstring(inputSource) && isscalar(inputSource)))
    error('runDictionaryGenerationCLI:InvalidInputSource', ...
        'inputSource must be a struct, folder path, or method file path.');
end

inputPath = char(string(inputSource));
if isfolder(inputPath)
    scanDir = inputPath;
elseif isfile(inputPath)
    [parentDir, fileName, ext] = fileparts(inputPath);
    if strcmpi([fileName ext], 'method') || strcmpi(fileName, 'method')
        scanDir = parentDir;
    else
        error('runDictionaryGenerationCLI:InvalidMethodPath', ...
            'When passing a file path, it must point to the Bruker method file.');
    end
else
    error('runDictionaryGenerationCLI:InputPathNotFound', ...
        'Input path does not exist: %s', inputPath);
end

params = LoadBrukerData(scanDir, loadDataFlag);
end

function prepList = resolvePrepList(options)
prepList = [];

if ~isempty(options.PrepList)
    prepList = double(options.PrepList);
elseif strlength(options.PrepListPath) > 0
    prepPath = char(options.PrepListPath);
    if ~isfile(prepPath)
        error('runDictionaryGenerationCLI:PrepListPathNotFound', ...
            'Prep list file not found: %s', prepPath);
    end
    prepList = parsePrepListFileFlexible(prepPath);
end

if isempty(prepList)
    return;
end

if size(prepList,2) == 2
    prepList(:,3) = 0;
elseif size(prepList,2) < 2
    error('runDictionaryGenerationCLI:InvalidPrepList', ...
        'Prep list must contain at least [moduleCode prepTime_ms].');
end
end

function prepList = parsePrepListFileFlexible(filePath)
txt = fileread(filePath);
linesRaw = splitlines(txt);
lines = {};
for i = 1:numel(linesRaw)
    ln = strtrim(linesRaw{i});
    if isempty(ln)
        continue;
    end
    lines{end+1} = ln; %#ok<AGROW>
end

if isempty(lines)
    error('runDictionaryGenerationCLI:EmptyPrepList', 'Prep list file is empty.');
end

lineStart = 1;
if startsWith(lines{1}, '#')
    lineStart = 2;
end

prepList = zeros(0,3);
for i = lineStart:numel(lines)
    parts = strsplit(lines{i});
    if numel(parts) < 2
        continue;
    end

    moduleCode = str2double(parts{1});
    if isnan(moduleCode)
        moduleCode = prepCodeFromName(parts{1});
    end
    prepTime = str2double(parts{2});
    if isnan(prepTime)
        continue;
    end

    waitTime = 0;
    if numel(parts) >= 3
        wt = str2double(parts{3});
        if ~isnan(wt)
            waitTime = wt;
        end
    end

    prepList(end+1,:) = [moduleCode, prepTime, waitTime]; %#ok<AGROW>
end

if isempty(prepList)
    error('runDictionaryGenerationCLI:InvalidPrepListRows', ...
        'No valid prep list rows were parsed from %s', filePath);
end
end

function code = prepCodeFromName(token)
token = lower(strtrim(string(token)));
switch token
    case {"t1prep","t1"}
        code = 0;
    case {"t2prep","t2"}
        code = 1;
    case {"none","noprep"}
        code = 2;
    case {"bir4","bir"}
        code = 2;
    otherwise
        code = 2;
end
end

function FA = resolveFlipAngles(options, params)
FA = [];

if ~isempty(options.FlipAngles)
    FA = double(options.FlipAngles(:).');
elseif strlength(options.FAPath) > 0
    faPath = char(options.FAPath);
    if ~isfile(faPath)
        error('runDictionaryGenerationCLI:FAPathNotFound', 'FA file not found: %s', faPath);
    end
    FA = double(ReadFAList(faPath));
    FA = FA(:).';
elseif isfield(params, 'MRFFA') && ~isempty(params.MRFFA)
    FA = double(params.MRFFA(:).');
end

if isempty(FA)
    return;
end

FA = FA(isfinite(FA));
if isempty(FA)
    error('runDictionaryGenerationCLI:InvalidFA', 'Flip-angle train is empty after filtering invalid values.');
end
end

function values = resolveNumericRange(inputValue, params, fieldName)
if ~isempty(inputValue)
    values = parseNumericRange(inputValue, fieldName);
    return;
end

if isfield(params, fieldName) && ~isempty(params.(fieldName))
    values = double(params.(fieldName)(:).');
    values = values(isfinite(values));
    if isempty(values)
        error('runDictionaryGenerationCLI:InvalidRange', ...
            '%s range in params is invalid.', fieldName);
    end
    return;
end

error('runDictionaryGenerationCLI:MissingRange', ...
    '%s values are required. Provide options.%sValues or params.%s.', fieldName, fieldName, fieldName);
end

function values = resolveB1Values(inputValue, params)
if ~isempty(inputValue)
    values = parseNumericRange(inputValue, 'B1');
    return;
end

if isfield(params, 'B1') && ~isempty(params.B1)
    values = double(params.B1(:).');
else
    values = 1;
end

values = values(isfinite(values));
if isempty(values)
    values = 1;
end
end

function values = parseNumericRange(inputValue, label)
if isnumeric(inputValue) || islogical(inputValue)
    values = double(inputValue(:).');
elseif ischar(inputValue) || (isstring(inputValue) && isscalar(inputValue))
    values = str2num(char(string(inputValue))); %#ok<ST2NM>
else
    error('runDictionaryGenerationCLI:InvalidRangeInput', ...
        '%s values must be numeric or a MATLAB range string.', label);
end

values = values(isfinite(values));
if isempty(values)
    error('runDictionaryGenerationCLI:EmptyRange', '%s values are empty.', label);
end
end

function params = configureDictionaryParams(params, FA, options)
params.FA = FA;
params.UseParallel = logical(options.ParallelSimulation);
params.InstantInversion = logical(options.InstantInversion);
params.dt = options.RasterTime_us * 1e-6;
params.RasterTime = params.dt;
params.NIsochromats = round(options.NIsochromats);

if isfield(params, 'Thickness') && ~isempty(params.Thickness)
    params.SliceThickness_mm = params.Thickness * 1000;
elseif ~isfield(params, 'SliceThickness_mm') || isempty(params.SliceThickness_mm)
    params.SliceThickness_mm = 2;
end

if ~isfield(params, 'RefPow') || isempty(params.RefPow)
    params.RefPow = 1;
end
end

function printDictionaryProgress(progress)
if ~isstruct(progress) || ~isfield(progress, 'Total')
    return;
end

if progress.Total <= 0
    fprintf('DictionaryGeneration: %s\n', progress.Message);
    return;
end

pct = 100 * progress.Percent;
if isfield(progress, 'RemainingSec') && isfinite(progress.RemainingSec)
    etaText = formatDuration(progress.RemainingSec);
else
    etaText = 'estimating...';
end

fprintf('\rDictionaryGeneration: %d/%d (%.1f%%) | ETA %s', ...
    progress.Completed, progress.Total, pct, etaText);
if progress.Completed >= progress.Total
    fprintf('\n');
end
end

function out = formatDuration(secondsValue)
secondsValue = max(0, secondsValue);
hoursValue = floor(secondsValue / 3600);
minutesValue = floor(mod(secondsValue, 3600) / 60);
secondsValue = round(mod(secondsValue, 60));

if hoursValue > 0
    out = sprintf('%dh %02dm %02ds', hoursValue, minutesValue, secondsValue);
elseif minutesValue > 0
    out = sprintf('%dm %02ds', minutesValue, secondsValue);
else
    out = sprintf('%ds', secondsValue);
end
end
