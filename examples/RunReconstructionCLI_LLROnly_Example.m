%% RunReconstructionCLI_LLROnly_Example
% Non-GUI reconstruction example: iterative MRF with LLR regularization only.
% This script is intended as a minimal baseline for low-rank recon testing.

% Update these paths for your dataset and dictionary.
scanDir = "C:\Users\isaac\OneDrive - University of Leeds\MRF_Project\CartesianMRF\LRRecon_2D\Data\32";
dictPath = "C:\Users\isaac\OneDrive - University of Leeds\MRF_Project\CartesianMRF\LRRecon_2D\Data\Dictionary_2DMRF_32.mat";

opts = struct();

% Core reconstruction choices
opts.ReconstructionTarget = "MRF";
opts.MRFReconMode = "Iterative";
opts.DictionaryPath = dictPath;

% Regularization: LLR only
opts.RegularizationModes = {"Locally-low rank"};
opts.RegularizationWeights = 1.0;
opts.Lambda = 0.01;
opts.BlockSize = 8;
opts.Stride = 8;

% ADMM settings
opts.OuterIterations = 1;
opts.InnerIterations = 1;
opts.Rho = 1.0;
opts.SubspaceComponentRetentionPct = 99.99;

% Data scaling options: off | global | per-frame | manual
opts.DataScalingMode = "global";
opts.DataScalingPercentile = 99;
% opts.DataScalingMode = "manual";
% opts.DataScalingFactor = 1e5;

% Optional controls
opts.EstimateMask = true;
opts.ShowProgress = true;
opts.ParallelMatching = true;
opts.SaveComplexM0 = false;

% Optional saving
opts.SaveOutputs = false;
opts.SaveResultBundle = false;
% opts.SaveOutputs = true;
% opts.SaveResultBundle = true;
% opts.SaveBasePath = "Results/mrf_llr_only_run1";

result = runReconstructionCLI(scanDir, opts);

fprintf("Reconstruction status: %s\n", string(result.Status));
if isfield(result, 'Scaling')
    disp('Scaling metadata:');
    disp(result.Scaling);
end
if isfield(result, 'OutputFiles')
    disp(result.OutputFiles);
end
if isfield(result, 'ParameterMaps')
    disp('Generated maps:');
    disp(fieldnames(result.ParameterMaps));
end
