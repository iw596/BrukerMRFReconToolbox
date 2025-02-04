function mask = generatePoissonDiscPattern(matrixSize, undersamplingRate)
    % Generate a 2D Poisson-disc sampling pattern with a specified undersampling rate

    % Total number of points in the grid
    totalPoints = prod(matrixSize);

    % Target number of sampled points based on undersampling rate
    targetPoints = round(totalPoints / undersamplingRate);

    % Initialize the sampling mask
    mask = zeros(matrixSize);

    % Generate grid points
    [X, Y] = ndgrid(1:matrixSize(1), 1:matrixSize(2));
    gridPoints = [X(:), Y(:)];

    % Central bias weighting (optional, if central density is desired)
    center = matrixSize / 2;
    distances = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
    weights = exp(-distances / max(distances)); % Exponential decay for central focus

    % Normalize weights to probabilities
    probabilities = weights / sum(weights);

    % Initialize sampled points
    sampledPoints = [];
    maxAttempts = 10 * targetPoints; % Limit attempts to prevent infinite loops

    % Sampling loop
    while size(sampledPoints, 1) < targetPoints && maxAttempts > 0
        % Randomly sample a candidate point based on probabilities
        cumulativeProbs = cumsum(probabilities);
        randomValue = rand * cumulativeProbs(end);
        candidateIdx = find(cumulativeProbs >= randomValue, 1);
        candidate = gridPoints(candidateIdx, :);

        % Minimum distance check (Poisson-disc constraint)
        if isempty(sampledPoints) || all(sqrt(sum((sampledPoints - candidate).^2, 2)) >= 3)
            % Accept the candidate point
            sampledPoints = [sampledPoints; candidate];
            mask(candidate(1), candidate(2)) = 1;
        end

        % Remove the candidate from gridPoints and update probabilities
        gridPoints(candidateIdx, :) = [];
        probabilities(candidateIdx) = [];
        probabilities = probabilities / sum(probabilities); % Re-normalize

        % Decrease attempts
        maxAttempts = maxAttempts - 1;
    end

    % Display the number of sampled points
    disp(['Generated ', num2str(size(sampledPoints, 1)), ' sampled points for target ', num2str(targetPoints)]);
end
