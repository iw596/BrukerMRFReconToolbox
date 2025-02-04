function samplingMasks = generateDynamicPoissonDiscPatterns(matrixSize, undersamplingRate, numTimePoints)
    % Generate different Poisson-disc patterns for each time point
    % matrixSize: [Nx, Ny] size of the k-space grid
    % undersamplingRate: Target undersampling factor
    % numTimePoints: Number of time points in the MRF signal train

    samplingMasks = zeros([matrixSize, numTimePoints]); % Initialize the 3D sampling mask array
    targetPoints = round(prod(matrixSize) / undersamplingRate); % Calculate target points per time point

    for t = 1:numTimePoints
        % Generate Poisson-disc pattern for each time point
        samplingMasks(:, :, t) = generatePoissonDiscPattern(matrixSize, targetPoints);
    end
end

function mask = generatePoissonDiscPattern(matrixSize, targetPoints)
    % Generate a single Poisson-disc pattern
    % matrixSize: [Nx, Ny] size of the k-space grid
    % targetPoints: Number of points to sample
    Nx = matrixSize(1);
    Ny = matrixSize(2);
    mask = zeros(Nx, Ny);
    
    % Poisson-disc logic
    center = [Nx / 2, Ny / 2];
    radius = sqrt(prod(matrixSize) / targetPoints); % Dynamic radius based on grid and target points
    sampledPoints = [];
    
    while size(sampledPoints, 1) < targetPoints
        candidate = randi([1, Nx; 1, Ny], [1, 2]); % Random candidate
        distances = sqrt(sum((sampledPoints - candidate).^2, 2));
        if isempty(distances) || all(distances >= radius)
            sampledPoints = [sampledPoints; candidate];
            mask(candidate(1), candidate(2)) = 1;
        end
    end
end
