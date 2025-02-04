function samplingMask = generateDynamicPoissonDiscPatterns15(gridSize, undersamplingRate, centralBiasFactor, numTimePoints)
    % Initialize parameters
    samplingMask = zeros(gridSize(1), gridSize(2), numTimePoints);
    
    for t = 1:numTimePoints
        % Compute the radial weights for central bias
        [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
        center = gridSize / 2;
        distances = sqrt((X - center(1)).^2 + (Y - center(2)).^2);
        centralWeights = exp(-centralBiasFactor * distances / max(distances(:)));
        
        % Normalize weights to probabilities
        probabilities = centralWeights / sum(centralWeights(:));
        
        % Generate points based on undersampling rate
        totalPoints = round(prod(gridSize) / undersamplingRate);
        sampledIndices = randsample(numel(probabilities), totalPoints, true, probabilities);
        
        % Create the sampling mask for this time point
        mask = zeros(gridSize);
        mask(sampledIndices) = 1;
        samplingMask(:, :, t) = mask;
    end
end
