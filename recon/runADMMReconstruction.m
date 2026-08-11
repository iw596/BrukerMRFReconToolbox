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

if isempty(regularizer) || ~isstruct(regularizer) || ~isfield(regularizer, 'Prox') || isempty(regularizer.Prox)
    error('runADMMReconstruction:InvalidRegularizer', ...
        'Regularizer must provide a valid proximal operator.');
end

components = resolveRegularizerComponents(regularizer);
nComponents = numel(components);
result.RegularizerComponentCount = nComponents;
result.Log{end+1} = sprintf('Split-ADMM enabled with %d regularizer component(s).', nComponents);

zList = cell(nComponents, 1);
uList = cell(nComponents, 1);
for iComp = 1:nComponents
    zList{iComp} = x;
    uList{iComp} = zeros(size(x), 'like', x);
end

result.ResidualHistory = struct('Primal', zeros(outerMax, 1), 'Dual', zeros(outerMax, 1));

for outerIter = 1:outerMax
    for innerIter = 1:innerMax
        zPrev = zList;

        for iComp = 1:nComponents
            zList{iComp} = components{iComp}.Prox(x + uList{iComp}, rho);
        end

        zMinusU = zeros(size(x), 'like', x);
        for iComp = 1:nComponents
            zMinusU = zMinusU + (zList{iComp} - uList{iComp});
        end

        % Data-consistency update for split-ADMM consensus.
        x = (xData + rho .* zMinusU) ./ (1 + rho * nComponents);

        for iComp = 1:nComponents
            uList{iComp} = uList{iComp} + (x - zList{iComp});
        end

        [primalResidual, dualResidual] = computeResiduals(x, zList, zPrev, rho);

        result.Iterations.Inner = innerIter;
    end

    result.Iterations.Outer = outerIter;
    result.Iterations.Inner = innerMax;
    result.ResidualHistory.Primal(outerIter) = primalResidual;
    result.ResidualHistory.Dual(outerIter) = dualResidual;
    result.Log{end+1} = sprintf('Completed outer iteration %d (primal=%.4e, dual=%.4e).', ...
        outerIter, primalResidual, dualResidual);
end

result.images = x;
result.Image = x;
result.DualVariable = uList;
result.AuxiliaryVariable = zList;
result.Rho = rho;
result.Status = 'Completed';
end

function components = resolveRegularizerComponents(regularizer)
if isfield(regularizer, 'Components') && ~isempty(regularizer.Components)
    components = regularizer.Components;
else
    components = {regularizer};
end

for iComp = 1:numel(components)
    if ~isfield(components{iComp}, 'Prox') || isempty(components{iComp}.Prox)
        error('runADMMReconstruction:InvalidRegularizerComponent', ...
            'Regularizer component %d is missing a proximal operator.', iComp);
    end
end
end

function [primalResidual, dualResidual] = computeResiduals(x, zList, zPrev, rho)
primalSq = 0;
dualSq = 0;

for iComp = 1:numel(zList)
    r = x - zList{iComp};
    primalSq = primalSq + sum(abs(r(:)).^2);

    dz = zList{iComp} - zPrev{iComp};
    dualSq = dualSq + sum(abs((rho .* dz(:))).^2);
end

primalResidual = sqrt(primalSq);
dualResidual = sqrt(dualSq);
end
