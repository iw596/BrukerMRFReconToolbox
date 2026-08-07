%% RunReconstructionCLI_LLR_Block8_Example
% Non-GUI reconstruction example: iterative MRF with combined regularizers.
% This example uses LLR + Wavelet + TV with split-ADMM and optional scaling.

% Update these paths for your dataset and dictionary.
scanDir = "datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/12";
dictPath = "Dictionaries/example_dictionary.mat";

opts = struct();

% Core reconstruction choices
opts.ReconstructionTarget = "MRF";
opts.MRFReconMode = "Iterative";
opts.DictionaryPath = dictPath;

% Regularization: combine LLR + Wavelet + TV
opts.RegularizationModes = {"Locally-low rank", "Wavelet", "Total variation"};
opts.RegularizationWeights = [1.0, 0.5, 0.3];
opts.Lambda = 0.01;
opts.BlockSize = 8;
opts.Stride = 4;
opts.WaveletName = "db2";
opts.WaveletLevels = 3;
opts.TVIterations = 25;

% Data scaling (BART-style configurable normalization)
% Available: "off", "global", "per-frame", "manual"
opts.DataScalingMode = "global";
opts.DataScalingPercentile = 99;
% opts.DataScalingMode = "manual";
% opts.DataScalingFactor = 1e5;

% ADMM settings
opts.OuterIterations = 10;
opts.InnerIterations = 5;
opts.Rho = 1.0;

% Optional controls
opts.SubspaceComponentRetentionPct = 100;
opts.EstimateMask = true;
opts.ShowProgress = true;
opts.ParallelMatching = true;
opts.SaveComplexM0 = false;

% Optional saving (set true and define SaveBasePath if desired)
opts.SaveOutputs = false;
opts.SaveResultBundle = false;
% opts.SaveOutputs = true;
% opts.SaveResultBundle = true;
% opts.SaveBasePath = "Results/mrf_llr_block8_run1";

result = runReconstructionCLI(scanDir, opts);

fprintf("Reconstruction status: %s\n", string(result.Status));
if isfield(result, 'OutputFiles')
    disp(result.OutputFiles);
end
if isfield(result, 'ParameterMaps')
    disp("Generated maps:");
    disp(fieldnames(result.ParameterMaps));
end
