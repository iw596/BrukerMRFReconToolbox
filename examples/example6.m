
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

% Generate Poisson disk sampling mask 
undersamplingFactor = 2; % Retain 50% of k-space
maxRadius = 4;           % Maximum spacing between points
biasFactor = 10;         % Controls central bias (adjustable)

% Generate the sampling mask using central bias
samplingMask = poissonDiskCentralBias([128, 128], undersamplingFactor, maxRadius, biasFactor);
% Debug: Check total sampled points
disp(['Total non-zero points in sampling mask: ', num2str(nnz(samplingMask))]);

% Apply the mask to fully sampled k-space to create undersampled data
undersampled_kspace = kspace .* repmat(samplingMask, [1, 1, size(kspace, 3)]);

% Save the undersampled k-space data for future use
save('undersampled_kspace_data.mat', 'undersampled_kspace', 'samplingMask');
disp('Central-biased undersampled k-space data generated and saved.');

% % Visualize the sampling mask 
figure;
imagesc(samplingMask); colormap('gray'); axis image;
title('Poisson Disk Sampling Mask');

% Visualize the new sampling mask
figure;
imagesc(samplingMask); colormap('gray'); axis image;
title('Central-Biased Poisson Disk Sampling Pattern');

%% Step 2: Reconstruction
% Reconstruct spatial domain images from k-space using IFT
imgs = ifftcn(rawdata, [1 2]); % Fully sampled reconstruction
undersampled_imgs = ifftcn(undersampled_kspace, [1 2]); % Undersampled reconstruction
% Visualize reconstructions
figure;
subplot(1, 2, 1); montage(mat2gray(abs(imgs))); title('Fully Sampled Reconstruction');
subplot(1, 2, 2); montage(mat2gray(abs(undersampled_imgs))); title('Undersampled Reconstruction');
% Compare temporal signals for the center voxel
centerVoxel = [64, 64];
figure;
plot(abs(squeeze(imgs(centerVoxel(1), centerVoxel(2), :))), 'b', 'LineWidth', 1.5); hold on;
plot(abs(squeeze(undersampled_imgs(centerVoxel(1), centerVoxel(2), :))), 'r--', 'LineWidth', 1.5);
legend('Fully Sampled', 'Undersampled');
xlabel('Time Frame'); ylabel('Signal Magnitude');
title('Temporal Signal Evolution at Center Voxel');
%% Step 3: Dictionary Creation (Load Precomputed Dictionary)
% Load dictionary and lookup table
load('MRF_Dictionary.mat', 'dict', 'LUT', 'T1List', 'T2List');
dictionary = dict; % Assign the numeric matrix
% % Confirm dictionary size
% disp(['Dictionary size: ', mat2str(size(dict))]);
% disp(['Number of T1 values: ', num2str(numel(T1List))]);
% disp(['Number of T2 values: ', num2str(numel(T2List))]);
% Normalize the dictionary (column-based normalization)
dict = dict ./ vecnorm(dict, 2, 1);
%% Step 4: Perform Matching for Both Datasets
% Load Dictionary and Lookup Table
load('MRF_Dictionary.mat', 'dict', 'LUT', 'T1List', 'T2List');
disp(['Dictionary size: ', mat2str(size(dict))]);

% Normalize the dictionary (row-based normalization for cosine similarity)
dict_norm = dict ./ vecnorm(dict, 2, 2);

% Dataset Setup
datasets = {'Fully Sampled', 'Undersampled'};
dataInputs = {imgs, undersampled_imgs};

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
mask = mean(imgs,3);
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


%% Compare Selected Voxels
selected_voxels = [50, 50; 30, 40; 60, 70; 100, 100];
for v = 1:size(selected_voxels, 1)
    x = selected_voxels(v, 1);
    y = selected_voxels(v, 2);
    disp(['Voxel (' num2str(x) ',' num2str(y) '):']);
    disp(['  Fully Sampled - T1: ' num2str(T1_map_fully(x, y)) ', T2: ' num2str(T2_map_fully(x, y))]);
    disp(['  Undersampled  - T1: ' num2str(T1_map_under(x, y)) ', T2: ' num2str(T2_map_under(x, y))]);
end

%% Visualize T1/T2 Differences

%% RMSE Calculation and Difference Maps
% Check if maps are available
if ~exist('T1_map_fully', 'var') || ~exist('T1_map_under', 'var')
    error('T1 maps not found. Ensure T1_map_fully and T1_map_under are generated or loaded.');
end

if ~exist('T2_map_fully', 'var') || ~exist('T2_map_under', 'var')
    error('T2 maps not found. Ensure T2_map_fully and T2_map_under are generated or loaded.');
end


% Flatten the maps for easier RMSE calculation
T1_fully_flat = T1_map_fully(mask);
T1_under_flat = T1_map_under(mask);

T2_fully_flat = T2_map_fully(mask);
T2_under_flat = T2_map_under(mask);

% Compute RMSE for T1 and T2
RMSE_T1 = sqrt(mean((T1_fully_flat - T1_under_flat).^2));
RMSE_T2 = sqrt(mean((T2_fully_flat - T2_under_flat).^2));

% Display RMSE results
disp(['RMSE for T1 Maps: ', num2str(RMSE_T1)]);
disp(['RMSE for T2 Maps: ', num2str(RMSE_T2)]);

% Compute Difference Maps
T1_diff = abs(T1_map_fully - T1_map_under);
T2_diff = abs(T2_map_fully - T2_map_under);

%% Visualize Difference Maps
figure;
subplot(1, 2, 1);
imagesc(T1_diff); colorbar; axis image;
title('T1 Difference Map (Fully Sampled vs Undersampled)');

subplot(1, 2, 2);
imagesc(T2_diff); colorbar; axis image;
title('T2 Difference Map (Fully Sampled vs Undersampled)');

%% Display Histograms of Differences
figure;
subplot(1, 2, 1);
histogram(T1_diff(mask), 'BinWidth', 5, 'FaceColor', 'r');
title('T1 Difference Histogram');
xlabel('Absolute Difference'); ylabel('Frequency');

subplot(1, 2, 2);
histogram(T2_diff(mask), 'BinWidth', 2, 'FaceColor', 'b');
title('T2 Difference Histogram');
xlabel('Absolute Difference'); ylabel('Frequency');



T1_diff = abs(T1_map_fully - T1_map_under);
T2_diff = abs(T2_map_fully - T2_map_under);

figure;
subplot(1, 2, 1);
imagesc(T1_diff); colorbar; title('T1 Difference Map');
subplot(1, 2, 2);
imagesc(T2_diff); colorbar; title('T2 Difference Map');

figure;
histogram(T1_map_fully(mask), 'FaceAlpha', 0.5); hold on;
histogram(T1_map_under(mask), 'FaceAlpha', 0.5);
legend('Fully Sampled', 'Undersampled');
title('T1 Value Distribution');

% Ensure the mask is applied to both maps
T1_fully_masked = T1_map_fully(mask);
T1_under_masked = T1_map_under(mask);

T2_fully_masked = T2_map_fully(mask);
T2_under_masked = T2_map_under(mask);

% Plot T1 Value Histograms
figure;
subplot(1, 2, 1); % T1 Histograms
hold on;
histogram(T1_fully_masked, 'FaceAlpha', 0.5, 'BinWidth', 5, 'DisplayName', 'Fully Sampled');
histogram(T1_under_masked, 'FaceAlpha', 0.5, 'BinWidth', 5, 'DisplayName', 'Undersampled');
legend; title('T1 Value Distribution');
xlabel('T1 Values'); ylabel('Frequency');
grid on;

% Plot T2 Value Histograms
subplot(1, 2, 2); % T2 Histograms
hold on;
histogram(T2_fully_masked, 'FaceAlpha', 0.5, 'BinWidth', 2, 'DisplayName', 'Fully Sampled');
histogram(T2_under_masked, 'FaceAlpha', 0.5, 'BinWidth', 2, 'DisplayName', 'Undersampled');
legend; title('T2 Value Distribution');
xlabel('T2 Values'); ylabel('Frequency');
grid on;

% Adjust figure for better layout
sgtitle('Comparison of T1 and T2 Value Distributions');


% Flatten T1 maps
T1_fully = T1_map_fully(:);
T1_under = T1_map_under(:);

% Flatten T2 maps
T2_fully = T2_map_fully(:);
T2_under = T2_map_under(:);

% T1 histogram
figure;
subplot(1, 2, 1);
hold on;
histogram(T1_fully, 'BinWidth', 5, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'EdgeColor', 'none'); % Blue for Fully Sampled
histogram(T1_under, 'BinWidth', 5, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'EdgeColor', 'none'); % Red for Undersampled
hold off;
xlabel('T1 Values'); ylabel('Frequency'); title('T1 Histogram');
legend('Fully Sampled', 'Undersampled');

% T2 histogram
subplot(1, 2, 2);
hold on;
histogram(T2_fully, 'BinWidth', 2, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'EdgeColor', 'none'); % Blue for Fully Sampled
histogram(T2_under, 'BinWidth', 2, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'EdgeColor', 'none'); % Red for Undersampled
hold off;
xlabel('T2 Values'); ylabel('Frequency'); title('T2 Histogram');
legend('Fully Sampled', 'Undersampled');

disp(['Number of non-zero values in Fully Sampled T1: ', num2str(nnz(T1_map_fully))]);
disp(['Number of non-zero values in Undersampled T1: ', num2str(nnz(T1_map_under))]);
disp(['Mean T1 Fully: ', num2str(mean(T1_map_fully(T1_map_fully > 0)))]);
disp(['Mean T1 Under: ', num2str(mean(T1_map_under(T1_map_under > 0)))]);

figure;
imagesc(samplingMask); colormap('gray'); axis image;
title(['Poisson Disk Sampling Mask (Sampled Points: ', num2str(nnz(samplingMask)), ')']);
