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
fprintf('Fully Sampled: Mean = %.2f, Std = %.2f, Range = [%.2f, %.2f]\n', ...
    mean_T1_full, std_T1_full, range_T1_full(1), range_T1_full(2));
fprintf('Undersampled:   Mean = %.2f, Std = %.2f, Range = [%.2f, %.2f]\n', ...
    mean_T1_us, std_T1_us, range_T1_us(1), range_T1_us(2));
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
fprintf('Fully Sampled: Mean = %.2f, Std = %.2f, Range = [%.2f, %.2f]\n', ...
    mean_T2_full, std_T2_full, range_T2_full(1), range_T2_full(2));
fprintf('Undersampled:   Mean = %.2f, Std = %.2f, Range = [%.2f, %.2f]\n', ...
    mean_T2_us, std_T2_us, range_T2_us(1), range_T2_us(2));
fprintf('T2 RMSE (Full vs. US): %.2f\n', rmse_T2);
figure;
imagesc(undersampling_mask);
colormap(gray);
axis image;
title('Undersampling Mask');

total_samples = numel(undersampling_mask);
sampled_points = sum(undersampling_mask(:));  % assuming mask is binary (1 for sampled, 0 for not)
sampling_fraction = sampled_points / total_samples;

fprintf('Sampling Fraction: %.2f%%\n', sampling_fraction * 100);

figure;
imagesc(log(abs(kspace_undersampled(:,:,1)) + 1));  % Using log scale for better contrast
colormap(gray);
axis image;
title('Log-Scaled Undersampled k-space (Time Point 1)');

difference = abs(kspace) - abs(kspace_undersampled);
figure;
imagesc(difference(:,:,1));  % visualizing one time point
colormap(jet);
colorbar;
axis image;
title('Difference between Fully Sampled and Undersampled k-space (Time Point 1)');

figure;
subplot(1,2,1);
imagesc(abs(image_full(:,:,1)));
colormap(gray);
axis image;
title('Fully Sampled Image (Time Point 1)');

subplot(1,2,2);
imagesc(abs(image_recon(:,:,1)));
colormap(gray);
axis image;
title('Undersampled Reconstructed Image (Time Point 1)');

% Define which time points you want to view (for example, 9 evenly spaced points)
nPlots = 9;
tpIndices = round(linspace(1, size(kspace_undersampled,3), nPlots));

figure;
for i = 1:nPlots
    subplot(3, 3, i);
    t = tpIndices(i);
    imagesc(log(abs(kspace_undersampled(:,:,t)) + 1));
    colormap(gray);
    axis image;
    title(['TP ' num2str(t)]);
end
sgtitle('Log-Scaled Undersampled k-space at Selected Time Points');

% Select two time points for comparison
t1 = 1;   % For example, Time Point 1
t2 = 50;  % For example, Time Point 50 (adjust as needed)

% Compute the log-scaled k-space images for each time point
logKspace_t1 = log(abs(kspace_undersampled(:,:,t1)) + 1);
logKspace_t2 = log(abs(kspace_undersampled(:,:,t2)) + 1);

% Compute the difference image (you could choose absolute difference or simple difference)
diff_image = logKspace_t1 - logKspace_t2;

% Create a figure with three subplots
figure;

% Subplot 1: Time Point t1
subplot(1,3,1);
imagesc(logKspace_t1);
colormap(gray);
axis image;
title(['Log-Scaled k-space at TP ', num2str(t1)]);

% Subplot 2: Time Point t2
subplot(1,3,2);
imagesc(logKspace_t2);
colormap(gray);
axis image;
title(['Log-Scaled k-space at TP ', num2str(t2)]);

% Subplot 3: Difference between the two time points
subplot(1,3,3);
imagesc(diff_image);
colormap(jet);  % Using jet for better visualization of differences
colorbar;
axis image;
title('Difference (TP1 - TP2)');

% Overall title for the figure
sgtitle('Comparison of k-space Patterns at Two Selected Time Points');

linear_diff = abs(kspace_undersampled(:,:,t1)) - abs(kspace_undersampled(:,:,t2));
figure;
imagesc(linear_diff);
colormap(jet);
colorbar;
axis image;
title('Linear Difference (|TP1| - |TP2|)');
abs_diff = abs( abs(kspace_undersampled(:,:,t1)) - abs(kspace_undersampled(:,:,t2)) );
figure;
imagesc(abs_diff);
colormap(jet);
colorbar;
axis image;
title('Absolute Difference (| |TP1| - |TP2| |)');

% Display the undersampling mask for two different time points (if they are different)
figure;
subplot(1,2,1);
imagesc(undersampling_mask(:,:,t1)); % if the mask itself is time-variant
colormap(gray);
axis image;
title(['Undersampling Mask at TP ', num2str(t1)]);

subplot(1,2,2);
imagesc(undersampling_mask(:,:,t2)); % if the mask varies over time
colormap(gray);
axis image;
title(['Undersampling Mask at TP ', num2str(t2)]);

% Example: Compute correlation between two k-space slices
k1 = abs(kspace_undersampled(:,:,t1));
k2 = abs(kspace_undersampled(:,:,t2));
corr_val = corr2(k1, k2);
fprintf('Correlation between TP %d and TP %d: %.2f\n', t1, t2, corr_val);
% Choose a few time points
tpIndices = [1, 50, 100, 150];

figure;
for i = 1:length(tpIndices)
    subplot(2,2,i);
    imagesc(log(abs(kspace_undersampled(:,:,tpIndices(i))) + 1));
    colormap(gray);
    axis image;
    title(['Time Point ', num2str(tpIndices(i))]);
end
sgtitle('Log-Scaled k-space at Selected Time Points');

% Define base and comparison time points
tp_base = 1;
tp_compare = [50, 100, 150];

% Precompute the log-scaled k-space image for the base time point
logKspace_base = log(abs(kspace_undersampled(:,:,tp_base)) + 1);

% Create a new figure for the difference maps
figure;
nPlots = length(tp_compare);
for i = 1:nPlots
    % Compute the log-scaled image for the current time point
    logKspace_current = log(abs(kspace_undersampled(:,:,tp_compare(i))) + 1);
    
    % Compute the difference image (current time point - base time point)
    diff_img = logKspace_current - logKspace_base;
    
    % Plot the difference image
    subplot(1, nPlots, i);
    imagesc(diff_img);
    axis image;
    colorbar;
    
    % If Brewermap is available, you can use a diverging colormap:
    % colormap(brewermap(64, 'RdBu'));  
    % Otherwise, use 'jet'
    colormap(jet);
    
    title(['Diff: TP ' num2str(tp_compare(i)) ' - TP ' num2str(tp_base)]);
end

% Add an overall title
sgtitle('Difference Maps (Log-scaled) Relative to Time Point 1');

% Create a new figure for the histograms
figure;

% --- Histogram for Fully Sampled T1 ---
subplot(2,2,1);
histogram(T1_full(:), 50, 'FaceColor', 'b');  % 50 bins, blue color for clarity
title('Fully Sampled T1 Distribution');
xlabel('T1 (ms)');
ylabel('Frequency');
grid on;

% --- Histogram for Undersampled T1 ---
subplot(2,2,2);
histogram(T1_us(:), 50, 'FaceColor', 'r');  % 50 bins, red color for clarity
title('Undersampled T1 Distribution');
xlabel('T1 (ms)');
ylabel('Frequency');
grid on;

% --- Histogram for Fully Sampled T2 ---
subplot(2,2,3);
histogram(T2_full(:), 50, 'FaceColor', 'b');  % 50 bins, blue color for clarity
title('Fully Sampled T2 Distribution');
xlabel('T2 (ms)');
ylabel('Frequency');
grid on;

% --- Histogram for Undersampled T2 ---
subplot(2,2,4);
histogram(T2_us(:), 50, 'FaceColor', 'r');  % 50 bins, red color for clarity
title('Undersampled T2 Distribution');
xlabel('T2 (ms)');
ylabel('Frequency');
grid on;

% Add an overall title for the figure (requires MATLAB R2018b or later)
sgtitle('Histogram Comparison of T1 and T2 Distributions');

figure;

% --- Subplot for T1 ---
subplot(1,2,1);
% Histogram for Fully Sampled T1 in blue
histogram(T1_full(:), 50, 'FaceColor', 'b', 'FaceAlpha', 0.5);
hold on;
% Histogram for Undersampled T1 in red
histogram(T1_us(:), 50, 'FaceColor', 'r', 'FaceAlpha', 0.5);
hold off;
title('T1 Distribution');
xlabel('T1 (ms)');
ylabel('Frequency');
legend('Fully Sampled','Undersampled');
grid on;

% --- Subplot for T2 ---
subplot(1,2,2);
% Histogram for Fully Sampled T2 in blue
histogram(T2_full(:), 50, 'FaceColor', 'b', 'FaceAlpha', 0.5);
hold on;
% Histogram for Undersampled T2 in red
histogram(T2_us(:), 50, 'FaceColor', 'r', 'FaceAlpha', 0.5);
hold off;
title('T2 Distribution');
xlabel('T2 (ms)');
ylabel('Frequency');
legend('Fully Sampled','Undersampled');
grid on;

% Overall title for the figure (MATLAB R2018b or later)
sgtitle('Overlay Histograms for T1 and T2 Distributions');


figure;
% Define bin limits for T1, starting from a small positive value (e.g., 1)
histogram(T1_full(:), 'BinLimits', [1, max(T1_full(:))], 'FaceColor', 'b', 'FaceAlpha', 0.5);
hold on;
histogram(T1_us(:), 'BinLimits', [1, max(T1_us(:))], 'FaceColor', 'r', 'FaceAlpha', 0.5);
hold off;
title('Overlay Histogram: T1 Distribution (BinLimits set from 1)');
xlabel('T1 (ms)');
ylabel('Frequency');
legend('Fully Sampled','Undersampled');
grid on;
figure;
% Define bin limits for T2, starting from a small positive value (e.g., 1)
histogram(T2_full(:), 'BinLimits', [1, max(T2_full(:))], 'FaceColor', 'b', 'FaceAlpha', 0.5);
hold on;
histogram(T2_us(:), 'BinLimits', [1, max(T2_us(:))], 'FaceColor', 'r', 'FaceAlpha', 0.5);
hold off;
title('Overlay Histogram: T2 Distribution (BinLimits set from 1)');
xlabel('T2 (ms)');
ylabel('Frequency');
legend('Fully Sampled','Undersampled');
grid on;

% Define image dimensions (assumed to be 128x128x1980)
[Nx, Ny, Nt] = size(image_full);  % Nx=128, Ny=128, Nt=1980

% Define voxel coordinates (row, column) 
% Central voxel:
voxel1 = [round(Ny/2), round(Nx/2)];  % e.g., [64, 64]

% Voxel from top left quadrant:
voxel2 = [round(Ny/4), round(Nx/4)];  % e.g., [32, 32]

% Voxel from bottom right quadrant:
voxel3 = [round(3*Ny/4), round(3*Nx/4)];  % e.g., [96, 96]

% Extract temporal signals using squeeze to convert the 1x1xNt slice into a vector.
signal_full_v1 = squeeze(image_full(voxel1(1), voxel1(2), :));
signal_recon_v1 = squeeze(image_recon(voxel1(1), voxel1(2), :));

signal_full_v2 = squeeze(image_full(voxel2(1), voxel2(2), :));
signal_recon_v2 = squeeze(image_recon(voxel2(1), voxel2(2), :));

signal_full_v3 = squeeze(image_full(voxel3(1), voxel3(2), :));
signal_recon_v3 = squeeze(image_recon(voxel3(1), voxel3(2), :));

% Create a time vector (if time points are indexed sequentially)
time = 1:Nt;

% Plot the temporal signals for each voxel in subplots
figure;

% Subplot 1: Central Voxel
subplot(3,1,1);
plot(time, signal_full_v1, 'b-', 'LineWidth', 1.5); hold on;
plot(time, signal_recon_v1, 'r--', 'LineWidth', 1.5); hold off;
title(['Temporal Signal at Central Voxel (' num2str(voxel1(1)) ',' num2str(voxel1(2)) ')']);
xlabel('Time Point'); ylabel('Signal Intensity');
legend('Fully Sampled','Undersampled');
grid on;

% Subplot 2: Top Left Voxel
subplot(3,1,2);
plot(time, signal_full_v2, 'b-', 'LineWidth', 1.5); hold on;
plot(time, signal_recon_v2, 'r--', 'LineWidth', 1.5); hold off;
title(['Temporal Signal at Top Left Voxel (' num2str(voxel2(1)) ',' num2str(voxel2(2)) ')']);
xlabel('Time Point'); ylabel('Signal Intensity');
legend('Fully Sampled','Undersampled');
grid on;

% Subplot 3: Bottom Right Voxel
subplot(3,1,3);
plot(time, signal_full_v3, 'b-', 'LineWidth', 1.5); hold on;
plot(time, signal_recon_v3, 'r--', 'LineWidth', 1.5); hold off;
title(['Temporal Signal at Bottom Right Voxel (' num2str(voxel3(1)) ',' num2str(voxel3(2)) ')']);
xlabel('Time Point'); ylabel('Signal Intensity');
legend('Fully Sampled','Undersampled');
grid on;

% Add an overall title to the figure
sgtitle('Temporal Signal Evolution for Selected Voxels');

plot(time, abs(signal_full_v1), 'b-', 'LineWidth', 1.5);
hold on;
plot(time, abs(signal_recon_v1), 'r--', 'LineWidth', 1.5);
hold off;

% Define image dimensions (assumed to be 128x128x1980)
[Nx, Ny, Nt] = size(image_full);  % Nx=128, Ny=128, Nt=1980

% Define voxel coordinates (row, column) 
% Central voxel:
voxel1 = [round(Ny/2), round(Nx/2)];  % e.g., [64, 64]

% Voxel from top left quadrant:
voxel2 = [round(Ny/4), round(Nx/4)];  % e.g., [32, 32]

% Voxel from bottom right quadrant:
voxel3 = [round(3*Ny/4), round(3*Nx/4)];  % e.g., [96, 96]

% Extract temporal signals using squeeze to convert the 1x1xNt slice into a vector.
signal_full_v1 = squeeze(image_full(voxel1(1), voxel1(2), :));
signal_recon_v1 = squeeze(image_recon(voxel1(1), voxel1(2), :));

signal_full_v2 = squeeze(image_full(voxel2(1), voxel2(2), :));
signal_recon_v2 = squeeze(image_recon(voxel2(1), voxel2(2), :));

signal_full_v3 = squeeze(image_full(voxel3(1), voxel3(2), :));
signal_recon_v3 = squeeze(image_recon(voxel3(1), voxel3(2), :));

% Create a time vector (if time points are indexed sequentially)
time = 1:Nt;

% Plot the temporal signals for each voxel in subplots using the magnitude
figure;

% Subplot 1: Central Voxel
subplot(3,1,1);
plot(time, abs(signal_full_v1), 'b-', 'LineWidth', 1.5); hold on;
plot(time, abs(signal_recon_v1), 'r--', 'LineWidth', 1.5); hold off;
title(['Temporal Signal at Central Voxel (' num2str(voxel1(1)) ',' num2str(voxel1(2)) ')']);
xlabel('Time Point'); ylabel('Signal Magnitude');
legend('Fully Sampled','Undersampled');
grid on;

% Subplot 2: Top Left Voxel
subplot(3,1,2);
plot(time, abs(signal_full_v2), 'b-', 'LineWidth', 1.5); hold on;
plot(time, abs(signal_recon_v2), 'r--', 'LineWidth', 1.5); hold off;
title(['Temporal Signal at Top Left Voxel (' num2str(voxel2(1)) ',' num2str(voxel2(2)) ')']);
xlabel('Time Point'); ylabel('Signal Magnitude');
legend('Fully Sampled','Undersampled');
grid on;

% Subplot 3: Bottom Right Voxel
subplot(3,1,3);
plot(time, abs(signal_full_v3), 'b-', 'LineWidth', 1.5); hold on;
plot(time, abs(signal_recon_v3), 'r--', 'LineWidth', 1.5); hold off;
title(['Temporal Signal at Bottom Right Voxel (' num2str(voxel3(1)) ',' num2str(voxel3(2)) ')']);
xlabel('Time Point'); ylabel('Signal Magnitude');
legend('Fully Sampled','Undersampled');
grid on;

% Overall title for the figure
sgtitle('Temporal Signal Evolution for Selected Voxels (Magnitude)');
% Compute the voxel-wise RMSE over time
% We take the magnitude of the signals to avoid sign issues.
rmse_map = sqrt(mean((abs(image_full) - abs(image_recon)).^2, 3));
rmse_map = sqrt(mean((abs(image_full) - abs(image_recon)).^2, 3));
figure;
imagesc(rmse_map);
colormap('hot');  % or any colormap of your choice
colorbar;
axis image;
title('Voxel-wise RMSE between Fully Sampled and Undersampled Data');
xlabel('X (pixels)');
ylabel('Y (pixels)');

% Compute the temporal mean and standard deviation at each voxel (using magnitude)
mean_map = mean(abs(image_full), 3);
std_map  = std(abs(image_full), 0, 3);

% Compute SNR; add a small constant (eps) to avoid division by zero
snr_map = mean_map ./ (std_map + eps);

% Display basic statistics of the SNR map (optional)
fprintf('SNR Map - Min: %.2f, Max: %.2f, Mean: %.2f\n', min(snr_map(:)), max(snr_map(:)), mean(snr_map(:)));
figure;

% Subplot 1: SNR Map
subplot(1,2,1);
imagesc(snr_map);
colormap('jet');   % 'jet' is good for visual contrast; you can try others like 'parula'
colorbar;
axis image;
title('SNR Map (Fully Sampled Data)');

% Subplot 2: RMSE Map
subplot(1,2,2);
imagesc(rmse_map);
colormap('hot');   % 'hot' emphasizes high error regions
colorbar;
axis image;
title('Voxel-wise RMSE Map');

sgtitle('Comparison: SNR Map vs. RMSE Map');
% Reshape the maps into vectors for scatter plotting
snr_vec = snr_map(:);
rmse_vec = rmse_map(:);

figure;
scatter(snr_vec, rmse_vec, 10, 'filled');  % Use marker size 10
xlabel('SNR');
ylabel('RMSE');
title('Scatter Plot of SNR vs. RMSE');
grid on;
% Compute temporal mean and standard deviation for each voxel from undersampled data
mean_map_us = mean(abs(image_recon), 3);
std_map_us  = std(abs(image_recon), 0, 3);

% Compute SNR; add a small constant (eps) to avoid division by zero
snr_map_us = mean_map_us ./ (std_map_us + eps);

% Display basic statistics (optional)
fprintf('Undersampled SNR Map - Min: %.2f, Max: %.2f, Mean: %.2f\n', ...
    min(snr_map_us(:)), max(snr_map_us(:)), mean(snr_map_us(:)));
figure;
imagesc(snr_map_us);
colormap('jet');
colorbar;
axis image;
title('SNR Map (Undersampled Data)');
xlabel('X (pixels)');
ylabel('Y (pixels)');
