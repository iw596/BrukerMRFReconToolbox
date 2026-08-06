%% RunReconstructionCLIExample
% Minimal non-GUI reconstruction example.
% Saves parameter maps only (not raw reconstructed images).

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

% Save only parameter maps, not the raw reconstructed image series.
opts.SaveOutputs = true;
opts.SaveImages = false;      % skip *_images.mat
opts.SaveMaps = true;         % write *_maps.mat
opts.SaveResultBundle = false;
opts.SaveBasePath = "Results/RunReconstructionCLIExample";

result = runReconstructionCLI(scanDir, opts);

fprintf('Status: %s\n', string(result.Status));
if isfield(result, 'OutputFiles') && ~isempty(result.OutputFiles.Maps)
    fprintf('Parameter maps saved to: %s\n', result.OutputFiles.Maps);
end
if isfield(result, 'ParameterMaps')
    disp('Generated map fields:');
    disp(fieldnames(result.ParameterMaps));
end

% Example 2: Save both images and maps
% opts2 = opts;
% opts2.SaveImages = true;
% opts2.SaveMaps = true;
% opts2.SaveBasePath = "Results/RunReconstructionCLIExample_full";
% result2 = runReconstructionCLI(scanDir, opts2);

% Example 3: T1 target using preloaded params
% params = LoadBrukerData(scanDir, true);
% t1opts = struct('ReconstructionTarget', "T1", 'MRFReconMode', "Direct");
% t1Result = runReconstructionCLI(params, t1opts);
