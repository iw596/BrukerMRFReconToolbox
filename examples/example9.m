% Main Script: Example Usage of poissonDiskCentralBias3

% Grid size (image dimensions)
gridSize = [128, 128];          % Grid dimensions (128x128)
undersamplingFactor = 2;        % Target undersampling factor (reduce data size by half)
radius = 4;                     % Minimum distance between sampled points in pixels
biasFactor = 10;                % Central bias factor for higher sampling density at the center

% Generate sampling and matching masks using the custom function
[samplingMask, matchingMask] = poissonDiskCentralBias3(gridSize, undersamplingFactor, radius, biasFactor);

% Visualize Sampling Mask and Matching Mask Together
figure;
subplot(1, 2, 1);
imagesc(samplingMask);
axis image; colorbar;
title('Poisson Disk Sampling Mask');

subplot(1, 2, 2);
imagesc(matchingMask);
axis image; colorbar;
title('Circular Matching Mask');

% Perform k-space undersampling using the generated sampling mask
% Assuming 'fullySampledKspace' contains the fully sampled k-space data
fullySampledKspace = randn(gridSize) + 1i * randn(gridSize); % Placeholder for demonstration
undersampledKspace = fullySampledKspace .* samplingMask;

% Visualize the k-space data
figure;
subplot(1, 2, 1);
imagesc(log(abs(fullySampledKspace) + 1)); % Log scale for better visualization
axis image; colorbar;
title('Fully Sampled k-Space');

subplot(1, 2, 2);
imagesc(log(abs(undersampledKspace) + 1)); % Log scale for better visualization
axis image; colorbar;
title('Undersampled k-Space');

% Reconstruct the images from k-space data using inverse FFT
fullySampledImage = abs(ifft2(fullySampledKspace));
undersampledImage = abs(ifft2(undersampledKspace));

% Visualize the reconstructed images
figure;
subplot(1, 2, 1);
imagesc(fullySampledImage);
axis image; colormap gray; colorbar;
title('Fully Sampled Image');

subplot(1, 2, 2);
imagesc(undersampledImage);
axis image; colormap gray; colorbar;
title('Undersampled Image');

% Display Summary of Sampling Results
disp('Summary of Sampling Results:');
disp(['Grid Size: ', num2str(gridSize(1)), 'x', num2str(gridSize(2))]);
disp(['Requested Undersampling Factor: ', num2str(undersamplingFactor)]);
disp(['Total Points in Fully Sampled Grid: ', num2str(prod(gridSize))]);
disp(['Total Sampled Points: ', num2str(sum(samplingMask(:)))]);
disp(['Achieved Undersampling Factor: ', num2str(prod(gridSize) / sum(samplingMask(:)))]);

% Additional Analysis: Visualizing Sampling Density
samplingDensity = conv2(samplingMask, ones(5), 'same'); % Convolution with 5x5 window

figure;
imagesc(samplingDensity);
axis image; colorbar;
title('Sampling Density Visualization');

figure;
imagesc(samplingMask);
colormap('hot');
colorbar;
title('Sampling Mask Visualization');

figure;
imagesc(matchingMask);
colormap('hot');
colorbar;
title('Matching Mask Visualization');

figure;
imagesc(samplingDensity);
colormap('hot');
colorbar;
title('Sampling Density Weights Visualization');
