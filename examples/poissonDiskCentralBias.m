function mask = poissonDiskCentralBias(gridSize, undersamplingFactor, maxRadius, biasFactor)
    % Inputs:
    % gridSize: size of k-space grid [Nx, Ny]
    % undersamplingFactor: determines the target sampling percentage
    % maxRadius: maximum spacing between points
    % biasFactor: controls the central bias (smaller = stronger central weighting)
    
    % Initialize parameters
    totalPoints = round(prod(gridSize) / undersamplingFactor);
    center = gridSize / 2;
    mask = zeros(gridSize);
    sampledPoints = [];

    % Generate candidate grid points
    [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
    gridPoints = [X(:), Y(:)];

    % Define a density weighting function (Gaussian decay)
    distances = sqrt((X - center(1)).^2 + (Y - center(2)).^2);
    densityWeights = exp(-biasFactor * (distances / max(gridSize)).^2);
    densityWeights = densityWeights / max(densityWeights(:)); % Normalize weights
    
    while size(sampledPoints, 1) < totalPoints
        % Randomly select a candidate point weighted by density
        probabilities = densityWeights(:) .* (mask(:) == 0); % Exclude already sampled points
        probabilities = probabilities / sum(probabilities); % Normalize probabilities
        
        % Sample a point based on probabilities
        cumulativeProbs = cumsum(probabilities);
randomValue = rand * cumulativeProbs(end);
candidateIdx = find(cumulativeProbs >= randomValue, 1);

        candidate = gridPoints(candidateIdx, :);
        
        % Check minimum radius constraint
        if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= maxRadius)
            sampledPoints = [sampledPoints; candidate];
            mask(candidate(1), candidate(2)) = 1;
        end
    end
    
    % Display sampled points
    disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
    imagesc(mask); colormap('gray'); axis image;
    title('Central Bias Poisson Disk Sampling Pattern');
end
