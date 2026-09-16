function operators = buildMRFSubspaceOperators(samplingMask, basis)
%buildMRFSubspaceOperators Build A, A' and A'A for subspace MRF imaging.
%
% Coefficients have size [nx ny nz K], images have size [nx ny nz Nt], and
% k-space has the same size as images. The forward model is
%
%   A(alpha) = P F (alpha Phi'),
%
% where F is an explicitly unitary spatial FFT and P is multiplication by the binary
% sampling mask. Since Phi has orthonormal columns, temporalAdjoint below
% is the Hermitian adjoint of temporalForward. The FFT implementation in
% legacy fftcn/ifftcn helpers are inverse pairs but use a different scaling,
% so this file implements the unitary pair locally for CG correctness.

if nargin < 2
    error('buildMRFSubspaceOperators:MissingInput', 'A sampling mask and basis are required.');
end
if ~islogical(samplingMask)
    samplingMask = logical(samplingMask);
end
if ndims(samplingMask) ~= 4
    error('buildMRFSubspaceOperators:InvalidMask', ...
        'The sampling mask must have size [nx ny nz Nt].');
end
if ~ismatrix(basis) || size(basis, 1) ~= size(samplingMask, 4)
    error('buildMRFSubspaceOperators:InvalidBasis', ...
        'The basis must have size [Nt K], with Nt matching the mask.');
end

operators.Basis = basis;
operators.Mask = samplingMask;
operators.Forward = @(alpha) forwardModel(alpha, samplingMask, basis);
operators.Adjoint = @(kSpace) adjointModel(kSpace, samplingMask, basis);
operators.Normal = @(alpha) operators.Adjoint(operators.Forward(alpha));
operators.TemporalForward = @(alpha) temporalForward(alpha, basis);
operators.TemporalAdjoint = @(images) temporalAdjoint(images, basis);
end

function kSpace = forwardModel(alpha, mask, basis)
images = temporalForward(alpha, basis);
kSpace = unitaryFFT(images, [1 2 3]);
kSpace = kSpace .* mask;
end

function alpha = adjointModel(kSpace, mask, basis)
if ~isequal(size(kSpace), size(mask))
    error('buildMRFSubspaceOperators:DataSizeMismatch', ...
        'K-space data and sampling mask must have identical sizes.');
end
images = unitaryIFFT(kSpace .* mask, [1 2 3]);
alpha = temporalAdjoint(images, basis);
end

function images = temporalForward(alpha, basis)
nComponents = size(alpha, 4);
if nComponents ~= size(basis, 2)
    error('buildMRFSubspaceOperators:CoefficientMismatch', ...
        'Coefficient count does not match the temporal basis.');
end
spatialSize = size(alpha);
spatialSize = spatialSize(1:3);
images = reshape(reshape(alpha, [], nComponents) * basis', ...
    [spatialSize size(basis, 1)]);
end

function alpha = temporalAdjoint(images, basis)
if size(images, 4) ~= size(basis, 1)
    error('buildMRFSubspaceOperators:TimeMismatch', ...
        'Image time dimension does not match the temporal basis.');
end
spatialSize = size(images);
spatialSize = spatialSize(1:3);
alpha = reshape(reshape(images, [], size(basis, 1)) * basis, ...
    [spatialSize size(basis, 2)]);
end

function output = unitaryFFT(input, dimensions)
output = input;
for dimension = dimensions
    output = fftshift(fft(ifftshift(output, dimension), [], dimension), dimension) ...
        / sqrt(size(output, dimension));
end
end

function output = unitaryIFFT(input, dimensions)
output = input;
for dimension = dimensions
    output = fftshift(ifft(ifftshift(output, dimension), [], dimension), dimension) ...
        * sqrt(size(output, dimension));
end
end