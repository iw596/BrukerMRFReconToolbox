%% Step 1: Load k-Space Data and Generate Undersampled Data
% Load fully sampled k-space data
addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")
addpath("FileIO\")

pth = "datasets\MRF_IWFISP";
params = LoadBrukerData(pth);
FA = ReadMRFList("datasets\MRFPattern.txt");
plot(FA);
rawdata  = params.data;
rawdata = reshape(rawdata, [params.NCol length(FA) params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
kspace=rawdata;

%% Parameters
Nx = 128;            % Number of frequency-encoding points (columns)
Ny = 128;            % Number of phase-encoding lines (rows)
numCentralLines = 20;  % Number of central lines to fully sample

% Percentage of outer lines to sample (e.g., 30% of the outer region)
outerSamplingFraction = 0.3;

%% Define Central Fully Sampled Lines
% Determine the central line indices
centerLine = round(Ny / 2);
halfCentral = floor(numCentralLines / 2);
centralIndices = (centerLine - halfCentral):(centerLine + halfCentral);

%% Define Outer Region Lines
% Outer lines are those not included in the central region
allLines = 1:Ny;
outerIndices = setdiff(allLines, centralIndices);

% Determine the number of outer lines to sample
numOuterToSample = round(outerSamplingFraction * numel(outerIndices));

% % Randomly select outer indices (you can use 'randsample' for random selection)
% selectedOuterIndices = sort(randsample(outerIndices, numOuterToSample));
 % Define Outer Region Lines
% Outer lines are those not included in the central region
allLines = 1:Ny;
outerIndices = setdiff(allLines, centralIndices);

% Determine the number of outer lines to sample
numOuterToSample = round(outerSamplingFraction * numel(outerIndices));

% Randomly select outer indices using randperm
idx = randperm(length(outerIndices), numOuterToSample);
selectedOuterIndices = sort(outerIndices(idx));


%% Create the Final Undersampling Mask
% Initialize a mask of zeros
undersampling_mask = zeros(Ny, Nx);

% Fully sample the central lines
undersampling_mask(centralIndices, :) = 1;

% Sample the selected outer lines (set the entire row to 1)
undersampling_mask(selectedOuterIndices, :) = 1;

%% Visualization of the Sampling Mask
figure;
imagesc(undersampling_mask);
colormap(gray);
axis image;
title('Line-Based Undersampling Mask');
xlabel('k_x (Frequency Encoding)');
ylabel('k_y (Phase Encoding)');

%%  Apply the Mask to Fully Sampled k-Space Data

% Apply the undersampling mask to fully sampled k-space data
kspace_undersampled = kspace .* undersampling_mask;

% Optional: Visualize the magnitude of k-space before and after undersampling
% For undersampled k-space data (assuming variable name: kspace_undersampled)
figure;
imagesc(abs(kspace_undersampled(:,:,1)));  % Visualize the first time point
colormap(gray);
axis image;
title('Undersampled k-space (Slice 1)');


subplot(1,2,2);
imagesc(abs(kspace_undersampled(:,:,1)));
colormap(gray);
axis image;
title('Undersampled k-space (Time Point 1)');


%%  Inverse Fourier Transform to Reconstruct the Image
% Before applying the inverse Fourier transform, shift the k-space data so that the zero-frequency component is at the correct location.
kspace_shifted = ifftshift(kspace_undersampled);  % Shift zero frequency to the beginning
image_recon = ifft2(kspace_shifted);                % Compute the inverse 2D Fourier transform
image_recon = fftshift(image_recon);                % Shift the image for proper centering

% 3. Visualize the Results
figure;

% Display the magnitude of the fully sampled reconstruction for reference
image_full = fftshift(ifft2(ifftshift(kspace)));
subplot(1,3,1);
imagesc(abs(image_full(:,:,1)));
colormap(gray);
axis image;
title('Reconstructed Image (Time Point 1)');

colormap(gray);
axis image;
title('Reconstruction: Fully Sampled');

% Display the magnitude of the undersampled k-space (for visualization purposes)
subplot(1,3,2);
imagesc(log(abs(kspace_undersampled(:,:,1)) + 1));  % Log-scale visualization for the first time point
colormap(gray);
axis image;
title('Log-Scaled Undersampled k-space (Time Point 1)');

colormap(gray);
axis image;
title('Undersampled k-space (log-scale)');

% Display the magnitude of the reconstructed image from undersampled data
subplot(1,3,3);
imagesc(abs(image_recon(:,:,1)));
colormap(gray);
axis image;
title('Reconstructed Image (Time Point 1)');

colormap(gray);
axis image;
title('Reconstructed Image (Undersampled)');
% % Visualize reconstructions
% figure;
% subplot(1, 2, 1); montage(mat2gray(abs(imgs))); title('Fully Sampled Reconstruction');
% subplot(1, 2, 2); montage(mat2gray(abs(undersampled_imgs))); title('Undersampled Reconstruction');
%%  Dictionary Creation (Load Precomputed Dictionary)
% Load dictionary and lookup table
load('MRF_Dictionary.mat', 'dict', 'LUT', 'T1List', 'T2List');
dictionary = dict; % Assign the numeric matrix

dict = dict ./ vecnorm(dict, 2, 1);
%% Perform Matching for Both Datasets
% Load Dictionary and Lookup Table
load('MRF_Dictionary.mat', 'dict', 'LUT', 'T1List', 'T2List');
disp(['Dictionary size: ', mat2str(size(dict))]);

% Normalize the dictionary (row-based normalization for cosine similarity)
dict_norm = dict ./ vecnorm(dict, 2, 2);

% Dataset Setup
datasets = {'Fully Sampled', 'Undersampled'};
dataInputs = {image_full, image_recon};

% Initialize output maps
T1_maps = {};
T2_maps = {};

% Loop Through Fully Sampled and Undersampled Datasets
for d = 1:2
    % Select dataset
    datasetName = datasets{d};
    data = dataInputs{d};
    disp(['Performing dictionary matching for: ', datasetName]);

    % Extract voxel-wise temporal signals
    [Nx, Ny, Nt] = size(data);
    signals = reshape(data, Nx * Ny, Nt); % Reshape to voxel-wise signals
    signals = signals ./ max(vecnorm(signals, 2, 2), eps); % Avoid division by zero

    % Initialize T1 and T2 maps
    T1_map = zeros(Nx, Ny);
    T2_map = zeros(Nx, Ny);

    % Step 4.1: Test Matching for Selected Voxels
    testVoxels = [sub2ind([Nx, Ny], Nx/2, Ny/2), ... % Center voxel
                  sub2ind([Nx, Ny], 10, 10), ...     % Edge voxel
                  sub2ind([Nx, Ny], 100, 100)];      % Manual voxel
    
    disp('Testing matching for selected voxels...');
    for voxelIdx = testVoxels
        % Extract and normalize the voxel signal
        signal = abs(signals(voxelIdx, :)');
        signal = signal / norm(signal); % Ensure unit norm

        % Compute cosine similarity
        correlations = dict_norm * signal;

        % Find the best match
        [maxValue, best_match_index] = max(correlations);

        % Map T1 and T2 values
        T1_map(voxelIdx) = LUT(best_match_index, 1);
        T2_map(voxelIdx) = LUT(best_match_index, 2);

        % Debugging display
        disp(['Voxel Index: ', num2str(voxelIdx), ...
              ', T1: ', num2str(LUT(best_match_index, 1)), ...
              ', T2: ', num2str(LUT(best_match_index, 2))]);
    end

    % Use vectorized matching
    se = strel('disk', 20, 0);
mask = mean(image_full,3);
mask = imbinarize(mat2gray(abs(mask)));

figure;imshow(mask)
    % mask_flattened = mask(:); % Flatten the mask for voxel indexing
    % for voxel = find(mask_flattened)' % Only process voxels within the mask
    % Step 4.2: Full Matching (After Verification)
    disp('Running full dictionary matching...');
    for voxelIdx = find(mask(:))' % Process only masked voxels
        % Extract and normalize the voxel signal
        signal = abs(signals(voxelIdx, :)');
        signal = signal / norm(signal);

        % Compute cosine similarity
        correlations = dict_norm * signal;

        % Find the best match
        [~, best_match_index] = max(correlations);

        % Map to T1 and T2 values
        T1_map(voxelIdx) = LUT(best_match_index, 1);
        T2_map(voxelIdx) = LUT(best_match_index, 2);
    end

    % Reshape Maps Back to Spatial Dimensions
    T1_map = reshape(T1_map, Nx, Ny) .* mask;
    T2_map = reshape(T2_map, Nx, Ny) .* mask;

    % Save Results
    save([datasetName '_T1_T2_Maps.mat'], 'T1_map', 'T2_map');

    % Store in Output List
    T1_maps{d} = T1_map;
    T2_maps{d} = T2_map;

    % Visualize Results
    figure;
    subplot(1, 2, 1); imagesc(T1_map); colorbar; title([datasetName ' T1 Map']);
    subplot(1, 2, 2); imagesc(T2_map); colorbar; title([datasetName ' T2 Map']);
end


% %% Compare Selected Voxels
selected_voxels = [50, 50; 30, 40; 60, 70; 100, 100];
for v = 1:size(selected_voxels, 1)
    x = selected_voxels(v, 1);
    y = selected_voxels(v, 2);
    disp(['Voxel (' num2str(x) ',' num2str(y) '):']);
    disp(['  Fully Sampled - T1: ' num2str(T1_fully(x, y)) ', T2: ' num2str(T2_fully(x, y))]);
    disp(['  Undersampled  - T1: ' num2str(T1_under(x, y)) ', T2: ' num2str(T2_under(x, y))]);
end

%--- Example Quantitative Maps (Replace with your actual maps) ---
% For demonstration, let's assume T1_full, T1_us, T2_full, T2_us are available
% Each map is a 2D matrix, e.g., 128x128.

T1_full = T1_maps{1};  % Fully sampled T1 map (size: 128x128)
T1_us   = T1_maps{2};  % Undersampled T1 map (size: 128x128)

T2_full = T2_maps{1};  % Fully sampled T2 map (size: 128x128)
T2_us   = T2_maps{2};
%--- Compute Metrics for T1 Map ---
% Fully sampled T1 metrics
mean_T1_full = mean(T1_full(:));
std_T1_full  = std(T1_full(:));
range_T1_full = [min(T1_full(:)), max(T1_full(:))];

% Undersampled T1 metrics
mean_T1_us = mean(T1_us(:));
std_T1_us  = std(T1_us(:));
range_T1_us = [min(T1_us(:)), max(T1_us(:))];

% RMSE for T1 between fully sampled and undersampled maps
rmse_T1 = sqrt(mean((T1_full(:) - T1_us(:)).^2));

% Display T1 metrics
fprintf('T1 Metrics:\n');
fprintf('Fully Sampled: Mean = %.2f, Std = %.2f, Range = [%.2f, %.2f]\n', mean_T1_full, std_T1_full, range_T1_full(1), range_T1_full(2));
fprintf('Undersampled:   Mean = %.2f, Std = %.2f, Range = [%.2f, %.2f]\n', mean_T1_us, std_T1_us, range_T1_us(1), range_T1_us(2));
fprintf('T1 RMSE (Full vs. US): %.2f\n\n', rmse_T1);

%--- Compute Metrics for T2 Map ---
% Fully sampled T2 metrics
mean_T2_full = mean(T2_full(:));
std_T2_full  = std(T2_full(:));
range_T2_full = [min(T2_full(:)), max(T2_full(:))];

% Undersampled T2 metrics
mean_T2_us = mean(T2_us(:));
std_T2_us  = std(T2_us(:));
range_T2_us = [min(T2_us(:)), max(T2_us(:))];

% RMSE for T2 between fully sampled and undersampled maps
rmse_T2 = sqrt(mean((T2_full(:) - T2_us(:)).^2));

% Display T2 metrics
fprintf('T2 Metrics:\n');
fprintf('Fully Sampled: Mean = %.2f, Std = %.2f, Range = [%.2f, %.2f]\n', mean_T2_full, std_T2_full, range_T2_full(1), range_T2_full(2));
fprintf('Undersampled:   Mean = %.2f, Std = %.2f, Range = [%.2f, %.2f]\n', mean_T2_us, std_T2_us, range_T2_us(1), range_T2_us(2));
fprintf('T2 RMSE (Full vs. US): %.2f\n', rmse_T2);
