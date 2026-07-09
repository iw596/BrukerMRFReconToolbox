%% RunReconstructionCLIExample
% Minimal non-GUI reconstruction example.

% Example 1: MRF target from a scan folder
scanDir = "datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/12";
dictPath = "Dictionaries/example_dictionary.mat"; % replace with your dictionary

opts = struct();
opts.ReconstructionTarget = "MRF";
opts.MRFReconMode = "Direct";
opts.DictionaryPath = dictPath;
opts.ParallelMatching = true;
opts.SaveComplexM0 = true;
opts.EstimateMask = true;
opts.ShowProgress = true;

result = runReconstructionCLI(scanDir, opts);

disp(result.Status);
if isfield(result, 'ParameterMaps')
    disp(fieldnames(result.ParameterMaps));
end

% Example 2: T1 target using preloaded params
% params = LoadBrukerData(scanDir, true);
% t1opts = struct('ReconstructionTarget', "T1", 'MRFReconMode', "Direct");
% t1Result = runReconstructionCLI(params, t1opts);
