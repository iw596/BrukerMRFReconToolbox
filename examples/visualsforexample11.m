% Load the sampling mask and parameters
center = gridSize / 2; % Center of the grid
[X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));

% Get sampled points' coordinates
sampledCoords = [X(samplingMask == 1), Y(samplingMask == 1)];
distances = sqrt((sampledCoords(:, 1) - center(1)).^2 + (sampledCoords(:, 2) - center(2)).^2);

% Display statistics
disp(['Total Sampled Points: ', num2str(length(distances))]);
disp(['Mean Distance from Center: ', num2str(mean(distances))]);
disp(['Max Distance from Center: ', num2str(max(distances))]);
disp(['Min Distance from Center: ', num2str(min(distances))]);

% Plot histogram of distances
figure;
histogram(distances, 'BinWidth', 2, 'Normalization', 'probability');
xlabel('Distance from Center');
ylabel('Proportion of Points');
title('Distribution of Sampled Points by Distance');
grid on;

% Create a density map
densityMap = zeros(gridSize);
for i = 1:size(sampledCoords, 1)
    x = sampledCoords(i, 1);
    y = sampledCoords(i, 2);
    densityMap(x, y) = densityMap(x, y) + 1;
end

% Plot the density map
figure;
imagesc(densityMap);
colormap('hot');
colorbar;
axis image;
title('Sampling Density Map');

% Parameters
center = round(gridSize / 2);
[X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
distances = sqrt((X - center(1)).^2 + (Y - center(2)).^2);

% Filter distances for sampled points
sampledDistances = distances(logical(samplingMask));

% Histogram of radial distances
binEdges = linspace(0, max(distances(:)), 20); % Adjust bins if needed
radialDensity = histcounts(sampledDistances, binEdges);
binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;

% Normalize to total points
radialDensity = radialDensity / sum(radialDensity);

% Plot the density profile
figure;
bar(binCenters, radialDensity, 'hist');
xlabel('Radial Distance from Center');
ylabel('Proportion of Points');
title('Radial Density Profile of Sampling');

% Compute Fourier Transform of the sampling mask
maskFT = fftshift(abs(fft2(samplingMask)));

% Normalize the Fourier Transform for visualization
maskFT = maskFT / max(maskFT(:));

% Plot the Fourier Transform
figure;
imagesc(maskFT);
colormap('hot');
colorbar;
axis image;
title('Fourier Transform of Sampling Mask');
xlabel('kx');
ylabel('ky');

% Overlay Density Profile with Theoretical Distribution

% Calculate radial distances for all points
[gridX, gridY] = ndgrid(1:gridSize(1), 1:gridSize(2));
distancesAll = sqrt((gridX(:) - center(1)).^2 + (gridY(:) - center(2)).^2);

% Calculate theoretical distribution
theoreticalDensity = exp(-biasFactor * distancesAll / max(distancesAll));
theoreticalDensity = theoreticalDensity / sum(theoreticalDensity); % Normalize

% Create histogram for sampled points
[histSampled, edges] = histcounts(distances, 'Normalization', 'probability');
binCenters = edges(1:end-1) + diff(edges) / 2;

% Create histogram for theoretical distribution
[histTheoretical, ~] = histcounts(distancesAll, edges, 'Normalization', 'probability');

% Plot comparison
figure;
hold on;
bar(binCenters, histSampled, 'FaceAlpha', 0.5, 'DisplayName', 'Sampled Points');
plot(binCenters, histTheoretical, '-r', 'LineWidth', 2, 'DisplayName', 'Theoretical Distribution');
xlabel('Distance from Center');
ylabel('Proportion');
legend;
title('Sampled vs. Theoretical Distribution');
hold off;

% Define central and peripheral regions
centralRadiusThreshold = gridSize(1) / 4; % Adjust this threshold as needed
isCentral = distances <= centralRadiusThreshold;
isPeripheral = distances > centralRadiusThreshold;

% Count points
numCentralPoints = sum(isCentral);
numPeripheralPoints = sum(isPeripheral);

% Display proportions
disp(['Total Points in Central Region: ', num2str(numCentralPoints)]);
disp(['Total Points in Peripheral Region: ', num2str(numPeripheralPoints)]);
disp(['Proportion Central: ', num2str(numCentralPoints / totalSampledPoints)]);
disp(['Proportion Peripheral: ', num2str(numPeripheralPoints / totalSampledPoints)]);


%% Evaluation Metrics for T1 and T2 Maps

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

% --- T1 Metrics ---
% Mean
T1_fully_mean = mean(T1_fully_masked);
T1_under_mean = mean(T1_under_masked);

% Standard Deviation
T1_fully_std = std(T1_fully_masked);
T1_under_std = std(T1_under_masked);

% Range
T1_fully_range = [min(T1_fully_masked), max(T1_fully_masked)];
T1_under_range = [min(T1_under_masked), max(T1_under_masked)];

% RMSE
T1_RMSE = sqrt(mean((T1_fully_masked - T1_under_masked).^2));

% --- T2 Metrics ---
% Mean
T2_fully_mean = mean(T2_fully_masked);
T2_under_mean = mean(T2_under_masked);

% Standard Deviation
T2_fully_std = std(T2_fully_masked);
T2_under_std = std(T2_under_masked);

% Range
T2_fully_range = [min(T2_fully_masked), max(T2_fully_masked)];
T2_under_range = [min(T2_under_masked), max(T2_under_masked)];

% RMSE
T2_RMSE = sqrt(mean((T2_fully_masked - T2_under_masked).^2));

% Display Metrics
disp('--- T1 Metrics ---');
disp(['Fully Sampled - Mean: ', num2str(T1_fully_mean), ...
      ', Std: ', num2str(T1_fully_std), ...
      ', Range: [', num2str(T1_fully_range(1)), ', ', num2str(T1_fully_range(2)), ']']);
disp(['Undersampled - Mean: ', num2str(T1_under_mean), ...
      ', Std: ', num2str(T1_under_std), ...
      ', Range: [', num2str(T1_under_range(1)), ', ', num2str(T1_under_range(2)), ']']);
disp(['RMSE for T1 Maps: ', num2str(T1_RMSE)]);

disp('--- T2 Metrics ---');
disp(['Fully Sampled - Mean: ', num2str(T2_fully_mean), ...
      ', Std: ', num2str(T2_fully_std), ...
      ', Range: [', num2str(T2_fully_range(1)), ', ', num2str(T2_fully_range(2)), ']']);
disp(['Undersampled - Mean: ', num2str(T2_under_mean), ...
      ', Std: ', num2str(T2_under_std), ...
      ', Range: [', num2str(T2_under_range(1)), ', ', num2str(T2_under_range(2)), ']']);
disp(['RMSE for T2 Maps: ', num2str(T2_RMSE)]);

% Assuming imgs (fully sampled) and undersampled_imgs (undersampled) are available

% Define center voxel
centerVoxel = [size(imgs, 1) / 2, size(imgs, 2) / 2];

% Extract signal magnitudes at the center voxel
fullySampledSignal = abs(squeeze(imgs(centerVoxel(1), centerVoxel(2), :)));
undersampledSignal = abs(squeeze(undersampled_imgs(centerVoxel(1), centerVoxel(2), :)));

% Plot comparison
figure;
plot(fullySampledSignal, '-b', 'LineWidth', 1.5, 'DisplayName', 'Fully Sampled');
hold on;
plot(undersampledSignal, '--r', 'LineWidth', 1.5, 'DisplayName', 'Undersampled');
legend('Location', 'best');
xlabel('Time Frame');
ylabel('Signal Magnitude');
title('Signal Magnitude Comparison at Center Voxel');
grid on;
