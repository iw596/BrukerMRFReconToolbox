function [samplingMask, matchingMask] = poissonDiskCentralBias3(gridSize, undersamplingFactor, radius, biasFactor)
    % Initialize parameters
    totalPoints = round(prod(gridSize) / undersamplingFactor);
    samplingMask = zeros(gridSize);
    matchingMask = zeros(gridSize);
    sampledPoints = [];
    consecutiveSkips = 0; % Track consecutive skips
    maxSkips = 50; % Maximum consecutive skips allowed before fallback

    % Initialize grid points
    [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
    gridPoints = [X(:), Y(:)];

    % Compute distance weights for central bias
    center = round(gridSize / 2);
    distances = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
    densityWeights = exp(-biasFactor * distances / max(distances)); % Exponential weighting
    probabilities = densityWeights / sum(densityWeights); % Normalize probabilities

    % Debug: Visualize Density Weights
    figure; imagesc(reshape(densityWeights, gridSize)); axis image; colorbar;
    title('Density Weights Visualization');

    % Sampling process
    while size(sampledPoints, 1) < totalPoints && ~isempty(gridPoints)
        % Sample a point based on probabilities
        cumulativeProbs = cumsum(probabilities);
        randomValue = rand * cumulativeProbs(end);
        candidateIdx = find(cumulativeProbs >= randomValue, 1);

        % Check if the candidate is valid
        if isempty(candidateIdx) || candidateIdx > size(gridPoints, 1)
            warning('Invalid candidateIdx detected, skipping iteration...');
            consecutiveSkips = consecutiveSkips + 1;
            if consecutiveSkips >= maxSkips
                warning('Too many consecutive skips, switching to fallback mode.');
                break;
            end
            continue; % Skip to the next iteration
        end

        candidate = gridPoints(candidateIdx, :);

        % Check minimum radius constraint
        if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
            sampledPoints = [sampledPoints; candidate];
            samplingMask(candidate(1), candidate(2)) = 1;
            consecutiveSkips = 0; % Reset skip counter
        else
            consecutiveSkips = consecutiveSkips + 1;
            if consecutiveSkips >= maxSkips
                warning('Too many consecutive skips, switching to fallback mode.');
                break;
            end
            continue; % Skip to the next iteration
        end

        % Remove candidate and update probabilities
        gridPoints(candidateIdx, :) = [];
        probabilities(candidateIdx) = [];
        probabilities = probabilities / sum(probabilities); % Re-normalize
    end

    % Debug: Display final results
    disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
    
    % Create a circular matching mask
    radiusMatch = round(min(gridSize) / 3); % Example matching radius
    for x = 1:gridSize(1)
        for y = 1:gridSize(2)
            if norm([x, y] - center) <= radiusMatch
                matchingMask(x, y) = 1;
            end
        end
    end

    % Debug: Visualize Sampling and Matching Masks
    figure;
    subplot(1, 2, 1); imagesc(samplingMask); axis image; colorbar; title('Sampling Mask');
    subplot(1, 2, 2); imagesc(matchingMask); axis image; colorbar; title('Matching Mask');
end
