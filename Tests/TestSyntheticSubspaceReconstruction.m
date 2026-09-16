function TestSyntheticSubspaceReconstruction()
%TestSyntheticSubspaceReconstruction Test iterative MRF on synthetic data.
%
% This test creates a known low-rank coefficient volume, synthesises masked
% k-space data with the same subspace forward model used by reconstruction,
% and then checks that LLR-ADMM returns correctly sized finite images with
% improved data consistency.
%
% Run from MATLAB with the repository on the path, or run this file from the
% repository root:
%
%   TestSyntheticSubspaceReconstruction

root = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(root));

rng(17, 'twister');
runSyntheticCase('2D', [24 20 1], [4 4 1], [4 4 1], 0.45);
runSyntheticCase('3D', [16 14 6], [4 4 2], [4 4 1], 0.45);

disp('TestSyntheticSubspaceReconstruction passed.');
end

function runSyntheticCase(dimensionality, spatialSize, blockSize, stride, samplingFraction)
% Build a small orthonormal temporal basis.
nTimePoints = 12;
nComponents = 3;
randomBasis = randn(nTimePoints, nComponents) + 1i * randn(nTimePoints, nComponents);
basis = orth(randomBasis);

% Create smooth, spatially varying coefficient images. The low-rank spatial
% structure makes the LLR prior meaningful while keeping the test fast.
coefficientSize = [spatialSize nComponents];
coefficients = zeros(coefficientSize);
[xGrid, yGrid, zGrid] = ndgrid( ...
    linspace(-1, 1, spatialSize(1)), ...
    linspace(-1, 1, spatialSize(2)), ...
    linspace(-1, 1, spatialSize(3)));
for component = 1:nComponents
    centreX = -0.35 + 0.35 * component;
    centreY = 0.25 - 0.25 * component;
    width = 0.35 + 0.08 * component;
    coefficients(:, :, :, component) = exp(-((xGrid - centreX).^2 + ...
        (yGrid - centreY).^2) / width^2) .* (1 + 0.15 * zGrid * component);
end

% P is a binary Cartesian sampling mask. Keep a fully sampled central
% fraction so the synthetic inverse problem is not needlessly pathological.
mask = rand([spatialSize nTimePoints]) < samplingFraction;
centreX = max(1, floor(spatialSize(1) / 2) - 1):min(spatialSize(1), floor(spatialSize(1) / 2) + 2);
centreY = max(1, floor(spatialSize(2) / 2) - 1):min(spatialSize(2), floor(spatialSize(2) / 2) + 2);
mask(centreX, centreY, :, :) = true;

operators = buildMRFSubspaceOperators(mask, basis);
cleanData = operators.Forward(coefficients);
noise = 0.01 * (randn(size(cleanData)) + 1i * randn(size(cleanData)));
data = cleanData + noise;

context = struct();
context.Dimensionality = dimensionality;
context.DataSize = size(data);
context.RegularizationMode = 'Locally-low rank';
context.Lambda = 0.002;
context.Rho = 1;
context.OuterIterations = 8;
context.InnerIterations = 12;
context.BlockSize = blockSize;
context.Stride = stride;
context.SubspaceComponentRetentionPct = 100;

context = buildMRFReconContext(context);
geometry = buildMRFReconGeometry(context);
regularizer = LLR(blockSize, stride, context.Lambda);
result = runADMMReconstruction(context, geometry, regularizer, data, operators);

expectedImageSize = [spatialSize nTimePoints];
assert(strcmp(result.Status, 'Completed'), ...
    '%s synthetic reconstruction did not complete.', dimensionality);
assert(isequal(size(result.Coefficients), coefficientSize), ...
    '%s coefficient dimensions are incorrect.', dimensionality);
assert(isequal(size(result.images), expectedImageSize), ...
    '%s image dimensions are incorrect.', dimensionality);
assert(all(isfinite(result.images(:))), ...
    '%s reconstruction contains non-finite values.', dimensionality);

% Compare the fitted k-space residual with the zero-filled starting point.
zeroFilledCoefficients = operators.Adjoint(data);
initialResidual = norm(operators.Forward(zeroFilledCoefficients) - data, 'fro');
finalResidual = norm(operators.Forward(result.Coefficients) - data, 'fro');
assert(finalResidual < initialResidual, ...
    '%s reconstruction did not improve data consistency.', dimensionality);

fprintf('%s synthetic case passed: residual %.3e -> %.3e.\n', ...
    dimensionality, initialResidual, finalResidual);
end
