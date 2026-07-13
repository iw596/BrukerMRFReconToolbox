function result = runADMMReconstruction(context, geometry, regularizer, data)
% runADMMReconstruction  ADMM skeleton for 2D/3D MRF reconstruction.
%
%   This implementation uses a simple consensus-style ADMM update that
%   applies the selected regularizer proximal operator on image-domain data.

result = struct();
result.Status = 'Skeleton completed';
result.Dimensionality = context.Dimensionality;
result.Geometry = geometry;
result.Regularizer = regularizer;
result.Iterations = struct('Outer', 0, 'Inner', 0);
result.Log = {};
result.SubspaceComponentRetentionPct = context.SubspaceComponentRetentionPct;

outerMax = context.OuterIterations;
innerMax = context.InnerIterations;
rho = context.Rho;

result.Log{end+1} = sprintf('Starting %s reconstruction with %s regularizer.', ...
    upper(char(context.Dimensionality)), regularizer.Description);
result.Log{end+1} = sprintf('Outer iterations: %d, inner iterations: %d, rho: %.6g', ...
    outerMax, innerMax, rho);
result.Log{end+1} = sprintf('Temporal subspace retention: %.2f%%.', context.SubspaceComponentRetentionPct);
result.Log{end+1} = 'Using image-domain ADMM consensus updates (data-consistency term + selected regularizer prox).';

if nargin < 4 || isempty(data)
    error('runADMMReconstruction:MissingData', ...
        'Iterative reconstruction requires k-space data input.');
end

% Initial image estimate from k-space data.
xData = ifftcn(data, [1 2 3]);
x = xData;
z = x;
u = zeros(size(x), 'like', x);

if isempty(regularizer) || ~isstruct(regularizer) || ~isfield(regularizer, 'Prox') || isempty(regularizer.Prox)
    error('runADMMReconstruction:InvalidRegularizer', ...
        'Regularizer must provide a valid proximal operator.');
end

for outerIter = 1:outerMax
    for innerIter = 1:innerMax
        z = regularizer.Prox(x + u, rho);

        % Simplified data-consistency update with quadratic penalty.
        x = (xData + rho .* (z - u)) ./ (1 + rho);

        % Dual update.
        u = u + (x - z);

        result.Iterations.Inner = innerIter;
    end

    result.Iterations.Outer = outerIter;
    result.Iterations.Inner = innerMax;
    result.Log{end+1} = sprintf('Completed outer iteration %d.', outerIter);
end

result.images = x;
result.Image = x;
result.DualVariable = u;
result.AuxiliaryVariable = z;
result.Rho = rho;
result.Status = 'Completed';
end
