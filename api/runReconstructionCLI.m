function result = runReconstructionCLI(inputSource, varargin)
% runReconstructionCLI  Non-GUI entry point for reconstruction workflows.
%
% Usage examples:
%   result = runReconstructionCLI("datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/12", ...
%       struct('ReconstructionTarget','MRF','DictionaryPath','Dictionaries/my_dict.mat'));
%
%   params = LoadBrukerData("datasets/14", true);
%   result = runReconstructionCLI(params, struct('ReconstructionTarget','T1'));
%   result = runReconstructionCLI(scanDir, 'ReconstructionTarget', 'MRF', 'DictionaryPath', '...');
%
% inputSource:
%   - struct returned by LoadBrukerData, or
%   - scan directory containing a Bruker method file, or
%   - full path to the method file.
%
% options fields:
%   ReconstructionTarget, MRFReconMode, RegularizationMode, EstimateMask,
%   DictionaryPath, ParallelMatching, SaveComplexM0, EstimateB1Map, B1Map,
%   Dimensionality, Lambda, BlockSize, Stride, OuterIterations,
%   InnerIterations, Rho, SaveOutputs, SaveResultBundle, SaveBasePath,
%   ShowProgress, MatchingProgressUpdateInterval, T1FittingProgressUpdateInterval,
%   LoadData

options = parseOptions(varargin{:});

MRFParams = resolveMRFParams(inputSource, options.LoadData);

settings = struct();
settings.ReconstructionTarget = char(options.ReconstructionTarget);
settings.MRFReconMode = char(options.MRFReconMode);
settings.RegularizationMode = char(options.RegularizationMode);
settings.EstimateMask = logical(options.EstimateMask);
settings.DictionaryPath = char(options.DictionaryPath);
settings.ParallelMatching = logical(options.ParallelMatching);
settings.SaveComplexM0 = logical(options.SaveComplexM0);
settings.B1CorrectionMode = char(options.B1CorrectionMode);
settings.EstimateB1Map = logical(options.EstimateB1Map);
settings.B1Map = resolveB1Map(options.B1Map);
settings.Lambda = options.Lambda;
settings.BlockSize = round(options.BlockSize);
settings.Stride = round(options.Stride);
settings.OuterIterations = round(options.OuterIterations);
settings.InnerIterations = round(options.InnerIterations);
settings.Rho = options.Rho;
settings.SaveOutputs = logical(options.SaveOutputs);
settings.SaveResultBundle = logical(options.SaveResultBundle);
settings.SaveBasePath = char(options.SaveBasePath);
settings.MethodParams = MRFParams;

if strlength(options.Dimensionality) > 0
    settings.Dimensionality = char(options.Dimensionality);
elseif isfield(MRFParams, 'NDim') && ~isempty(MRFParams.NDim) && double(MRFParams.NDim) >= 3
    settings.Dimensionality = '3D';
else
    settings.Dimensionality = '2D';
end

runtimeOptions = struct();
if options.ShowProgress
    runtimeOptions.MatchingProgressCallback = makeProgressPrinter('Dictionary matching');
    runtimeOptions.MatchingProgressUpdateInterval = max(1, round(options.MatchingProgressUpdateInterval));
    runtimeOptions.T1FittingProgressCallback = makeProgressPrinter('T1 fitting');
    runtimeOptions.T1FittingProgressUpdateInterval = max(1, round(options.T1FittingProgressUpdateInterval));
end

if strcmpi(settings.ReconstructionTarget, 'MRF') && isempty(settings.DictionaryPath)
    error('runReconstructionCLI:DictionaryRequired', ...
        'DictionaryPath is required when ReconstructionTarget is MRF.');
end

result = runMRFReconstruction(MRFParams, settings, runtimeOptions);
end

function options = parseOptions(varargin)
defaults = struct();
defaults.ReconstructionTarget = "MRF";
defaults.MRFReconMode = "Direct";
defaults.RegularizationMode = "Locally-low rank";
defaults.EstimateMask = false;
defaults.DictionaryPath = "";
defaults.ParallelMatching = false;
defaults.SaveComplexM0 = false;
defaults.B1CorrectionMode = "None";
defaults.EstimateB1Map = false;
defaults.B1Map = [];
defaults.Dimensionality = "";
defaults.Lambda = 0.01;
defaults.BlockSize = 8;
defaults.Stride = 4;
defaults.OuterIterations = 10;
defaults.InnerIterations = 5;
defaults.Rho = 1;
defaults.SaveOutputs = false;
defaults.SaveResultBundle = false;
defaults.SaveBasePath = "";
defaults.ShowProgress = true;
defaults.MatchingProgressUpdateInterval = 1;
defaults.T1FittingProgressUpdateInterval = 1;
defaults.LoadData = true;

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
            error('runReconstructionCLI:UnknownOption', 'Unknown option ''%s''.', fieldName);
        end
        options.(fieldName) = userOptions.(fieldName);
    end
elseif mod(numel(varargin), 2) == 0
    for iArg = 1:2:numel(varargin)
        rawName = varargin{iArg};
        if ~(ischar(rawName) || (isstring(rawName) && isscalar(rawName)))
            error('runReconstructionCLI:InvalidNameValue', ...
                'Name-value options must use text option names.');
        end
        fieldName = char(string(rawName));
        if ~isfield(defaults, fieldName)
            error('runReconstructionCLI:UnknownOption', 'Unknown option ''%s''.', fieldName);
        end
        options.(fieldName) = varargin{iArg + 1};
    end
else
    error('runReconstructionCLI:InvalidOptionsInput', ...
        ['Options must be provided either as a single struct or as ' ...
         'name-value pairs.']);
end

options.ReconstructionTarget = string(options.ReconstructionTarget);
options.MRFReconMode = string(options.MRFReconMode);
options.RegularizationMode = string(options.RegularizationMode);
options.DictionaryPath = string(options.DictionaryPath);
options.B1CorrectionMode = string(options.B1CorrectionMode);
options.Dimensionality = string(options.Dimensionality);
options.SaveBasePath = string(options.SaveBasePath);
options.ShowProgress = logical(options.ShowProgress);
options.EstimateMask = logical(options.EstimateMask);
options.ParallelMatching = logical(options.ParallelMatching);
options.SaveComplexM0 = logical(options.SaveComplexM0);
options.EstimateB1Map = logical(options.EstimateB1Map);
options.Lambda = double(options.Lambda);
options.BlockSize = double(options.BlockSize);
options.Stride = double(options.Stride);
options.OuterIterations = double(options.OuterIterations);
options.InnerIterations = double(options.InnerIterations);
options.Rho = double(options.Rho);
options.SaveOutputs = logical(options.SaveOutputs);
options.SaveResultBundle = logical(options.SaveResultBundle);
options.MatchingProgressUpdateInterval = double(options.MatchingProgressUpdateInterval);
options.T1FittingProgressUpdateInterval = double(options.T1FittingProgressUpdateInterval);
options.LoadData = logical(options.LoadData);
end

function params = resolveMRFParams(inputSource, loadDataFlag)
if isstruct(inputSource)
    params = inputSource;
    return;
end

if ~(ischar(inputSource) || (isstring(inputSource) && isscalar(inputSource)))
    error('runReconstructionCLI:InvalidInputSource', ...
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
        error('runReconstructionCLI:InvalidMethodPath', ...
            'When passing a file path, it must point to the Bruker method file.');
    end
else
    error('runReconstructionCLI:InputPathNotFound', 'Input path does not exist: %s', inputPath);
end

params = LoadBrukerData(scanDir, loadDataFlag);
end

function B1Map = resolveB1Map(inputB1)
if isempty(inputB1)
    B1Map = [];
    return;
end

if isnumeric(inputB1) || islogical(inputB1)
    B1Map = double(inputB1);
    return;
end

if ischar(inputB1) || (isstring(inputB1) && isscalar(inputB1))
    b1Path = char(string(inputB1));
    if ~isfile(b1Path)
        error('runReconstructionCLI:B1PathNotFound', 'B1 map file does not exist: %s', b1Path);
    end

    [~,~,ext] = fileparts(b1Path);
    switch lower(ext)
        case '.mat'
            S = load(b1Path);
            names = fieldnames(S);
            idx = find(structfun(@isnumeric, S), 1, 'first');
            if isempty(idx)
                error('runReconstructionCLI:InvalidB1Mat', ...
                    'B1 MAT file contains no numeric variable.');
            end
            B1Map = double(S.(names{idx}));
        case {'.nii', '.gz'}
            info = niftiinfo(b1Path);
            B1Map = double(niftiread(info));
        otherwise
            error('runReconstructionCLI:UnsupportedB1Format', ...
                'Unsupported B1 format. Use MAT or NIfTI.');
    end
    return;
end

error('runReconstructionCLI:InvalidB1Input', ...
    'B1Map must be numeric, empty, or a file path string.');
end

function cb = makeProgressPrinter(stageName)
lastPercent = -1;

cb = @progressUpdate;

    function progressUpdate(doneCount, totalCount)
        totalCount = max(1, round(double(totalCount)));
        doneCount = min(max(round(double(doneCount)), 0), totalCount);
        pct = floor((100 * doneCount) / totalCount);

        if pct == lastPercent
            return;
        end

        if pct < 100
            fprintf('\r[%s] %d/%d (%d%%)', stageName, doneCount, totalCount, pct);
        else
            fprintf('\r[%s] %d/%d (%d%%)\n', stageName, doneCount, totalCount, pct);
        end
        lastPercent = pct;
    end
end
