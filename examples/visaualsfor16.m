% Check if sampling patterns are different across time points
unique_patterns = true;

for t = 2:numTimePoints
    if isequal(samplingMasks(:, :, t), samplingMasks(:, :, t-1))
        fprintf('Time point %d and %d have the same sampling pattern.\n', t-1, t);
        unique_patterns = false;
    end
end

if unique_patterns
    disp('All sampling patterns are unique across time points.');
else
    disp('Some sampling patterns are identical. Adjust randomization settings.');
end

% Visualize patterns for a few time points
figure;
for i = 1:6
    subplot(2, 3, i);
    imshow(samplingMasks(:, :, i), []);
    title(['Mask for Time Point ' num2str(i)]);
end

% Compare patterns between two random time points
tp1 = randi([1, numTimePoints]);
tp2 = randi([1, numTimePoints]);

figure;
subplot(1, 2, 1);
imshow(samplingMasks(:, :, tp1), []);
title(['Mask for Time Point ' num2str(tp1)]);

subplot(1, 2, 2);
imshow(samplingMasks(:, :, tp2), []);
title(['Mask for Time Point ' num2str(tp2)]);

% Display difference between two masks
difference = samplingMasks(:, :, tp1) - samplingMasks(:, :, tp2);
figure;
imshow(difference, []);
title(['Difference Between Masks ' num2str(tp1) ' and ' num2str(tp2)]);


difference = abs(imgs) - abs(undersampled_imgs);
figure; montage(mat2gray(difference)); title('Difference Between Reconstructions');

% Create a video of undersampled reconstructions
figure;
for t = 1:size(undersampled_imgs, 3)
    imshow(mat2gray(abs(undersampled_imgs(:, :, t))), []);
    title(['Undersampled Reconstruction - Time Point: ' num2str(t)]);
    pause(0.1); % Adjust pause time for animation speed
end

% Select a pixel or region (e.g., center pixel)
x = 64; % Row index
y = 64; % Column index

% Extract intensity profiles over time
fully_sampled_profile = squeeze(abs(imgs(x, y, :)));
undersampled_profile = squeeze(abs(undersampled_imgs(x, y, :)));

% Plot the temporal profiles
figure;
plot(fully_sampled_profile, 'b', 'DisplayName', 'Fully Sampled');
hold on;
plot(undersampled_profile, 'r', 'DisplayName', 'Undersampled');
legend;
title('Temporal Profile of Pixel Intensity');
xlabel('Time Point');
ylabel('Intensity');

% Define pixel coordinates for analysis (center, edge, corners)
pixel_coords = [
    64, 64;   % Center pixel
    10, 10;   % Top-left corner
    10, 118;  % Top-right corner
    118, 10;  % Bottom-left corner
    118, 118; % Bottom-right corner
    64, 10;   % Middle of left edge
    64, 118;  % Middle of right edge
    10, 64;   % Middle of top edge
    118, 64   % Middle of bottom edge
];

% Number of pixels to analyze
num_pixels = size(pixel_coords, 1);

% Plot temporal profiles for selected pixels
figure;
for i = 1:num_pixels
    x = pixel_coords(i, 1); % Row index
    y = pixel_coords(i, 2); % Column index
    
    % Extract intensity profiles over time
    fully_sampled_profile = squeeze(abs(imgs(x, y, :)));
    undersampled_profile = squeeze(abs(undersampled_imgs(x, y, :)));
    
    % Plot temporal profile
    subplot(3, 3, i); % Create a grid of subplots
    plot(fully_sampled_profile, 'b', 'DisplayName', 'Fully Sampled');
    hold on;
    plot(undersampled_profile, 'r', 'DisplayName', 'Undersampled');
    title(['Pixel (' num2str(x) ', ' num2str(y) ')']);
    xlabel('Time Point');
    ylabel('Intensity');
    legend;
    hold off;
end

for i = 1:num_pixels
    x = pixel_coords(i, 1);
    y = pixel_coords(i, 2);
    fully_sampled_profile = squeeze(abs(imgs(x, y, :)));
    undersampled_profile = squeeze(abs(undersampled_imgs(x, y, :)));

    % Compute RMSE
    rmse = sqrt(mean((fully_sampled_profile - undersampled_profile).^2));
    fprintf('Pixel (%d, %d): RMSE = %.4f\n', x, y, rmse);

    % Compute Correlation
    correlation = corr(fully_sampled_profile, undersampled_profile);
    fprintf('Pixel (%d, %d): Correlation = %.4f\n', x, y, correlation);
end

temporal_variance = var(abs(imgs) - abs(undersampled_imgs), 0, 3);
figure;
imagesc(temporal_variance);
colorbar;
title('Temporal Variance Heatmap');
xlabel('X Pixels');
ylabel('Y Pixels');

% Manual computation of Pearson Correlation Coefficient
numerator = sum((fully_sampled_profile - mean(fully_sampled_profile)) .* ...
                (undersampled_profile - mean(undersampled_profile)));
denominator = sqrt(sum((fully_sampled_profile - mean(fully_sampled_profile)).^2)) * ...
              sqrt(sum((undersampled_profile - mean(undersampled_profile)).^2));
correlation = numerator / denominator;

fprintf('Pixel (%d, %d): Correlation = %.4f\n', x, y, correlation);

figure;
imshow(mat2gray(abs(imgs(:, :, 1))) + temporal_variance, []);
title('Reconstructed Image with Artefact Heatmap Overlay');

for i = 1:num_pixels
    x = pixel_coords(i, 1);
    y = pixel_coords(i, 2);
    fully_sampled_profile = squeeze(abs(imgs(x, y, :)));
    undersampled_profile = squeeze(abs(undersampled_imgs(x, y, :)));

    % Compute Correlation Manually
    numerator = sum((fully_sampled_profile - mean(fully_sampled_profile)) .* ...
                    (undersampled_profile - mean(undersampled_profile)));
    denominator = sqrt(sum((fully_sampled_profile - mean(fully_sampled_profile)).^2)) * ...
                  sqrt(sum((undersampled_profile - mean(undersampled_profile)).^2));
    correlation = numerator / denominator;

    fprintf('Pixel (%d, %d): Correlation = %.4f\n', x, y, correlation);
end

% Visualize the sampling mask
figure;
imshow(samplingMasks, []);
title('Sampling Mask');

% Visualize fully sampled and undersampled k-space
figure;
subplot(1, 2, 1);
imagesc(log(1 + abs(kspace))); % Fully sampled k-space
title('Fully Sampled K-space');
colorbar;

subplot(1, 2, 2);
imagesc(log(1 + abs(undersampled_kspace))); % Undersampled k-space
title('Undersampled K-space');
colorbar;
% Ensure the sampling mask is a valid grayscale image
figure;
imshow(mat2gray(samplingMasks)); % Normalize the mask to the range [0, 1]
title('Sampling Mask');

% Select a single k-space slice for visualization (e.g., first time point)
kspace_full_slice = abs(kspace(:, :, 1)); % Magnitude of fully sampled k-space (time point 1)
kspace_undersampled_slice = abs(undersampled_kspace(:, :, 1)); % Magnitude of undersampled k-space (time point 1)

% Visualize fully sampled k-space
figure;
subplot(1, 2, 1);
imagesc(log(1 + kspace_full_slice)); % Log magnitude visualization
title('Fully Sampled K-space');
colormap gray;
colorbar;

% Visualize undersampled k-space
subplot(1, 2, 2);
imagesc(log(1 + kspace_undersampled_slice)); % Log magnitude visualization
title('Undersampled K-space');
colormap gray;
colorbar;

figure;
imshow(samplingMasks, []);
title('Sampling Mask');

[rows, cols] = find(samplingMasks); % Coordinates of sampled points
distances = pdist([rows, cols]); % Pairwise distances
histogram(distances); % Visualize distribution of distances
title('Histogram of Sampling Distances');

figure;
heatmap(samplingMasks, 'Colormap', gray, 'ColorLimits', [0, 1]);
title('Sampling Mask');


figure;
imagesc(samplingMasks); % Visualize the sampling mask
colormap gray; % Use a grayscale colormap
colorbar; % Add a color bar for intensity reference
title('Sampling Mask');
axis image; % Ensure equal aspect ratio for the axes

% Select the sampling mask for the first time point (slice)
sampling_mask_single = samplingMasks(:, :, 1);

% Visualize the single sampling mask
figure;
imagesc(sampling_mask_single);
colormap gray; % Grayscale visualization
colorbar; % Add a color bar
title('Sampling Mask for Time Point 1');
axis image; % Maintain aspect ratio

for t = 1:5:1980 % Adjust the step size (1:5) as needed
    sampling_mask_single = samplingMasks(:, :, t);
    figure;
    imagesc(sampling_mask_single);
    colormap gray;
    colorbar;
    title(['Sampling Mask for Time Point ', num2str(t)]);
    pause(0.5);
end

% Compute reconstruction differences
diff_imgs = abs(imgs) - abs(undersampled_imgs);

% Visualize reconstructions and differences for selected time points
time_points = [1, 500, 1000, 1500, 1980]; % Select representative time points
for t = time_points
    figure;
    subplot(1, 3, 1);
    imagesc(abs(imgs(:, :, t))); colormap gray; colorbar;
    title(['Fully Sampled Image at Time Point ', num2str(t)]);
    
    subplot(1, 3, 2);
    imagesc(abs(undersampled_imgs(:, :, t))); colormap gray; colorbar;
    title(['Undersampled Image at Time Point ', num2str(t)]);
    
    subplot(1, 3, 3);
    imagesc(diff_imgs(:, :, t)); colormap jet; colorbar;
    title(['Difference Image at Time Point ', num2str(t)]);
end

rmse_time = sqrt(mean((abs(imgs) - abs(undersampled_imgs)).^2, [1, 2]));
plot(1:1980, rmse_time);
xlabel('Time Point');
ylabel('RMSE');
title('RMSE Across Time Points');

% Compute RMSE across time points
rmse_time = sqrt(mean((abs(imgs) - abs(undersampled_imgs)).^2, [1, 2]));

% Squeeze to ensure rmse_time is a 1D vector
rmse_time = squeeze(rmse_time);

% Plot RMSE over time points
figure;
plot(1:length(rmse_time), rmse_time, 'LineWidth', 1.5);
xlabel('Time Point');
ylabel('RMSE');
title('RMSE Across Time Points');
grid on;

temporal_variance = var(abs(imgs) - abs(undersampled_imgs), 0, 3);
imagesc(temporal_variance);
colormap jet; colorbar;
title('Temporal Variance of Artefacts');

maskSum = sum(samplingMasks(:, :, 1), 'all');
disp(['Total sampled points in the mask: ', num2str(maskSum)]);

centralMask = samplingMasks(57:72, 57:72, 1); % Adjust indices to match 15% coverage
centralPoints = sum(centralMask, 'all');
peripheralPoints = maskSum - centralPoints;
disp(['Central points: ', num2str(centralPoints)]);
disp(['Peripheral points: ', num2str(peripheralPoints)]);

[rows, cols] = find(samplingMasks(:, :, 1));
scatter(cols, rows, 'r.');
axis equal;
xlim([0, 128]); ylim([0, 128]);
title('Sampled Points in the Mask');

[rows, cols] = find(samplingMasks(:, :, 1) == 1); % Find all sampled points
figure;
scatter(cols, rows, 5, 'r', 'filled'); % Adjust marker size for better visibility
axis equal;
xlim([0, 128]); ylim([0, 128]);
title('Sampling Points Distribution');

disp(['Total sampled points in mask: ', num2str(nnz(masks(:, :, t)))]);
