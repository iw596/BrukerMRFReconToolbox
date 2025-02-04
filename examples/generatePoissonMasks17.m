% function masks = generatePoissonMasks17(gridSize, numTimePoints, accelerationFactor, centralCoverage)
%     % Parameters
%     totalPoints = prod(gridSize);
%     retainedPoints = totalPoints / accelerationFactor; % Total points to retain
%     centralPoints = round(totalPoints * centralCoverage); % Central region points
% 
%     % Ensure non-negative and integer points to retain
%     pointsToRetain = max(0, round(retainedPoints - centralPoints));
% 
%     % Determine central region size (assume square)
%     centralSize = round(sqrt(centralPoints));
%     centralHalf = floor(centralSize / 2);
% 
%     % Initialize masks
%     masks = zeros([gridSize, numTimePoints]);
%     centerX = floor(gridSize(1) / 2);
%     centerY = floor(gridSize(2) / 2);
% 
%     for t = 1:numTimePoints
%         % Generate Poisson Disk Sampling for outer region
%         peripheralMask = zeros(gridSize);
% 
%         % Create indices for peripheral region
%         [xGrid, yGrid] = meshgrid(1:gridSize(1), 1:gridSize(2));
%         peripheralIndices = find((abs(xGrid - centerX) > centralHalf) | (abs(yGrid - centerY) > centralHalf));
% 
%         % DEBUG: Check values
%         if isempty(peripheralIndices)
%             error('Peripheral indices are empty! Check the central region calculation.');
%         end
%         if pointsToRetain <= 0
%             warning('No points to retain in the peripheral region.');
%         end
% 
%         % Select random peripheral points
%         if ~isempty(peripheralIndices) && pointsToRetain > 0
%             try
%                 selectedIndices = randperm(numel(peripheralIndices), min(pointsToRetain, numel(peripheralIndices)));
%                 peripheralMask(peripheralIndices(selectedIndices)) = 1;
%             catch ME
%                 error('Error in randperm: %s\npointsToRetain: %d\nperipheralIndices: %d', ...
%                       ME.message, pointsToRetain, numel(peripheralIndices));
%             end
%         end
% 
%         % Add central region
%         centralRegionX = (centerX - centralHalf):(centerX + centralHalf);
%         centralRegionY = (centerY - centralHalf):(centerY + centralHalf);
%         peripheralMask(centralRegionX, centralRegionY) = 1;
% 
%         % Assign mask
%         masks(:, :, t) = peripheralMask;
%     end
% end

function masks = generatePoissonMasks17(gridSize, numTimePoints, accelerationFactor, centralCoverage)
    % Function to generate Poisson sampling masks with central and peripheral regions

    % Parameters
    totalPoints = prod(gridSize); % Total number of points in the grid
    retainedPoints = totalPoints / accelerationFactor; % Total points to retain
    centralPoints = round(totalPoints * centralCoverage); % Central region points

    % Ensure non-negative and integer points to retain
    pointsToRetain = max(0, round(retainedPoints - centralPoints));

    % Determine central region size (assume square)
    centralSize = round(sqrt(centralPoints));
    centralHalf = floor(centralSize / 2);

    % Initialize masks
    masks = zeros([gridSize, numTimePoints]);
    centerX = floor(gridSize(1) / 2);
    centerY = floor(gridSize(2) / 2);

    % Debugging display
    disp(['Total Points: ', num2str(totalPoints)]);
    disp(['Retained Points: ', num2str(retainedPoints)]);
    disp(['Central Points: ', num2str(centralPoints)]);
    disp(['Points to Retain in Periphery: ', num2str(pointsToRetain)]);

    for t = 1:numTimePoints
        % Generate peripheral mask
        peripheralMask = zeros(gridSize);

        % Create indices for the peripheral region
        [xGrid, yGrid] = meshgrid(1:gridSize(1), 1:gridSize(2));
        peripheralIndices = find((abs(xGrid - centerX) > centralHalf) | (abs(yGrid - centerY) > centralHalf));

        % Debugging display for each time point
        disp(['Time Point: ', num2str(t)]);
        disp(['Peripheral Indices Count: ', num2str(numel(peripheralIndices))]);

        % Select random peripheral points
        if ~isempty(peripheralIndices) && pointsToRetain > 0
            try
                selectedIndices = randperm(numel(peripheralIndices), min(pointsToRetain, numel(peripheralIndices)));
                peripheralMask(peripheralIndices(selectedIndices)) = 1;
            catch ME
                error('Error in randperm: %s\npointsToRetain: %d\nperipheralIndices: %d', ...
                      ME.message, pointsToRetain, numel(peripheralIndices));
            end
        else
            warning('Peripheral indices are empty or no points to retain.');
        end

        % Add central region
        centralRegionX = max(1, (centerX - centralHalf)):min(gridSize(1), (centerX + centralHalf));
        centralRegionY = max(1, (centerY - centralHalf)):min(gridSize(2), (centerY + centralHalf));
        peripheralMask(centralRegionX, centralRegionY) = 1;

        % Assign mask
        masks(:, :, t) = peripheralMask;
    end

    % Visualize the mean sampling mask across time points
    figure;
    imagesc(mean(masks, 3)); colormap gray; colorbar;
    title('Mean Sampling Mask Across Time Points');

    % Count sampled points
    totalSampledPoints = nnz(masks(:, :, 1));
    centralSampledPoints = numel(centralRegionX) * numel(centralRegionY);
    peripheralSampledPoints = totalSampledPoints - centralSampledPoints;

    % Debugging final counts
    disp(['Total Sampled Points (First Time Point): ', num2str(totalSampledPoints)]);
    disp(['Central Sampled Points: ', num2str(centralSampledPoints)]);
    disp(['Peripheral Sampled Points: ', num2str(peripheralSampledPoints)]);
end
