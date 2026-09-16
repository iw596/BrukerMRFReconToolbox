function TestIterativeMRFOperators()
%TestIterativeMRFOperators Check dimensions and the subspace adjoint identity.
%
% Run from the toolbox root after adding the repository with genpath.

rng(7);
nx = 6;
ny = 5;
nz = 3;
nt = 8;
nComponents = 3;

basis = orth(randn(nt, nComponents));
mask = rand(nx, ny, nz, nt) > 0.35;
operators = buildMRFSubspaceOperators(mask, basis);

coefficients = randn(nx, ny, nz, nComponents) + 1i * randn(nx, ny, nz, nComponents);
kSpace = randn(nx, ny, nz, nt) + 1i * randn(nx, ny, nz, nt);

leftInnerProduct = sum(conj(operators.Forward(coefficients)) .* kSpace, 'all');
rightInnerProduct = sum(conj(coefficients) .* operators.Adjoint(kSpace), 'all');
assert(abs(leftInnerProduct - rightInnerProduct) < 1e-10 * max(1, abs(leftInnerProduct)), ...
    'The subspace forward and adjoint operators are inconsistent.');

llr2D = LLR([3 3], [3 3]);
result2D = llr2D.prox(randn(nx, ny, nComponents), 0.1);
assert(isequal(size(result2D), [nx ny nComponents]));

llr3D = LLR([3 3 2], [3 3 2]);
result3D = llr3D.prox(randn(nx, ny, nz, nComponents), 0.1);
assert(isequal(size(result3D), [nx ny nz nComponents]));

disp('TestIterativeMRFOperators passed.');
end
