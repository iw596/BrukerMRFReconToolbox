%% Main Script for Variable Density Poisson Disk Sampling in k-Space

% Parameters
gridSize = [128, 128]; % Size of k-space grid
undersamplingFactor = 3; % Desired undersampling factor
radius = 4; % Minimum distance between points (pixels)
biasFactor = 2; % Strength of central biasing

% Generate Poisson disk sampling mask with variable density
samplingMask = variableDensityPoissonDisk(gridSize, undersamplingFactor, radius, biasFactor);

% Visualize the sampling mask
figure;
imagesc(samplingMask);
title('Variable Density Poisson Disk Sampling Mask');
colorbar;
axis image;

% Load k-space data
addpath("Simulations\");
addpath("recon\");
addpath("B1Mapping\");
addpath("Fitting\");
addpath("FileIO\");

pth = "datasets\MRF_IWFISP";
params = LoadBrukerData(pth);
FA = ReadMRFList("datasets\MRFPattern.txt");
rawdata = params.data;
rawdata = reshape(rawdata, [params.NCol, length(FA), params.NLin]);
rawdata = permute(rawdata, [1, 3, 2]);
kspace = rawdata;

% Apply sampling mask to fully sampled k-space data
undersampled_kspace = kspace .* repmat(samplingMask, [1, 1, size(kspace, 3)]);

% Save undersampled k-space data
save('undersampled_kspace_data.mat', 'undersampled_kspace');
disp('Undersampled k-space data generated and saved.');

% Reconstruct spatial domain images from k-space
imgs = ifftcn(kspace, [1, 2]); % Fully sampled reconstruction
undersampled_imgs = ifftcn(undersampled_kspace, [1, 2]); % Undersampled reconstruction

% Visualize reconstructions
figure;
subplot(1, 2, 1); montage(mat2gray(abs(imgs))); title('Fully Sampled Reconstruction');
subplot(1, 2, 2); montage(mat2gray(abs(undersampled_imgs))); title('Undersampled Reconstruction');

% Load precomputed dictionary and perform matching
load('MRF_Dictionary.mat', 'dict', 'LUT', 'T1List', 'T2List');
dict_norm = dict ./ vecnorm(dict, 2, 2); % Normalize dictionary for matching

% Extract voxel-wise temporal signals
[Nx, Ny, Nt] = size(undersampled_imgs);
signals = reshape(undersampled_imgs, Nx * Ny, Nt); % Reshape to voxel-wise signals
signals = signals ./ max(vecnorm(signals, 2, 2), eps); % Normalize signals

% Initialize T1 and T2 maps
T1_map = zeros(Nx, Ny);
T2_map = zeros(Nx, Ny);

% Perform dictionary matching
disp('Performing dictionary matching...');
for voxelIdx = 1:(Nx * Ny)
    % Extract signal for the voxel
    signal = signals(voxelIdx, :)';
    % Compute cosine similarity
    correlations = dict_norm * signal;
    % Find the best match
    [~, best_match_index] = max(correlations);
    % Map to T1 and T2 values
    T1_map(voxelIdx) = LUT(best_match_index, 1);
    T2_map(voxelIdx) = LUT(best_match_index, 2);
end

% Reshape T1 and T2 maps back to spatial dimensions
T1_map = reshape(T1_map, Nx, Ny);
T2_map = reshape(T2_map, Nx, Ny);

% Save results
save('T1_T2_Maps.mat', 'T1_map', 'T2_map');

% Visualize T1 and T2 maps
figure;
subplot(1, 2, 1); imagesc(T1_map); colorbar; title('T1 Map');
subplot(1, 2, 2); imagesc(T2_map); colorbar; title('T2 Map');

% Compare selected voxels
selected_voxels = [50, 50; 30, 40; 60, 70; 100, 100];
for v = 1:size(selected_voxels, 1)
    x = selected_voxels(v, 1);
    y = selected_voxels(v, 2);
    disp(['Voxel (' num2str(x) ',' num2str(y) '):']);
    disp(['  T1: ' num2str(T1_map(x, y)) ', T2: ' num2str(T2_map(x, y))]);
end

% Visualize T1 and T2 histograms
figure;
subplot(1, 2, 1); histogram(T1_map(:), 'FaceAlpha', 0.5); title('T1 Histogram'); xlabel('T1 Values'); ylabel('Frequency');
subplot(1, 2, 2); histogram(T2_map(:), 'FaceAlpha', 0.5); title('T2 Histogram'); xlabel('T2 Values'); ylabel('Frequency');
