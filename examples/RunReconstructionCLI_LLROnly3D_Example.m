%% RunReconstructionCLI_LLROnly3D_Example
% Non-GUI reconstruction example: iterative 3D MRF with LLR regularization only.
% Use this script as a baseline for volumetric low-rank reconstruction.

% Update these paths for your dataset and dictionary.
scanDir = "datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/12";
dictPath = "Dictionaries/example_dictionary.mat";

opts = struct();

% Core reconstruction choices
opts.ReconstructionTarget = "MRF";
opts.MRFReconMode = "Iterative";
opts.Dimensionality = "3D";
opts.DictionaryPath = dictPath;

% Regularization: LLR only (3D)
opts.RegularizationModes = {"Locally-low rank"};
opts.RegularizationWeights = 1.0;
opts.Lambda = 0.008;

% 3D local block geometry (x, y, z)
opts.BlockSize = [8 8 4];
opts.Stride = [4 4 2];

% ADMM settings
opts.OuterIterations = 10;
opts.InnerIterations = 5;
opts.Rho = 1.0;
opts.SubspaceComponentRetentionPct = 100;

% Data scaling options: off | global | per-frame | manual
opts.DataScalingMode = "global";
opts.DataScalingPercentile = 99;

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
% opts.SaveBasePath = "Results/mrf_llr_only_3d_run1";

result = runReconstructionCLI(scanDir, opts);

fprintf("Reconstruction status: %s\n", string(result.Status));
if isfield(result, 'SubspaceRetainedComponents')
    fprintf("Retained subspace components: %d/%d\n", ...
        result.SubspaceRetainedComponents, result.SubspaceTotalComponents);
end
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
