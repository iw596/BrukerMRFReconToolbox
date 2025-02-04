%% Step 1: Load Sampling Masks
% Ensure 'samplingMasks' is loaded in your workspace
% samplingMasks should have dimensions [128, 128, numTimePoints]
gridSize = [128, 128];
numTimePoints = size(samplingMasks, 3);
centralCoverage = 0.15; % 15% central coverage
accelerationFactor = 8;

%% Step 2: Define Central and Peripheral Regions
totalPoints = prod(gridSize);
centralPoints = round(totalPoints * centralCoverage); % Expected central points
peripheralPoints = round(totalPoints / accelerationFactor) - centralPoints; % Expected peripheral points

% Determine central region size
centralSize = round(sqrt(centralPoints));
centralHalf = floor(centralSize / 2);
centerX = floor(gridSize(1) / 2);
centerY = floor(gridSize(2) / 2);

% Create a mask for the central region
centralMask = false(gridSize);
for x = (centerX - centralHalf):(centerX + centralHalf)
    for y = (centerY - centralHalf):(centerY + centralHalf)
        centralMask(x, y) = true;
    end
end

%% Step 3: Analyze Central and Peripheral Sampling
centralCounts = zeros(1, numTimePoints);
peripheralCounts = zeros(1, numTimePoints);

for t = 1:numTimePoints
    currentMask = samplingMasks(:, :, t);
    centralCounts(t) = sum(currentMask(centralMask));
    peripheralCounts(t) = sum(currentMask(~centralMask));
end

% Calculate the average and standard deviation of sampled points
avgCentralPoints = mean(centralCounts);
stdCentralPoints = std(centralCounts);
avgPeripheralPoints = mean(peripheralCounts);
stdPeripheralPoints = std(peripheralCounts);

% Display results
fprintf('Expected Central Points: %d\n', centralPoints);
fprintf('Average Central Points: %.2f (± %.2f)\n', avgCentralPoints, stdCentralPoints);

fprintf('Expected Peripheral Points: %d\n', peripheralPoints);
fprintf('Average Peripheral Points: %.2f (± %.2f)\n', avgPeripheralPoints, stdPeripheralPoints);

%% Step 4: Visualize Peripheral Point Density
peripheralDensity = zeros(gridSize);

for t = 1:numTimePoints
    currentMask = samplingMasks(:, :, t);
    peripheralDensity = peripheralDensity + currentMask .* ~centralMask;
end

% Normalize density map
peripheralDensity = peripheralDensity / numTimePoints;

% Display peripheral density heatmap
figure;
imagesc(peripheralDensity);
colormap('hot');
colorbar;
title('Peripheral Sampling Density Heatmap');
axis image;

%% Step 5: Validate Temporal Randomness of Peripheral Sampling
overlapMatrix = zeros(numTimePoints, numTimePoints);

for t1 = 1:numTimePoints
    for t2 = t1:numTimePoints
        overlap = nnz(samplingMasks(:, :, t1) & samplingMasks(:, :, t2) & ~centralMask);
        overlapMatrix(t1, t2) = overlap;
        overlapMatrix(t2, t1) = overlap; % Symmetry
    end
end

% Visualize overlap matrix
figure;
imagesc(overlapMatrix);
colormap('jet');
colorbar;
title('Overlap of Peripheral Sampling Across Time Points');
xlabel('Time Point 1');
ylabel('Time Point 2');
axis square;
