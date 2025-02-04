% function mask = poissonDiskMask(gridSize, undersamplingFactor, radius)
%     totalPoints = round(prod(gridSize) / undersamplingFactor); 
%     mask = zeros(gridSize); 
%     sampledPoints = []; % Initializes an empty list to keep track of sampled points
% 
%     while numel(sampledPoints) < totalPoints
%         candidate = [randi(gridSize(1)), randi(gridSize(2))];
%         if all(vecnorm(bsxfun(@minus, sampledPoints, candidate), 2, 2) >= radius, 'all')
%             sampledPoints = [sampledPoints; candidate];
%             mask(candidate(1), candidate(2)) = 1; % Mark as sampled
%         end
%     end
% end
% function mask = poissonDiskMask(gridSize, undersamplingFactor, radius)
%     % Calculate the total number of points to sample
%     totalPoints = round(prod(gridSize) / undersamplingFactor);
% 
%     % Initialize the binary mask and sampled points
%     mask = zeros(gridSize);
%     sampledPoints = [];
% 
%     % Loop until the desired number of points is sampled
%     while size(sampledPoints, 1) < totalPoints
%         % Generate a random candidate point
%         candidate = [randi(gridSize(1)), randi(gridSize(2))];
% 
%         % If no points have been sampled yet, accept the first candidate
%         if isempty(sampledPoints)
%             sampledPoints = candidate;
%             mask(candidate(1), candidate(2)) = 1;
%             continue;
%         end
% 
%         % Compute distances to all previously sampled points
%         distances = vecnorm(sampledPoints - candidate, 2, 2);
% 
%         % Check if the candidate is sufficiently far from all sampled points
%         if all(distances >= radius)
%             sampledPoints = [sampledPoints; candidate];
%             mask(candidate(1), candidate(2)) = 1; % Mark the candidate as sampled
%         end
%     end
% end

% function mask = poissonDiskMask(gridSize, undersamplingFactor, radius)
%     totalPoints = round(prod(gridSize) / undersamplingFactor); 
%     mask = zeros(gridSize);
%     sampledPoints = [];
% 
%     % Pre-compute grid indices for candidate generation
%     [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
%     gridPoints = [X(:), Y(:)];
% 
%     while size(sampledPoints, 1) < totalPoints
%         candidateIdx = randi(size(gridPoints, 1));
%         candidate = gridPoints(candidateIdx, :);
% 
%         % Remove the candidate point from the gridPoints to avoid re-selection
%         gridPoints(candidateIdx, :) = [];
% 
%         if isempty(sampledPoints)
%             sampledPoints = candidate;
%             mask(candidate(1), candidate(2)) = 1;
%             continue;
%         end
% 
%         distances = vecnorm(sampledPoints - candidate, 2, 2);
%         if all(distances >= radius)
%             sampledPoints = [sampledPoints; candidate];
%             mask(candidate(1), candidate(2)) = 1;
%         end
%     end
% end

% function mask = poissonDiskMask(gridSize, undersamplingFactor, radius)
%     totalPoints = round(prod(gridSize) / undersamplingFactor); 
%     mask = zeros(gridSize);
%     sampledPoints = [];
% 
%     % Pre-compute grid indices for candidate generation
%     [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
%     gridPoints = [X(:), Y(:)];
% 
%     while size(sampledPoints, 1) < totalPoints
%         % Check if there are any points left in gridPoints
%         % if isempty(gridPoints)
%         %     warning('Not enough valid points to satisfy undersampling requirements. Reducing totalPoints.');
%         %     break;
%         % end
% 
%         % Randomly select a candidate point
%         candidateIdx = randi(size(gridPoints, 1));
%         candidate = gridPoints(candidateIdx, :);
% 
%         % Remove the candidate from gridPoints
%         gridPoints(candidateIdx, :) = [];
% 
%         % Add the first candidate automatically
%         if isempty(sampledPoints)
%             sampledPoints = candidate;
%             mask(candidate(1), candidate(2)) = 1;
%             continue;
%         end
% 
%         % Calculate distances to existing points
%         distances = vecnorm(sampledPoints - candidate, 2, 2);
%         if all(distances >= radius)
%             sampledPoints = [sampledPoints; candidate];
%             mask(candidate(1), candidate(2)) = 1;
%         end
%     end
% 
%     % Display the actual number of points sampled
%     disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
% end
% 
% function mask = poissonDiskMask(gridSize, undersamplingFactor, radius)
%     % Initialize parameters
%     totalPoints = round(prod(gridSize) / undersamplingFactor); 
%     mask = zeros(gridSize);
%     sampledPoints = [];
% 
%     % Pre-compute grid indices for candidate generation
%     [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
%     gridPoints = [X(:), Y(:)];
% 
%     % Sampling loop
%     while size(sampledPoints, 1) < totalPoints
%         % Check if gridPoints is exhausted
%         if isempty(gridPoints)
%             warning('Grid points exhausted. Falling back to random sampling.');
%             remainingPoints = totalPoints - size(sampledPoints, 1);
% 
%             % Add remaining points randomly
%             [rows, cols] = find(~mask);
%             randomIndices = randperm(length(rows), min(remainingPoints, length(rows)));
%             for idx = randomIndices
%                 mask(rows(idx), cols(idx)) = 1;
%                 sampledPoints = [sampledPoints; rows(idx), cols(idx)];
%             end
%             break; % Exit the loop after fallback
%         end
% 
%         % Randomly select a candidate point
%         candidateIdx = randi(size(gridPoints, 1));
%         candidate = gridPoints(candidateIdx, :);
% 
%         % Remove the candidate from gridPoints
%         gridPoints(candidateIdx, :) = [];
% 
%         % Add the first candidate automatically
%         if isempty(sampledPoints)
%             sampledPoints = candidate;
%             mask(candidate(1), candidate(2)) = 1;
%             continue;
%         end
% 
%         % Calculate distances to existing points
%         distances = vecnorm(sampledPoints - candidate, 2, 2);
%         if all(distances >= radius)
%             sampledPoints = [sampledPoints; candidate];
%             mask(candidate(1), candidate(2)) = 1;
%         end
%     end
% 
%     % Display the actual number of points sampled
%     disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
% end

function mask = poissonDiskMask(gridSize, undersamplingFactor, radius)
    % Initialize parameters
    totalPoints = round(prod(gridSize) / undersamplingFactor); 
    mask = zeros(gridSize);
    sampledPoints = [];

    % Pre-compute grid indices for candidate generation
    [X, Y] = ndgrid(1:gridSize(1), 1:gridSize(2));
    gridPoints = [X(:), Y(:)];

    % Sampling loop
    while size(sampledPoints, 1) < totalPoints
        % Check if gridPoints is exhausted
        if isempty(gridPoints)
            disp('Grid points exhausted. Reducing the number of requested points dynamically.');
            totalPoints = size(sampledPoints, 1); % Adjust target to the number of sampled points
            break; % Exit the loop gracefully
        end

        % Randomly select a candidate point
        candidateIdx = randi(size(gridPoints, 1));
        candidate = gridPoints(candidateIdx, :);

        % Remove the candidate from gridPoints
        gridPoints(candidateIdx, :) = [];

        % Add the first candidate automatically
        if isempty(sampledPoints)
            sampledPoints = candidate;
            mask(candidate(1), candidate(2)) = 1;
            continue;
        end

        % Calculate distances to existing points
        distances = vecnorm(sampledPoints - candidate, 2, 2);
        if all(distances >= radius)
            sampledPoints = [sampledPoints; candidate];
            mask(candidate(1), candidate(2)) = 1;
        end
    end

    % Display the actual number of points sampled
    disp(['Sampled ', num2str(size(sampledPoints, 1)), ' points out of requested ', num2str(totalPoints)]);
end
