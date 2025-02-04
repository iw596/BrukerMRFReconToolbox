function mask = variableDensityPoissonDisk(gridSize, undersamplingFactor, radius, biasFactor)
    % Initialize
    totalPoints = round(prod(gridSize) / undersamplingFactor); % Target points
    mask = zeros(gridSize); % Sampling mask
    sampledPoints = []; % List of sampled points

    % Generate k-space grid and central bias weights
    [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
    gridPoints = [X(:), Y(:)];
    center = round(gridSize / 2);
    distances = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
    densityWeights = exp(-biasFactor * distances / max(distances)); % Exponential bias
    probabilities = densityWeights / sum(densityWeights); % Normalize weights

    % Start sampling
    while size(sampledPoints, 1) < totalPoints && ~isempty(gridPoints)
        % Weighted random sampling
        randomValue = rand * sum(probabilities);
        candidateIdx = find(cumsum(probabilities) >= randomValue, 1);
        candidate = gridPoints(candidateIdx, :);

        % Check Poisson disk constraint
        if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
            sampledPoints = [sampledPoints; candidate];
            mask(candidate(1), candidate(2)) = 1;
        end

        % Remove sampled point and update probabilities
        gridPoints(candidateIdx, :) = [];
        probabilities(candidateIdx) = [];
        probabilities = probabilities / sum(probabilities); % Re-normalize
    end

    % Display results
    disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
end
