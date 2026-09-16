classdef LLR < Regularizer
    %LLR Locally low-rank regularizer for MRF coefficient images.
    %
    % The input is arranged as [x y coefficients] for 2-D data or
    % [x y z coefficients] for 3-D data. Each spatial block is reshaped to
    % a matrix whose rows are voxels and whose columns are coefficients.
    % Singular-value soft-thresholding is then applied to that matrix.
    %
    % Blocks may overlap. In that case the block results are averaged. This
    % is the standard practical LLR denoiser, but it is an approximation to
    % the exact proximal operator of a sum of overlapping nuclear norms.

    properties
        BlockSize
        Stride
        Lambda = 0.01
        Description = 'Locally low-rank regularization'
    end

    methods
        function obj = LLR(blockSize, stride, lambda)
            if nargin < 1 || isempty(blockSize)
                blockSize = 8;
            end
            if nargin < 2 || isempty(stride)
                stride = blockSize;
            end
            if nargin >= 3 && ~isempty(lambda)
                obj.Lambda = double(lambda);
            end

            obj.BlockSize = validateSpatialVector(blockSize, 'blockSize');
            obj.Stride = validateSpatialVector(stride, 'stride');
        end

        function xOut = prox(obj, xIn, tau)
            %PROX Apply blockwise singular-value soft-thresholding.
            if nargin < 3 || ~isscalar(tau) || ~isfinite(tau) || tau < 0
                error('LLR:InvalidThreshold', 'prox requires a finite non-negative threshold.');
            end
            if isempty(xIn) || tau == 0
                xOut = xIn;
                return;
            end

            nSpatial = ndims(xIn) - 1;
            if nSpatial ~= 2 && nSpatial ~= 3
                error('LLR:InvalidInput', ...
                    'Expected [x y coefficients] or [x y z coefficients].');
            end

            spatialSize = size(xIn);
            spatialSize = spatialSize(1:nSpatial);
            nCoefficients = size(xIn, nSpatial + 1);
            blockSize = expandVector(obj.BlockSize, nSpatial);
            stride = expandVector(obj.Stride, nSpatial);
            blockSize = min(blockSize, spatialSize);
            stride = max(1, min(stride, blockSize));

            output = zeros(size(xIn), 'like', xIn);
            weights = zeros(spatialSize);
            starts = cell(1, nSpatial);
            for iDim = 1:nSpatial
                starts{iDim} = blockStarts(spatialSize(iDim), blockSize(iDim), stride(iDim));
            end

            for xStart = starts{1}
                xIndex = xStart:min(xStart + blockSize(1) - 1, spatialSize(1));
                for yStart = starts{2}
                    yIndex = yStart:min(yStart + blockSize(2) - 1, spatialSize(2));
                    if nSpatial == 3
                        zStarts = starts{3};
                    else
                        zStarts = 1;
                    end
                    for zStart = zStarts
                        if nSpatial == 3
                            zIndex = zStart:min(zStart + blockSize(3) - 1, spatialSize(3));
                            block = xIn(xIndex, yIndex, zIndex, :);
                        else
                            zIndex = 1;
                            block = xIn(xIndex, yIndex, :);
                        end

                        matrix = reshape(block, [], nCoefficients);
                        [left, singularValues, right] = svd(matrix, 'econ');
                        shrunk = max(diag(singularValues) - tau, 0);
                        matrixOut = left * (diag(shrunk) * right');

                        if nSpatial == 3
                            blockOut = reshape(matrixOut, [numel(xIndex), numel(yIndex), numel(zIndex), nCoefficients]);
                            output(xIndex, yIndex, zIndex, :) = output(xIndex, yIndex, zIndex, :) + blockOut;
                            weights(xIndex, yIndex, zIndex) = weights(xIndex, yIndex, zIndex) + 1;
                        else
                            blockOut = reshape(matrixOut, [numel(xIndex), numel(yIndex), nCoefficients]);
                            output(xIndex, yIndex, :) = output(xIndex, yIndex, :) + blockOut;
                            weights(xIndex, yIndex) = weights(xIndex, yIndex) + 1;
                        end
                    end
                end
            end

            weights(weights == 0) = 1;
            xOut = output ./ reshape(weights, [spatialSize 1]);
        end

        function value = evaluate(obj, xIn)
            %EVALUATE Return the sum of block nuclear norms.
            value = 0;
            nSpatial = ndims(xIn) - 1;
            spatialSize = size(xIn);
            spatialSize = spatialSize(1:nSpatial);
            blockSize = min(expandVector(obj.BlockSize, nSpatial), spatialSize);
            stride = max(1, min(expandVector(obj.Stride, nSpatial), blockSize));
            starts = cell(1, nSpatial);
            for iDim = 1:nSpatial
                starts{iDim} = blockStarts(spatialSize(iDim), blockSize(iDim), stride(iDim));
            end
            for xStart = starts{1}
                for yStart = starts{2}
                    if nSpatial == 3
                        zStarts = starts{3};
                    else
                        zStarts = 1;
                    end
                    for zStart = zStarts
                        xIndex = xStart:min(xStart + blockSize(1) - 1, spatialSize(1));
                        yIndex = yStart:min(yStart + blockSize(2) - 1, spatialSize(2));
                        if nSpatial == 3
                            zIndex = zStart:min(zStart + blockSize(3) - 1, spatialSize(3));
                            block = xIn(xIndex, yIndex, zIndex, :);
                        else
                            block = xIn(xIndex, yIndex, :);
                        end
                        value = value + sum(svd(reshape(block, [], size(xIn, nSpatial + 1)), 'econ'), 'all');
                    end
                end
            end
        end
    end
end

function vector = validateSpatialVector(value, name)
vector = double(value(:)).';
if isempty(vector) || any(~isfinite(vector)) || any(vector < 1) || any(vector ~= round(vector))
    error('LLR:InvalidSpatialParameter', '%s must contain positive integers.', name);
end
end

function vector = expandVector(value, nSpatial)
if isscalar(value)
    vector = repmat(value, 1, nSpatial);
else
    vector = [value, repmat(value(end), 1, max(0, nSpatial - numel(value)))];
    vector = vector(1:nSpatial);
end
end

function starts = blockStarts(n, blockSize, stride)
if n <= blockSize
    starts = 1;
else
    starts = 1:stride:(n - blockSize + 1);
    lastStart = n - blockSize + 1;
    if starts(end) ~= lastStart
        starts(end + 1) = lastStart;
    end
end
end
