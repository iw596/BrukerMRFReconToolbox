
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

% parameters

matrixSize = [128, 128]; % 2D Cartesian matrix size
targetPoints = round(prod(matrixSize) / 40); % Undersampling factor ~40
numTimePoints = 1980; % Number of time points in MRF signal train
centralBiasFactor = 2; % Decay parameter for central bias

% Generate sampling masks
samplingMasks = optimizedPoissonDiskSampling14(matrixSize, targetPoints, numTimePoints, centralBiasFactor);

% Apply sampling masks to k-space data
undersampled_kspace = zeros(size(kspace)); % Initialize undersampled k-space
for t = 1:numTimePoints
    undersampled_kspace(:, :, t) = kspace(:, :, t) .* samplingMasks(:, :, t);
end

% % Visualize the sampling mask for one time point
% timePointToVisualize = 1; % Change this to visualize other time points
% figure;
% imagesc(samplingMasks(:, :, timePointToVisualize));
% colormap('gray');
% colorbar;
% axis image;
% title(['Sampling Mask at Time Point ', num2str(timePointToVisualize)]);

% Visualize the sampling mask for one time point
timePointToVisualize = 1; % Change this to visualize other time points
figure;
imagesc(samplingMasks(:, :, timePointToVisualize));
colormap('gray');
colorbar;
axis image;
title(['Sampling Mask at Time Point ', num2str(timePointToVisualize)]);


% % % Visualize the sampling mask 
% figure;
% imagesc(samplingMask); colormap('gray'); axis image;
% title('Poisson Disk Sampling Mask');
% % Analyze Sampling
% numPoints = sum(samplingMask(:));
% disp(['Total sampled points: ', num2str(numPoints)]);

% Generate Poisson disk sampling mask 
% undersamplingFactor = 2; % Retain 50% of k-space
% radius = 4; % Minimum spacing between points

% % Dynamically adjust radius if necessary
% totalPoints = round(prod([128, 128]) / undersamplingFactor);
% maxRadius = sqrt(prod([128, 128]) / pi / totalPoints);
% if radius > maxRadius
%     disp(['Radius adjusted to ', num2str(maxRadius)]);
%     radius = maxRadius;
% end

% Call the function
% samplingMask = poissonDiskMask([128, 128], undersamplingFactor, radius);

% % Debug: Check number of sampled points
% actualSampledPoints = sum(samplingMask(:));
% disp(['Requested points: ', num2str(totalPoints)]);
% disp(['Sampled points: ', num2str(actualSampledPoints)]);
% if actualSampledPoints < totalPoints * 0.5
%     warning('Significantly fewer points sampled than requested. Check undersampling parameters.');
% end
% disp(['Number of non-zero points in mask: ', num2str(nnz(samplingMask))]);

% Apply the mask to fully sampled k-space to create undersampled data
% undersampled_kspace = kspace .* repmat(samplingMask, [1, 1, size(kspace, 3)]);

% % Save undersampled k-space data for future use
% save('undersampled_kspace_data.mat', 'undersampled_kspace');
% disp('Undersampled k-space data generated and saved.');

% % Visualize the sampling mask 
% figure;
% imagesc(samplingMask); colormap('gray'); axis image;
% title('Poisson Disk Sampling Mask');

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


% %% Compare Selected Voxels
selected_voxels = [50, 50; 30, 40; 60, 70; 100, 100];
for v = 1:size(selected_voxels, 1)
    x = selected_voxels(v, 1);
    y = selected_voxels(v, 2);
    disp(['Voxel (' num2str(x) ',' num2str(y) '):']);
    disp(['  Fully Sampled - T1: ' num2str(T1_fully(x, y)) ', T2: ' num2str(T2_fully(x, y))]);
    disp(['  Undersampled  - T1: ' num2str(T1_under(x, y)) ', T2: ' num2str(T2_under(x, y))]);
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

%% Quantify Differences Between Fully Sampled and Undersampled Maps

% Flatten the masked values
T1_fully_masked = T1_maps{1}(mask);
T1_under_masked = T1_maps{2}(mask);
T2_fully_masked = T2_maps{1}(mask);
T2_under_masked = T2_maps{2}(mask);

% Compute statistics for T1 values
T1_fully_mean = mean(T1_fully_masked);
T1_fully_std = std(T1_fully_masked);
T1_fully_range = [min(T1_fully_masked), max(T1_fully_masked)];

T1_under_mean = mean(T1_under_masked);
T1_under_std = std(T1_under_masked);
T1_under_range = [min(T1_under_masked), max(T1_under_masked)];

% Compute statistics for T2 values
T2_fully_mean = mean(T2_fully_masked);
T2_fully_std = std(T2_fully_masked);
T2_fully_range = [min(T2_fully_masked), max(T2_fully_masked)];

T2_under_mean = mean(T2_under_masked);
T2_under_std = std(T2_under_masked);
T2_under_range = [min(T2_under_masked), max(T2_under_masked)];

% Display the results
fprintf('--- T1 Comparison ---\n');
fprintf('Fully Sampled - Mean: %.2f, Std: %.2f, Range: [%.2f, %.2f]\n', ...
    T1_fully_mean, T1_fully_std, T1_fully_range(1), T1_fully_range(2));
fprintf('Undersampled - Mean: %.2f, Std: %.2f, Range: [%.2f, %.2f]\n', ...
    T1_under_mean, T1_under_std, T1_under_range(1), T1_under_range(2));

fprintf('\n--- T2 Comparison ---\n');
fprintf('Fully Sampled - Mean: %.2f, Std: %.2f, Range: [%.2f, %.2f]\n', ...
    T2_fully_mean, T2_fully_std, T2_fully_range(1), T2_fully_range(2));
fprintf('Undersampled - Mean: %.2f, Std: %.2f, Range: [%.2f, %.2f]\n', ...
    T2_under_mean, T2_under_std, T2_under_range(1), T2_under_range(2));
%% Comparison Between Fully Sampled and Undersampled T1/T2 Values

% Flatten the T1 and T2 maps (consider only masked voxels)
T1_fully = T1_maps{1}(mask);
T1_under = T1_maps{2}(mask);

T2_fully = T2_maps{1}(mask);
T2_under = T2_maps{2}(mask);



% ---- 2. Histograms ----
figure;
subplot(1, 2, 1);
histogram(T1_fully, 'BinWidth', 5, 'FaceAlpha', 0.5, 'FaceColor', 'b'); hold on;
histogram(T1_under, 'BinWidth', 5, 'FaceAlpha', 0.5, 'FaceColor', 'r');
legend('Fully Sampled', 'Undersampled');
title('T1 Histogram Comparison');
xlabel('T1 Values'); ylabel('Frequency'); grid on;

subplot(1, 2, 2);
histogram(T2_fully, 'BinWidth', 2, 'FaceAlpha', 0.5, 'FaceColor', 'b'); hold on;
histogram(T2_under, 'BinWidth', 2, 'FaceAlpha', 0.5, 'FaceColor', 'r');
legend('Fully Sampled', 'Undersampled');
title('T2 Histogram Comparison');
xlabel('T2 Values'); ylabel('Frequency'); grid on;


T1_fully = T1_maps{1};
T1_under = T1_maps{2};
T2_fully = T2_maps{1};
T2_under = T2_maps{2};

% ---- 4. Numerical Comparison ----
fprintf('Numerical Comparison of T1 and T2 Maps:\n');
fprintf('T1 Fully Sampled: Mean = %.2f, Std = %.2f\n', mean(T1_fully), std(T1_fully));
fprintf('T1 Undersampled: Mean = %.2f, Std = %.2f\n', mean(T1_under), std(T1_under));
fprintf('T2 Fully Sampled: Mean = %.2f, Std = %.2f\n', mean(T2_fully), std(T2_fully));
fprintf('T2 Undersampled: Mean = %.2f, Std = %.2f\n', mean(T2_under), std(T2_under));
%% Calculate RMSE Between Fully Sampled and Undersampled Maps
% Extract Fully Sampled and Undersampled T1/T2 Maps
T1_fully = T1_maps{1};
T1_under = T1_maps{2};
T2_fully = T2_maps{1};
T2_under = T2_maps{2};

% Apply mask to consider only valid voxels
T1_fully_masked = T1_fully(mask);
T1_under_masked = T1_under(mask);
T2_fully_masked = T2_fully(mask);
T2_under_masked = T2_under(mask);

% Calculate RMSE for T1 and T2
RMSE_T1 = sqrt(mean((T1_fully_masked - T1_under_masked).^2));
RMSE_T2 = sqrt(mean((T2_fully_masked - T2_under_masked).^2));

% Display RMSE Results
disp(['RMSE for T1 Maps: ', num2str(RMSE_T1)]);
disp(['RMSE for T2 Maps: ', num2str(RMSE_T2)]);

T1_error = abs(T1_fully - T1_under);
figure; imagesc(T1_error); colorbar; title('T1 Error Map');

% Compute Absolute Error Map for T2
T2_diff = abs(T2_maps{1} - T2_maps{2}); % Assuming {1} is fully sampled and {2} is undersampled

% Plot T2 Error Map
figure;
imagesc(T2_diff); 
colorbar;
axis image;
title('Absolute T2 Error Map');
xlabel('X');
ylabel('Y');

%% Compute and Visualize Difference Maps
% Extract Fully Sampled and Undersampled T1/T2 Maps
T1_fully = T1_maps{1};
T1_under = T1_maps{2};
T2_fully = T2_maps{1};
T2_under = T2_maps{2};

% Compute Differences
T1_diff = abs(T1_fully - T1_under);
T2_diff = abs(T2_fully - T2_under);

% Visualize T1 and T2 Maps Side-by-Side
figure;
subplot(2, 2, 1);
imagesc(T1_fully); axis image; colorbar;
title('Fully Sampled T1 Map');

subplot(2, 2, 2);
imagesc(T1_under); axis image; colorbar;
title('Undersampled T1 Map');

subplot(2, 2, 3);
imagesc(T2_fully); axis image; colorbar;
title('Fully Sampled T2 Map');

subplot(2, 2, 4);
imagesc(T2_under); axis image; colorbar;
title('Undersampled T2 Map');

% Visualize Difference Maps
figure;
subplot(1, 2, 1);
imagesc(T1_diff); axis image; colorbar;
title('T1 Difference Map');

subplot(1, 2, 2);
imagesc(T2_diff); axis image; colorbar;
title('T2 Difference Map');

%% Visualize Histograms for T1 and T2 Values
% Masked Values Only
T1_fully_masked = T1_fully(mask);
T1_under_masked = T1_under(mask);
T2_fully_masked = T2_fully(mask);
T2_under_masked = T2_under(mask);

% T1 Histograms
figure;
subplot(1, 2, 1);
hold on;
histogram(T1_fully_masked, 'BinWidth', 5, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
histogram(T1_under_masked, 'BinWidth', 5, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
legend('Fully Sampled', 'Undersampled');
xlabel('T1 Values'); ylabel('Frequency');
title('T1 Value Distribution');
grid on;

% T2 Histograms
subplot(1, 2, 2);
hold on;
histogram(T2_fully_masked, 'BinWidth', 2, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
histogram(T2_under_masked, 'BinWidth', 2, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
legend('Fully Sampled', 'Undersampled');
xlabel('T2 Values'); ylabel('Frequency');
title('T2 Value Distribution');
grid on;

sgtitle('Comparison of T1 and T2 Value Distributions');


%% Visualize Comparison of Fully Sampled, Undersampled, and Error Maps
figure;

% Fully Sampled T1 Map
subplot(2, 3, 1);
imagesc(T1_maps{1}); axis image; colorbar;
title('Fully Sampled T1 Map');

% Fully Sampled T2 Map
subplot(2, 3, 2);
imagesc(T2_maps{1}); axis image; colorbar;
title('Fully Sampled T2 Map');

% T1 Error Map
subplot(2, 3, 3);
imagesc(T1_diff); axis image; colorbar;
title('T1 Error Map');

% Undersampled T1 Map
subplot(2, 3, 4);
imagesc(T1_maps{2}); axis image; colorbar;
title('Undersampled T1 Map');

% Undersampled T2 Map
subplot(2, 3, 5);
imagesc(T2_maps{2}); axis image; colorbar;
title('Undersampled T2 Map');

% T2 Error Map
subplot(2, 3, 6);
imagesc(T2_diff); axis image; colorbar;
title('T2 Error Map');

% Adjust layout
sgtitle('Comparison of Fully Sampled, Undersampled, and Error Maps');

totalSampledPoints = nnz(samplingMask);
disp(['Total sampled points: ', num2str(totalSampledPoints)]);

