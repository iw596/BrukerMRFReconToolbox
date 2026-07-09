function result = runReconstructionCLI(inputSource, options)
% runReconstructionCLI  Non-GUI entry point for reconstruction workflows.
%
% Usage examples:
%   result = runReconstructionCLI("datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/12", ...
%       struct('ReconstructionTarget','MRF','DictionaryPath','Dictionaries/my_dict.mat'));
%
%   params = LoadBrukerData("datasets/14", true);
%   result = runReconstructionCLI(params, struct('ReconstructionTarget','T1'));
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

arguments
    inputSource
    options.ReconstructionTarget (1,1) string {mustBeMember(options.ReconstructionTarget,["MRF","T1","T2"])} = "MRF"
    options.MRFReconMode (1,1) string {mustBeMember(options.MRFReconMode,["Direct","Iterative"])} = "Direct"
    options.RegularizationMode (1,1) string = "Locally-low rank"
    options.EstimateMask (1,1) logical = false
    options.DictionaryPath (1,1) string = ""
    options.ParallelMatching (1,1) logical = false
    options.SaveComplexM0 (1,1) logical = false
    options.B1CorrectionMode (1,1) string = "None"
    options.EstimateB1Map (1,1) logical = false
    options.B1Map = []
    options.Dimensionality (1,1) string = ""
    options.Lambda (1,1) double = 0.01
    options.BlockSize (1,1) double = 8
    options.Stride (1,1) double = 4
    options.OuterIterations (1,1) double = 10
    options.InnerIterations (1,1) double = 5
    options.Rho (1,1) double = 1
    options.SaveOutputs (1,1) logical = false
    options.SaveResultBundle (1,1) logical = false
    options.SaveBasePath (1,1) string = ""
    options.ShowProgress (1,1) logical = true
    options.MatchingProgressUpdateInterval (1,1) double = 1
    options.T1FittingProgressUpdateInterval (1,1) double = 1
    options.LoadData (1,1) logical = true
end

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
