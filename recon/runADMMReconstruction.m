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
%
% Optional adaptive step size (residual balancing, Boyd et al. 2011):
% when enabled via context.AdaptiveRho, rho is increased when the primal
% residual dominates the dual residual and decreased in the opposite
% case, which keeps the two residuals within a factor of context.RhoTau
% of each other. The scaled dual u is rescaled with rho so that the
% unscaled dual variable (rho*u) is left unchanged by the update, since
% it is rho, not u, that must track the changing step size. Enable with
% context.AdaptiveRho = true; tune context.RhoMu (imbalance threshold,
% default 10) and context.RhoTau (adaptation factor, default 2).

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

adaptiveRho = isfield(context, 'AdaptiveRho') && islogical(context.AdaptiveRho) && context.AdaptiveRho;
rhoMu = getContextDefault(context, 'RhoMu', 10);         % imbalance threshold that triggers adaptation
rhoTau = getContextDefault(context, 'RhoTau', 2);        % multiplicative step used to grow/shrink rho
rhoMin = getContextDefault(context, 'RhoMin', rho / 1e3); % bounds prevent runaway adaptation
rhoMax = getContextDefault(context, 'RhoMax', rho * 1e3);
if adaptiveRho
    rhoMu = positiveScalar(rhoMu, 'RhoMu');
    rhoTau = positiveScalar(rhoTau, 'RhoTau');
    rhoMin = positiveScalar(rhoMin, 'RhoMin');
    rhoMax = positiveScalar(rhoMax, 'RhoMax');
end

% Live console logging of ADMM progress, on by default; disable with
% context.ShowProgress = false for silent/batch runs.
showProgress = logical(getContextDefault(context, 'ShowProgress', true));

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
result.ResidualHistory.Rho = zeros(outerIterations, 1);
result.ResidualHistory.ElapsedSeconds = zeros(outerIterations, 1);
result.Log = {sprintf('ADMM with LLR: %d outer iterations, %d CG iterations, coefficient size [%s].', ...
    outerIterations, cgIterations, num2str(size(x)))};
if adaptiveRho
    result.Log{end + 1} = sprintf(...
        'Adaptive rho enabled: mu=%.3g, tau=%.3g, bounds=[%.3g, %.3g].', ...
        rhoMu, rhoTau, rhoMin, rhoMax);
end
if showProgress
    fprintf('%s\n', result.Log{:});
end

totalTimer = tic;
for outer = 1:outerIterations
    outerTimer = tic;
    zPrevious = z;
    rightHandSide = adjointData + rho * (z - u);
    normalEquation = @(candidate) operators.Normal(candidate) + rho * candidate;
    [x, cgCount] = conjugateGradient(normalEquation, rightHandSide, x, cgIterations, 1e-4);

    % The LLR proximal threshold is lambda/rho for the objective above.
    z = regularizer.prox(x + u, lambda / rho);
    u = u + x - z;

    primal = norm(x(:) - z(:));
    dual = rho * norm(z(:) - zPrevious(:));
    elapsed = toc(outerTimer);
    result.ResidualHistory.Primal(outer) = primal;
    result.ResidualHistory.Dual(outer) = dual;
    result.ResidualHistory.CG(outer) = cgCount;
    result.ResidualHistory.Rho(outer) = rho;
    result.ResidualHistory.ElapsedSeconds(outer) = elapsed;
    result.Iterations.Outer = outer;
    result.Iterations.Inner = cgCount;

    iterationLog = sprintf(...
        '[ADMM] outer %d/%d | CG %d/%d | primal %.4e | dual %.4e | rho %.4e | %.2fs', ...
        outer, outerIterations, cgCount, cgIterations, primal, dual, rho, elapsed);
    result.Log{end + 1} = iterationLog;
    if showProgress
        fprintf('%s\n', iterationLog);
    end

    if adaptiveRho
        if primal > rhoMu * dual
            rho = min(rho * rhoTau, rhoMax);
            u = u / rhoTau; % rescale scaled dual so rho*u (unscaled dual) is preserved
        elseif dual > rhoMu * primal
            rho = max(rho / rhoTau, rhoMin);
            u = u * rhoTau;
        end
    end
end
totalElapsed = toc(totalTimer);

result.Coefficients = x;
result.images = operators.TemporalForward(x);
result.Image = result.images;
result.DualVariable = u;
result.AuxiliaryVariable = z;
result.Rho = rho; % final rho, useful as a warm start for subsequent runs
result.Status = 'Completed';
result.ElapsedSeconds = totalElapsed;
finalLog = sprintf('Final primal residual %.4e; dual residual %.4e; final rho %.4e; total time %.2fs.', ...
    primal, dual, rho, totalElapsed);
result.Log{end + 1} = finalLog;
if showProgress
    fprintf('%s\n', finalLog);
end
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

function value = getContextDefault(context, field, defaultValue)
%getContextDefault Read an optional context field, falling back to a default.
if isfield(context, field) && ~isempty(context.(field))
    value = context.(field);
else
    value = defaultValue;
end
end
