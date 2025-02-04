function [samplingMask, sampledPointsCount] = optimizedPoissonDiskSampling(gridSize, targetPoints, initialRadius, centralBiasFactor)
    % Initialize variables
    samplingMask = zeros(gridSize); % Sampling mask
    sampledPoints = []; % List of sampled points
    gridPoints = createGridPoints(gridSize); % Generate grid points

    % Central bias weighting
    center = gridSize / 2;
    distancesFromCenter = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
    centralWeights = exp(-centralBiasFactor * distancesFromCenter / max(distancesFromCenter));
    probabilities = centralWeights / sum(centralWeights); % Normalize probabilities

    % Parameters
    numSampled = 0;
    maxAttempts = 1000 * targetPoints; % Limit attempts to prevent infinite loops
    currentRadius = initialRadius; % Start radius
    radiusDecreaseFactor = 0.95; % Gradually reduce radius
    minRadius = 1; % Minimum allowable radius

    % Sampling loop
    while numSampled < targetPoints && maxAttempts > 0
        % Ensure probabilities are valid
        if isempty(probabilities) || all(probabilities == 0)
            warning('Probabilities became invalid during the process. Terminating sampling.');
            break;
        end

        % Compute cumulative probabilities
        cumulativeProbs = cumsum(probabilities);

        % Ensure cumulativeProbs is valid
        if isempty(cumulativeProbs) || cumulativeProbs(end) <= 0
            warning('Cumulative probabilities are invalid or empty. Terminating sampling.');
            break;
        end

        % Sample a candidate point
        randomValue = rand * cumulativeProbs(end);
        candidateIdx = find(cumulativeProbs >= randomValue, 1);
        candidate = gridPoints(candidateIdx, :);

        % Check minimum distance condition
        if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= currentRadius)
            % Accept the candidate
            sampledPoints = [sampledPoints; candidate];
            samplingMask(candidate(1), candidate(2)) = 1;
            numSampled = numSampled + 1;
        end

        % Remove the candidate from grid points
        gridPoints(candidateIdx, :) = [];
        probabilities(candidateIdx) = [];

        % Re-normalize probabilities and adjust radius
        if ~isempty(probabilities)
            probabilities = probabilities / sum(probabilities);
        end
        currentRadius = max(currentRadius * radiusDecreaseFactor, minRadius);

        % Update attempt counter
        maxAttempts = maxAttempts - 1;
    end

    % Output the number of sampled points
    sampledPointsCount = numSampled;
    disp(['Achieved sampled points: ', num2str(numSampled)]);
    disp(['Target points: ', num2str(targetPoints)]);

    % Display warning if not enough points were sampled
    if numSampled < targetPoints
        warning('Sampling did not reach the target number of points. Consider adjusting parameters.');
    end
end

function gridPoints = createGridPoints(gridSize)
    % Create grid points for the sampling process
    [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
    gridPoints = [X(:), Y(:)];
end
