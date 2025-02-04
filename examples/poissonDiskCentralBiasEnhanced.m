function [samplingMask, matchingMask] = poissonDiskCentralBiasDynamic(gridSize, undersamplingFactor, initialRadius, biasFactor, maxIterations)
    % Initialize parameters
    totalPoints = round(prod(gridSize) / undersamplingFactor);
    samplingMask = zeros(gridSize);
    matchingMask = zeros(gridSize);
    sampledPoints = [];

    % Initialize grid points
    [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
    gridPoints = [X(:), Y(:)];

    % Compute Gaussian density weights for central bias
    center = round(gridSize / 2);
    distances = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
    densityWeights = exp(-biasFactor * (distances / max(distances)).^2);

    % Normalize probabilities
    probabilities = densityWeights / sum(densityWeights);

    % Sampling process
    radius = initialRadius; % Start with the initial radius
    iteration = 0;
    while size(sampledPoints, 1) < totalPoints && iteration < maxIterations
        % Select a candidate point based on probabilities
        randomValue = rand * sum(probabilities);
        candidateIdx = find(cumsum(probabilities) >= randomValue, 1);
        candidate = gridPoints(candidateIdx, :);

        % Check distance constraint
        if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
            sampledPoints = [sampledPoints; candidate];
            samplingMask(candidate(1), candidate(2)) = 1;
        end

        % Remove candidate and update probabilities
        gridPoints(candidateIdx, :) = [];
        probabilities(candidateIdx) = [];
        probabilities = probabilities / sum(probabilities);

        % Gradually reduce the radius to allow more points
        radius = max(1, radius * 0.95);

        iteration = iteration + 1;
    end

    % Fallback: Random sampling for remaining points if undersampling is too high
    if size(sampledPoints, 1) < totalPoints
        remainingPoints = totalPoints - size(sampledPoints, 1);
        randomIndices = randperm(size(gridPoints, 1), remainingPoints);
        additionalPoints = gridPoints(randomIndices, :);
        sampledPoints = [sampledPoints; additionalPoints];
        for i = 1:size(additionalPoints, 1)
            samplingMask(additionalPoints(i, 1), additionalPoints(i, 2)) = 1;
        end
    end

    % Create matching mask (circular)
    maxDistance = max(distances);
    matchingMask(distances <= maxDistance / 2) = 1;

    % Display results
    disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
    figure;
    subplot(1, 2, 1); imagesc(samplingMask); axis image; colorbar; title('Sampling Mask');
    subplot(1, 2, 2); imagesc(matchingMask); axis image; colorbar; title('Matching Mask');
end

