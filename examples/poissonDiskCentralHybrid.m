% function mask = poissonDiskCentralHybrid(gridSize, centralRadius, peripheralRadius, centralFactor, peripheralFactor, biasFactor)
%     % Initialize Masks
%     centralMask = zeros(gridSize);
%     peripheralMask = zeros(gridSize);
% 
%     % Central Region Sampling
%     center = round(gridSize / 2);
%     [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
%     distances = sqrt((X - center(1)).^2 + (Y - center(2)).^2);
%     centralRegion = distances <= (gridSize(1) * centralFactor);
% 
%     % Apply Poisson Disk Sampling in the Central Region
%     centralMask(centralRegion) = poissonDiskSampling(gridSize, centralRadius, biasFactor, centralRegion);
% 
%     % Peripheral Region Sampling
%     peripheralRegion = distances > (gridSize(1) * centralFactor);
%     peripheralMask(peripheralRegion) = poissonDiskSampling(gridSize, peripheralRadius, biasFactor, peripheralRegion);
% 
%     % Combine Masks
%     mask = max(centralMask, peripheralMask);
% 
%     % Display the Results
%     figure;
%     imagesc(mask);
%     axis image;
%     colormap('gray');
%     title('Combined Poisson Disk Sampling Mask with Central Density');
% end
% 
% function regionMask = poissonDiskSampling(gridSize, radius, biasFactor, region)
%     % Poisson Disk Sampling within a Specified Region
%     regionMask = zeros(gridSize);
%     [X, Y] = find(region); % Extract valid points within the region
%     sampledPoints = [];
%     probabilities = exp(-biasFactor * sqrt((X - gridSize(1) / 2).^2 + (Y - gridSize(2) / 2).^2));
%     probabilities = probabilities / sum(probabilities);
% 
%     % Sample Points
%     while numel(sampledPoints) < numel(probabilities)
%         candidateIdx = randsample(length(X), 1, true, probabilities);
%         candidate = [X(candidateIdx), Y(candidateIdx)];
% 
%         % Check Distance Constraint
%         if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
%             sampledPoints = [sampledPoints; candidate];
%             regionMask(candidate(1), candidate(2)) = 1;
%         end
% 
%         % Remove Selected Point
%         probabilities(candidateIdx) = 0;
%         probabilities = probabilities / sum(probabilities);
%     end
% end
% function mask = poissonDiskCentralHybrid(gridSize, centralRadius, peripheralRadius, centralFactor, peripheralFactor, biasFactor)
%     % Initialize Masks
%     centralMask = zeros(gridSize);
%     peripheralMask = zeros(gridSize);
% 
%     % Central Region Sampling
%     center = round(gridSize / 2);
%     [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
%     distances = sqrt((X - center(1)).^2 + (Y - center(2)).^2);
%     centralRegion = distances <= (gridSize(1) * centralFactor);
% 
%     % Apply Poisson Disk Sampling in the Central Region
%     centralMask(centralRegion) = poissonDiskSampling(gridSize, centralRadius, biasFactor, centralRegion);
% 
%     % Peripheral Region Sampling
%     peripheralRegion = distances > (gridSize(1) * centralFactor);
%     peripheralMask(peripheralRegion) = poissonDiskSampling(gridSize, peripheralRadius, biasFactor, peripheralRegion);
% 
%     % Combine Masks
%     mask = max(centralMask, peripheralMask);
% 
%     % Display the Results
%     figure;
%     imagesc(mask);
%     axis image;
%     colormap('gray');
%     title('Combined Poisson Disk Sampling Mask with Central Density');
% end
% 
% function regionMask = poissonDiskSampling(gridSize, radius, biasFactor, region)
%     % Poisson Disk Sampling within a Specified Region
%     regionMask = zeros(gridSize);
%     [X, Y] = find(region); % Extract valid points within the region
%     sampledPoints = [];
%     probabilities = exp(-biasFactor * sqrt((X - gridSize(1) / 2).^2 + (Y - gridSize(2) / 2).^2));
%     probabilities = probabilities / sum(probabilities);
% 
%     % Sample Points
%     while numel(sampledPoints) < numel(probabilities)
%         % Custom weighted sampling
%         cumulativeProbs = cumsum(probabilities);
%         randomValue = rand * cumulativeProbs(end);
%         candidateIdx = find(cumulativeProbs >= randomValue, 1);
%         candidate = [X(candidateIdx), Y(candidateIdx)];
% 
%         % Check Distance Constraint
%         if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
%             sampledPoints = [sampledPoints; candidate];
%             regionMask(candidate(1), candidate(2)) = 1;
%         end
% 
%         % Remove Selected Point
%         probabilities(candidateIdx) = 0;
%         probabilities = probabilities / sum(probabilities);
%     end
% end
% function mask = poissonDiskCentralHybrid(gridSize, centralRadius, peripheralRadius, centralFactor, peripheralFactor, biasFactor)
%     % Initialize Masks
%     centralMask = zeros(gridSize);
%     peripheralMask = zeros(gridSize);
% 
%     % Central Region Sampling
%     center = round(gridSize / 2);
%     [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
%     distances = sqrt((X - center(1)).^2 + (Y - center(2)).^2);
%     centralRegion = distances <= (gridSize(1) * centralFactor);
% 
%     % Apply Poisson Disk Sampling in the Central Region
%     centralMask(centralRegion) = poissonDiskSampling(gridSize, centralRadius, biasFactor, centralRegion);
% 
%     % Peripheral Region Sampling
%     peripheralRegion = distances > (gridSize(1) * centralFactor);
%     peripheralMask(peripheralRegion) = poissonDiskSampling(gridSize, peripheralRadius, biasFactor, peripheralRegion);
% 
%     % Combine Masks
%     mask = max(centralMask, peripheralMask);
% 
%     % Display the Results
%     figure;
%     imagesc(mask);
%     axis image;
%     colormap('gray');
%     title('Combined Poisson Disk Sampling Mask with Central Density');
% end
% 
% function regionMask = poissonDiskSampling(gridSize, radius, biasFactor, region)
%     % Poisson Disk Sampling within a Specified Region
%     regionMask = zeros(gridSize);
%     [X, Y] = find(region); % Extract valid points within the region
%     sampledPoints = [];
%     probabilities = exp(-biasFactor * sqrt((X - gridSize(1) / 2).^2 + (Y - gridSize(2) / 2).^2));
%     probabilities = probabilities / sum(probabilities);
% 
%     % Sample Points
%     while sum(regionMask(:)) < numel(probabilities)
%         % Custom weighted sampling
%         cumulativeProbs = cumsum(probabilities);
%         randomValue = rand * cumulativeProbs(end);
%         candidateIdx = find(cumulativeProbs >= randomValue, 1);
%         candidate = [X(candidateIdx), Y(candidateIdx)];
% 
%         % Check Distance Constraint
%         if isempty(sampledPoints)
%             % Automatically accept the first candidate
%             sampledPoints = candidate;
%             regionMask(candidate(1), candidate(2)) = 1;
%         else
%             % Compute distances to existing sampled points
%             distances = sqrt(sum((sampledPoints - candidate).^2, 2)); 
%             if all(distances >= radius)
%                 sampledPoints = [sampledPoints; candidate];
%                 regionMask(candidate(1), candidate(2)) = 1;
%             end
%         end
% 
%         % Remove Selected Point
%         probabilities(candidateIdx) = 0;
%         probabilities = probabilities / sum(probabilities);
%     end
% end
function samplingMask = poissonDiskCentralHybrid(gridSize, centralRadius, peripheralRadius, centralFactor, peripheralFactor, biasFactor)
    % Function to generate a hybrid Poisson disk sampling mask with central and peripheral bias.

    % Initialize masks
    samplingMask = zeros(gridSize);

    % Define central and peripheral regions
    center = round(gridSize / 2);
    [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
    distances = sqrt((X - center(1)).^2 + (Y - center(2)).^2);

    % Central and peripheral regions
    centralRegion = distances <= gridSize(1) / 4; % Example: central is within 1/4 of the grid size
    peripheralRegion = distances > gridSize(1) / 4;

    % Central region sampling
    disp('Sampling central region...');
    centralMask = zeros(gridSize);
    centralPoints = poissonDiskSampling(gridSize, centralRadius, centralFactor, centralRegion);
    centralMask(centralPoints(:, 1) + (centralPoints(:, 2) - 1) * gridSize(1)) = 1;

    % Peripheral region sampling
    disp('Sampling peripheral region...');
    peripheralMask = zeros(gridSize);
    peripheralPoints = poissonDiskSampling(gridSize, peripheralRadius, peripheralFactor, peripheralRegion);
    peripheralMask(peripheralPoints(:, 1) + (peripheralPoints(:, 2) - 1) * gridSize(1)) = 1;

    % Combine masks
    samplingMask = max(centralMask, peripheralMask);

    % Display final sampling summary
    disp(['Total sampled points: ', num2str(nnz(samplingMask))]);
end

function sampledPoints = poissonDiskSampling(gridSize, radius, biasFactor, validRegion)
    % Subfunction for Poisson disk sampling with central density bias.

    % Initialize variables
    sampledPoints = [];
    [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
    gridPoints = [X(validRegion), Y(validRegion)];

    % Compute density weights (bias towards center)
    center = round(gridSize / 2);
    distances = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
    densityWeights = exp(-biasFactor * distances / max(distances));
    probabilities = densityWeights / sum(densityWeights);

    while size(sampledPoints, 1) < round(nnz(validRegion) / 2) && ~isempty(gridPoints)
        % Sample a candidate point
        cumulativeProbs = cumsum(probabilities);
        randomValue = rand * cumulativeProbs(end);
        candidateIdx = find(cumulativeProbs >= randomValue, 1);
        candidate = gridPoints(candidateIdx, :);

        % Check minimum radius constraint
        if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
            sampledPoints = [sampledPoints; candidate];
        end

        % Remove candidate and update probabilities
        gridPoints(candidateIdx, :) = [];
        probabilities(candidateIdx) = [];
        if isempty(probabilities)
            break;
        end
        probabilities = probabilities / sum(probabilities);
    end
end

