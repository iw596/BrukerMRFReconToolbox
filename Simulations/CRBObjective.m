function [crbT1, crbT2, fim] = CRBObjective(faPattern_deg, TR, TE, T1_s, T2_s, NIso)
% CRBObjective  Compute the Cramér-Rao Bound on T1 and T2 for a given FA pattern.
%
%   [crbT1, crbT2, fim] = CRBObjective(faPattern_deg, TR, TE, T1_s, T2_s, NIso)
%
%   Inputs
%   ------
%   faPattern_deg : 1×N vector of flip angles in degrees
%   TR            : Repetition time in seconds (scalar or 1×N)
%   TE            : Echo time in seconds (scalar or 1×N)
%   T1_s          : T1 value in seconds
%   T2_s          : T2 value in seconds
%   NIso          : Number of isochromats for slice-profile averaging (default 1)
%
%   Outputs
%   -------
%   crbT1  : Cramér-Rao lower bound on T1 variance (s²)
%   crbT2  : Cramér-Rao lower bound on T2 variance (s²)
%   fim    : 2×2 Fisher Information Matrix [dT1 dT2]

if nargin < 6 || isempty(NIso)
    NIso = 1;
end

N = numel(faPattern_deg);
if isscalar(TR), TR = repmat(TR, 1, N); end
if isscalar(TE), TE = repmat(TE, 1, N); end

% Finite-difference step sizes (1% of parameter value, minimum 0.1 ms)
dT1 = max(T1_s * 0.01, 0.1e-3);
dT2 = max(T2_s * 0.01, 0.1e-3);

% Central differences for partial derivatives
SdT1p = fisp_signal(faPattern_deg, TR, TE, T1_s + dT1, T2_s,       NIso);
SdT1m = fisp_signal(faPattern_deg, TR, TE, T1_s - dT1, T2_s,       NIso);
SdT2p = fisp_signal(faPattern_deg, TR, TE, T1_s,       T2_s + dT2, NIso);
SdT2m = fisp_signal(faPattern_deg, TR, TE, T1_s,       T2_s - dT2, NIso);

dSdT1 = (SdT1p - SdT1m) ./ (2 * dT1);  % 1×N
dSdT2 = (SdT2p - SdT2m) ./ (2 * dT2);  % 1×N

% Fisher Information Matrix  (assuming unit noise variance per time point)
% FIM_{ij} = sum_n (dS/dpi)^T (dS/dpj)
dSdT1_vec = [real(dSdT1(:)); imag(dSdT1(:))];
dSdT2_vec = [real(dSdT2(:)); imag(dSdT2(:))];

fim = [dot(dSdT1_vec, dSdT1_vec),  dot(dSdT1_vec, dSdT2_vec); ...
       dot(dSdT2_vec, dSdT1_vec),  dot(dSdT2_vec, dSdT2_vec)];

% CRB = diagonal of inv(FIM)
detFIM = fim(1,1)*fim(2,2) - fim(1,2)*fim(2,1);
if abs(detFIM) < 1e-30
    crbT1 = Inf;
    crbT2 = Inf;
else
    invFIM = [fim(2,2), -fim(1,2); -fim(2,1), fim(1,1)] ./ detFIM;
    crbT1 = invFIM(1,1);
    crbT2 = invFIM(2,2);
end

end % CRBObjective

% -------------------------------------------------------------------------
function S = fisp_signal(faPattern_deg, TR, TE, T1, T2, NIso)
% FISP (spoiled-GRE style) Bloch simulation over an FA pattern.
% Returns complex signal vector 1×N.

N = numel(faPattern_deg);
phi = linspace(-pi, pi, NIso);

M = zeros(3, NIso);
M(3,:) = 1;

S = zeros(1, N);
for ii = 1:N
    % Instantaneous RF excitation
    alpha = deg2rad(faPattern_deg(ii));
    R = xrot(alpha);
    M = R * M;

    % Free precession to TE
    [A, B] = freeprecess(TE(ii) * 1000, T1 * 1000, T2 * 1000); % freeprecess uses ms
    M = A * M + B;

    % Record signal
    S(ii) = mean(M(1,:) + 1i * M(2,:));

    % Free precession TR - TE then quadratic spoiling
    [A, B] = freeprecess((TR(ii) - TE(ii)) * 1000, T1 * 1000, T2 * 1000);
    M = A * M + B;

    for j = 1:NIso
        M(:,j) = zrot(phi(j)) * M(:,j);
    end
end
end % fisp_signal
