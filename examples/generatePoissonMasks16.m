function masks = generatePoissonMasks16(gridSize, numTimePoints, accelerationFactor, centralCoverage)
    % Parameters
    totalPoints = prod(gridSize);
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

    for t = 1:numTimePoints
        % Generate Poisson Disk Sampling for outer region
        peripheralMask = zeros(gridSize);

        % Create indices for peripheral region
        [xGrid, yGrid] = meshgrid(1:gridSize(1), 1:gridSize(2));
        peripheralIndices = find((abs(xGrid - centerX) > centralHalf) | (abs(yGrid - centerY) > centralHalf));

        % DEBUG: Check values
        if isempty(peripheralIndices)
            error('Peripheral indices are empty! Check the central region calculation.');
        end
        if pointsToRetain <= 0
            warning('No points to retain in the peripheral region.');
        end

        % Select random peripheral points
        if ~isempty(peripheralIndices) && pointsToRetain > 0
            try
                selectedIndices = randperm(numel(peripheralIndices), min(pointsToRetain, numel(peripheralIndices)));
                peripheralMask(peripheralIndices(selectedIndices)) = 1;
            catch ME
                error('Error in randperm: %s\npointsToRetain: %d\nperipheralIndices: %d', ...
                      ME.message, pointsToRetain, numel(peripheralIndices));
            end
        end

        % Add central region
        centralRegionX = (centerX - centralHalf):(centerX + centralHalf);
        centralRegionY = (centerY - centralHalf):(centerY + centralHalf);
        peripheralMask(centralRegionX, centralRegionY) = 1;

        % Assign mask
        masks(:, :, t) = peripheralMask;
    end
end
