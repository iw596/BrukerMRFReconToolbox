function samplingMasks = optimizedPoissonDiskSampling14(matrixSize, targetPoints, numTimePoints, centralBiasFactor)
    samplingMasks = zeros([matrixSize, numTimePoints]); % 3D array to store masks for all time points
    
    for t = 1:numTimePoints
        % Create pseudorandom Poisson-disc sampling with central bias
        center = matrixSize / 2;
        maxDistance = sqrt((center(1))^2 + (center(2))^2);
        
        % Generate weights for central bias
        [X, Y] = ndgrid(1:matrixSize(1), 1:matrixSize(2));
        distances = sqrt((X - center(1)).^2 + (Y - center(2)).^2);
        weights = exp(-centralBiasFactor * distances / maxDistance);
        
        % Normalize weights
        probabilities = weights(:) / sum(weights(:));
        
        % Random sampling based on probabilities
        cumulativeProbs = cumsum(probabilities);
        sampledIndices = zeros(targetPoints, 1);
        
        for i = 1:targetPoints
            randomValue = rand * cumulativeProbs(end);
            sampledIndices(i) = find(cumulativeProbs >= randomValue, 1);
        end
        
        % Generate mask for this time point
        mask = zeros(matrixSize);
        mask(sampledIndices) = 1;
        samplingMasks(:, :, t) = mask;
    end
    
    disp(['Generated sampling masks for ', num2str(numTimePoints), ' time points.']);
end
