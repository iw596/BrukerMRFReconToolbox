function result = OptimiseFAPatternCRB(params)
% OptimiseFAPatternCRB  Optimise an MRF flip-angle pattern to minimise the
%   Cramér-Rao Bound on T1 and/or T2 over a grid of tissue values.
%
%   result = OptimiseFAPatternCRB(params)
%
%   params fields
%   -------------
%   N          : Number of FA frames
%   TR         : Repetition time, seconds (scalar)
%   TE         : Echo time, seconds (scalar)
%   T1Grid     : Vector of T1 values (seconds) to optimise over
%   T2Grid     : Vector of T2 values (seconds) to optimise over
%   MaxIter    : Maximum optimiser iterations (default 200)
%   NIso       : Isochromats per voxel (default 1)
%   FAMin_deg  : Lower bound on each FA (default 1)
%   FAMax_deg  : Upper bound on each FA (default 90)
%   InitFA     : Initial FA pattern in degrees (default random)
%   Objective  : 'T1', 'T2', or 'joint' (default 'joint')
%   Weights    : [wT1, wT2] relative weighting for joint objective (default [1 1])
%   Normalise  : Normalise CRBs by T1²/T2² before combining (default true)
%   ProgressFcn: Optional function handle @(iter, totalIter, fval, fa) for progress callbacks

% ---- Default parameters -------------------------------------------------
N        = params.N;
TR       = params.TR;
TE       = params.TE;
T1Grid   = params.T1Grid(:).';
T2Grid   = params.T2Grid(:).';

maxIter  = getfield_default(params, 'MaxIter',    200);
NIso     = getfield_default(params, 'NIso',       1);
faMin    = getfield_default(params, 'FAMin_deg',  1);
faMax    = getfield_default(params, 'FAMax_deg',  90);
initFA   = getfield_default(params, 'InitFA',     []);
objective= getfield_default(params, 'Objective',  'joint');
weights  = getfield_default(params, 'Weights',    [1 1]);
normalise= getfield_default(params, 'Normalise',  true);
progFcn  = getfield_default(params, 'ProgressFcn', []);

% ---- Build valid T1/T2 pairs (T1 >= T2) ---------------------------------
LUT = [];
for ii = 1:numel(T1Grid)
    for jj = 1:numel(T2Grid)
        if T1Grid(ii) >= T2Grid(jj)
            LUT(end+1, :) = [T1Grid(ii), T2Grid(jj)]; %#ok<AGROW>
        end
    end
end
nPairs = size(LUT, 1);
if nPairs == 0
    error('OptimiseFAPatternCRB:NoPairs', ...
        'No valid T1/T2 pairs found (require T1 >= T2).');
end

% ---- Initial FA pattern --------------------------------------------------
if isempty(initFA) || numel(initFA) ~= N
    rng(0);
    initFA = faMin + (faMax - faMin) .* abs(sin(pi * (1:N) / N));
end
x0 = initFA(:).';    % row vector of N values

% ---- Objective function --------------------------------------------------
iter = 0;
costHistory = zeros(maxIter + 1, 1);

    function cost = objectiveFcn(x)
        fa = min(faMax, max(faMin, x));     % soft-clamp (hard lb/ub via fmincon)
        crbT1_sum = 0;
        crbT2_sum = 0;
        for kIdx = 1:nPairs
            T1k = LUT(kIdx,1);
            T2k = LUT(kIdx,2);
            [c1, c2] = CRBObjective(fa, TR, TE, T1k, T2k, NIso);
            if normalise
                c1 = c1 / T1k^2;
                c2 = c2 / T2k^2;
            end
            crbT1_sum = crbT1_sum + c1;
            crbT2_sum = crbT2_sum + c2;
        end

        switch lower(objective)
            case 't1'
                cost = crbT1_sum / nPairs;
            case 't2'
                cost = crbT2_sum / nPairs;
            otherwise  % joint
                cost = (weights(1) * crbT1_sum + weights(2) * crbT2_sum) / nPairs;
        end

        iter = iter + 1;
        if iter <= numel(costHistory)
            costHistory(iter) = cost;
        end
        if ~isempty(progFcn) && mod(iter, 5) == 0
            try
                progFcn(iter, maxIter, cost, fa);
            catch
            end
        end
    end

% ---- Run optimiser -------------------------------------------------------
lb = repmat(faMin,  1, N);
ub = repmat(faMax,  1, N);

opts = optimoptions('fmincon', ...
    'Algorithm',              'interior-point', ...
    'MaxIterations',          maxIter, ...
    'MaxFunctionEvaluations', maxIter * N * 4, ...
    'Display',                'iter-detailed', ...
    'OptimalityTolerance',    1e-6, ...
    'StepTolerance',          1e-6);

[xOpt, fOpt, exitFlag, output] = fmincon(@objectiveFcn, x0, [], [], [], [], lb, ub, [], opts);

% ---- Evaluate final CRBs -------------------------------------------------
crbT1_final = zeros(nPairs, 1);
crbT2_final = zeros(nPairs, 1);
for kFinal = 1:nPairs
    [crbT1_final(kFinal), crbT2_final(kFinal)] = CRBObjective(xOpt, TR, TE, LUT(kFinal,1), LUT(kFinal,2), NIso);
end

% ---- Pack result ---------------------------------------------------------
result.FA_deg          = xOpt;
result.CostFinal       = fOpt;
result.ExitFlag        = exitFlag;
result.Iterations      = output.iterations;
result.CostHistory     = costHistory(1:min(iter, numel(costHistory)));
result.LUT             = LUT;
result.CRB_T1          = crbT1_final;
result.CRB_T2          = crbT2_final;
result.Params          = params;

end % OptimiseFAPatternCRB

% -------------------------------------------------------------------------
function v = getfield_default(s, field, default)
if isfield(s, field) && ~isempty(s.(field))
    v = s.(field);
else
    v = default;
end
end
