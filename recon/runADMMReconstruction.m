function result = runADMMReconstruction(context, geometry, regularizer, data, operators)
%runADMMReconstruction Reconstruct subspace coefficients with LLR-ADMM.
%
% This function solves the split problem
%
%   minimize 0.5*||A*x - d||_2^2 + lambda*R(x),  subject to x = z,
%
% where x contains subspace coefficient images and R is the LLR penalty.
% With scaled dual variable u, the updates are
%
%   x <- solve((A'*A + rho*I)x = A'*d + rho*(z-u))
%   z <- prox_(lambda/rho R)(x+u)
%   u <- u + x-z.
%
% The x equation is solved by conjugate gradients because A'*A is not
% generally diagonal after sampling and temporal projection. InnerIterations
% controls the maximum number of CG iterations per ADMM iteration.

if nargin < 5 || isempty(operators)
    error('runADMMReconstruction:MissingOperators', ...
        'The masked subspace forward and adjoint operators are required.');
end
if nargin < 4 || isempty(data)
    error('runADMMReconstruction:MissingData', 'K-space data is required.');
end
if ~isa(regularizer, 'LLR')
    error('runADMMReconstruction:InvalidRegularizer', ...
        'Iterative MRF reconstruction currently supports the LLR object only.');
end

rho = positiveScalar(context.Rho, 'Rho');
lambda = positiveScalar(context.Lambda, 'Lambda');
outerIterations = positiveInteger(context.OuterIterations, 'OuterIterations');
cgIterations = positiveInteger(context.InnerIterations, 'InnerIterations');

adjointData = operators.Adjoint(data);
x = adjointData;
z = x;
u = zeros(size(x), 'like', x);

result = struct();
result.Status = 'Running';
result.Dimensionality = geometry.Dimensionality;
result.Geometry = geometry;
result.Regularizer = regularizer;
result.Rho = rho;
result.Lambda = lambda;
result.Iterations = struct('Outer', 0, 'Inner', 0);
result.ResidualHistory = struct('Primal', zeros(outerIterations, 1), ...
    'Dual', zeros(outerIterations, 1), 'CG', zeros(outerIterations, 1));
result.Log = {sprintf('ADMM with LLR: %d outer iterations, %d CG iterations.', ...
    outerIterations, cgIterations)};

for outer = 1:outerIterations
    zPrevious = z;
    rightHandSide = adjointData + rho * (z - u);
    normalEquation = @(candidate) operators.Normal(candidate) + rho * candidate;
    [x, cgCount] = conjugateGradient(normalEquation, rightHandSide, x, cgIterations, 1e-4);

    % The LLR proximal threshold is lambda/rho for the objective above.
    z = regularizer.prox(x + u, lambda / rho);
    u = u + x - z;

    primal = norm(x(:) - z(:));
    dual = rho * norm(z(:) - zPrevious(:));
    result.ResidualHistory.Primal(outer) = primal;
    result.ResidualHistory.Dual(outer) = dual;
    result.ResidualHistory.CG(outer) = cgCount;
    result.Iterations.Outer = outer;
    result.Iterations.Inner = cgCount;
end

result.Coefficients = x;
result.images = operators.TemporalForward(x);
result.Image = result.images;
result.DualVariable = u;
result.AuxiliaryVariable = z;
result.Status = 'Completed';
result.Log{end + 1} = sprintf('Final primal residual %.4e; dual residual %.4e.', primal, dual);
end

function [x, iterations] = conjugateGradient(operator, b, x, maxIterations, tolerance)
%conjugateGradient Solve a Hermitian positive-definite linear system.
r = b - operator(x);
p = r;
rrOld = real(sum(conj(r(:)) .* r(:)));
initialNorm = sqrt(rrOld);
if initialNorm == 0
    iterations = 0;
    return;
end

for iterations = 1:maxIterations
    Ap = operator(p);
    denominator = real(sum(conj(p(:)) .* Ap(:)));
    if denominator <= 0 || ~isfinite(denominator)
        error('runADMMReconstruction:InvalidNormalOperator', ...
            'The normal-equation operator is not positive definite.');
    end
    step = rrOld / denominator;
    x = x + step * p;
    r = r - step * Ap;
    rrNew = real(sum(conj(r(:)) .* r(:)));
    if sqrt(rrNew) <= tolerance * initialNorm
        return;
    end
    p = r + (rrNew / rrOld) * p;
    rrOld = rrNew;
end
end

function value = positiveScalar(value, name)
value = double(value);
if ~isscalar(value) || ~isfinite(value) || value <= 0
    error('runADMMReconstruction:InvalidOption', '%s must be a positive scalar.', name);
end
end

function value = positiveInteger(value, name)
value = positiveScalar(value, name);
if value ~= round(value)
    error('runADMMReconstruction:InvalidOption', '%s must be a positive integer.', name);
end
value = round(value);
end
