% function mask = poissonDiskCentralBias2(gridSize, undersamplingFactor, radius, biasFactor)
%     % Total target points
%     totalPoints = round(prod(gridSize) / undersamplingFactor);
%     mask = zeros(gridSize);
%     sampledPoints = [];
% 
%     % Initialize grid points
%     [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
%     gridPoints = [X(:), Y(:)];
% 
%     % Compute distance weights for central bias
%     center = round(gridSize / 2);
%     distances = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
%     densityWeights = exp(-biasFactor * distances / max(distances)); % Exponential weighting
% 
%     % Debug: Visualize Density Weights
%     densityMap = reshape(densityWeights, gridSize);
%     figure; imagesc(densityMap); axis image;
%     colorbar; title('Density Weights Visualization');
% 
%     % Normalize probabilities
%     probabilities = densityWeights / sum(densityWeights);
% 
%     % Start Sampling
%     cumulativeProbs = cumsum(probabilities); % Initial cumulative probabilities
%     while size(sampledPoints, 1) < totalPoints && ~isempty(gridPoints)
% 
% randomValue = rand * sum(probabilities);
% candidateIdx = find(cumsum(probabilities) >= randomValue, 1);
% 
% 
%         candidate = gridPoints(candidateIdx, :);
% 
%         % Check minimum radius constraint
%         if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
%             sampledPoints = [sampledPoints; candidate];
%             mask(candidate(1), candidate(2)) = 1;
%         end
% 
%         % Remove candidate and update probabilities
%         probabilities(candidateIdx) = 0; % Set to zero
%         cumulativeProbs = cumsum(probabilities); % Update cumulative probabilities
%     end
% 
%     % Display the number of sampled points
%     disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
% end
% 

% function mask = poissonDiskCentralBias2(gridSize, undersamplingFactor, radius, biasFactor)
%     % Total target points
%     totalPoints = round(prod(gridSize) / undersamplingFactor);
%     mask = zeros(gridSize);
%     sampledPoints = [];
% 
%     % Initialize grid points
%     [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
%     gridPoints = [X(:), Y(:)];
% 
%     % Compute distance weights for central bias
%     center = round(gridSize / 2);
%     distances = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
%     densityWeights = exp(-biasFactor * distances / max(distances)); % Exponential weighting
% 
%     % Debug: Visualize Density Weights
%     densityMap = reshape(densityWeights, gridSize);
%     figure; imagesc(densityMap); axis image;
%     colorbar; title('Density Weights Visualization');
% 
%     % Normalize probabilities
%     probabilities = densityWeights / sum(densityWeights);
% 
%     % Start Sampling
%     cumulativeProbs = cumsum(probabilities); % Initial cumulative probabilities
%     while size(sampledPoints, 1) < totalPoints && ~isempty(gridPoints)
%         % Optimized weighted random sampling using histcounts
%         randomValue = rand * cumulativeProbs(end);
%         candidateIdx = find(cumulativeProbs >= randomValue, 1);
% 
%         % Validate candidateIdx
%         if isempty(candidateIdx) || candidateIdx < 1 || candidateIdx > size(gridPoints, 1)
%             warning('Invalid candidateIdx detected, skipping...');
%             continue;
%         end
% 
%         candidate = gridPoints(candidateIdx, :);
% 
%         % Check minimum radius constraint
%         if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
%             sampledPoints = [sampledPoints; candidate];
%             mask(candidate(1), candidate(2)) = 1;
%         end
% 
%         % Remove candidate and update probabilities
%         probabilities(candidateIdx) = 0; % Set probability to zero
%         cumulativeProbs = cumsum(probabilities); % Update cumulative probabilities
%         gridPoints(candidateIdx, :) = []; % Remove candidate from grid points
%     end
% 
%     % Display the number of sampled points
%     disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
% end

% function mask = poissonDiskCentralBias2(gridSize, undersamplingFactor, radius, biasFactor)
%     % Total target points
%     totalPoints = round(prod(gridSize) / undersamplingFactor);
%     mask = zeros(gridSize);
%     sampledPoints = [];
% 
%     % Initialize grid points
%     [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
%     gridPoints = [X(:), Y(:)];
% 
%     % Compute distance weights for central bias
%     center = round(gridSize / 2);
%     distances = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
%     densityWeights = exp(-biasFactor * distances / max(distances)); % Exponential weighting
% 
%     % Debug: Visualize Density Weights
%     densityMap = reshape(densityWeights, gridSize);
%     figure; imagesc(densityMap); axis image;
%     colorbar; title('Density Weights Visualization');
% 
%     % Normalize probabilities
%     probabilities = densityWeights / sum(densityWeights);
% 
%     % Start Sampling
%     cumulativeProbs = cumsum(probabilities); % Initial cumulative probabilities
%     while size(sampledPoints, 1) < totalPoints && ~isempty(gridPoints)
%         % Sample a point based on probabilities
%         randomValue = rand * cumulativeProbs(end);
%         candidateIdx = find(cumulativeProbs >= randomValue, 1);
% 
%         % Fallback mechanism for invalid indices
%         if isempty(candidateIdx) || candidateIdx < 1 || candidateIdx > size(gridPoints, 1)
%             % Find the highest remaining probability as a fallback
%             [~, candidateIdx] = max(probabilities);
%             if candidateIdx == 0 % If all probabilities are zero, break
%                 warning('All probabilities zero. Stopping sampling.');
%                 break;
%             end
%         end
% 
%         candidate = gridPoints(candidateIdx, :);
% 
%         % Check minimum radius constraint
%         if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
%             sampledPoints = [sampledPoints; candidate];
%             mask(candidate(1), candidate(2)) = 1;
%         end
% 
%         % Remove candidate and update probabilities
%         probabilities(candidateIdx) = 0; % Set probability to zero
%         cumulativeProbs = cumsum(probabilities); % Update cumulative probabilities
%         gridPoints(candidateIdx, :) = []; % Remove candidate from grid points
%     end
% 
%     % Display the number of sampled points
%     disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
% end

function mask = poissonDiskCentralBias2(gridSize, undersamplingFactor, radius, biasFactor)
    % Total target points
    totalPoints = round(prod(gridSize) / undersamplingFactor);
    mask = zeros(gridSize);
    sampledPoints = [];

    % Initialize grid points
    [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
    gridPoints = [X(:), Y(:)];

    % Compute distance weights for central bias
    center = round(gridSize / 2);
    distances = sqrt((gridPoints(:, 1) - center(1)).^2 + (gridPoints(:, 2) - center(2)).^2);
    densityWeights = exp(-biasFactor * distances / max(distances)); % Exponential weighting

    % Debug: Visualize Density Weights
    densityMap = reshape(densityWeights, gridSize);
    figure; imagesc(densityMap); axis image;
    colorbar; title('Density Weights Visualization');

    % Normalize probabilities
    probabilities = densityWeights / sum(densityWeights);

    % Start Sampling
    while size(sampledPoints, 1) < totalPoints && ~isempty(gridPoints)
        % Sample a point based on probabilities
        randomValue = rand * sum(probabilities);
        candidateIdx = find(cumsum(probabilities) >= randomValue, 1);

        % Fallback mechanism for invalid indices
        if isempty(candidateIdx) || candidateIdx > size(gridPoints, 1)
            warning('Invalid candidateIdx detected, skipping...');
            continue;
        end

        candidate = gridPoints(candidateIdx, :);

        % Check minimum radius constraint
        if isempty(sampledPoints) || all(vecnorm(sampledPoints - candidate, 2, 2) >= radius)
            sampledPoints = [sampledPoints; candidate];
            mask(candidate(1), candidate(2)) = 1;
        end

        % Remove candidate and update probabilities
        gridPoints(candidateIdx, :) = []; % Remove candidate from grid points
        probabilities(candidateIdx) = []; % Remove corresponding probability
        probabilities = probabilities / sum(probabilities); % Re-normalize probabilities
    end

    % Display the number of sampled points
    disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
end
