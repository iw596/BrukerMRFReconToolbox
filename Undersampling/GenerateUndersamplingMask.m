function mask = GenerateUndersamplingMask(dims, R, opts)
%GENERATEUNDERSAMPLINGMASK Variable-density Poisson-disc undersampling masks.
%   mask = GenerateUndersamplingMask(dims, R, opts) generates a
%   Ny x Nz x Nt logical mask. Each Ny x Nz frame is an independently
%   generated variable-density Poisson-disc pattern with acceleration
%   factor R. Every frame contains exactly the same number of sampled
%   points, as required for MRF reconstructions.
%
%   dims - [Ny, Nz, Nt]
%   R    - acceleration factor, defined relative to the full Ny*Nz
%         matrix (i.e. Ntotal = round(Ny*Nz/R)), regardless of any
%         elliptical restriction of the sampling domain
%   opts.sigma          - normalised Gaussian rolloff of the sampling
%                         density, as a fraction of the domain half-width
%                         (roughly 0-1). Small sigma -> densely sampled
%                         centre with fast fall-off (strongly variable
%                         density). Large sigma -> close to uniform
%                         density. Default 0.35
%   opts.ellipticalMask - if true, restrict sampling to an ellipse
%                         inscribed in the Ny x Nz grid instead of the
%                         full rectangle. Default false
%   opts.autoCalibSize  - [acsY, acsZ] size of the fully-sampled
%                         autocalibration region at the centre of
%                         k-space. Identical for every frame and does not
%                         count against the Poisson-disc spacing. Default
%                         [0 0] (no ACS region)
%
%   mask - Ny x Nz x Nt logical array

arguments
    dims (1,3) double {mustBeInteger, mustBePositive}
    R (1,1) double {mustBePositive}
    opts.sigma (1,1) double {mustBePositive} = 0.35
    opts.ellipticalMask (1,1) logical = false
    opts.autoCalibSize (1,2) double {mustBeNonnegative, mustBeInteger} = [0 0]
end

Ny = dims(1);
Nz = dims(2);
Nt = dims(3);

cy = floor(Ny/2) + 1; % k-space centre, y
cz = floor(Nz/2) + 1; % k-space centre, z

%% Sampling domain: full rectangle, or an ellipse inscribed within it
[Zg, Yg] = meshgrid(1:Nz, 1:Ny);
if opts.ellipticalMask
    domainMask = ((Yg-cy)/(Ny/2)).^2 + ((Zg-cz)/(Nz/2)).^2 <= 1;
else
    domainMask = true(Ny, Nz);
end

%% Autocalibration (ACS) region: identical, fully-sampled, every frame
acsMask = false(Ny, Nz);
acsY = opts.autoCalibSize(1);
acsZ = opts.autoCalibSize(2);
if acsY > 0 && acsZ > 0
    yIdx = (cy-floor(acsY/2)) : (cy-floor(acsY/2)+acsY-1);
    zIdx = (cz-floor(acsZ/2)) : (cz-floor(acsZ/2)+acsZ-1);
    yIdx = yIdx(yIdx >= 1 & yIdx <= Ny);
    zIdx = zIdx(zIdx >= 1 & zIdx <= Nz);
    acsMask(yIdx, zIdx) = true;
end
acsMask = acsMask & domainMask;

%% Variable-density map: Gaussian rolloff in normalised radius (0 at centre, 1 at domain edge)
normRadius = sqrt(((Yg-cy)/(Ny/2)).^2 + ((Zg-cz)/(Nz/2)).^2);
density = exp(-normRadius.^2 / (2*opts.sigma^2));
density(~domainMask) = 0;

%% Target sample count, fixed and identical for every frame
% R is conventionally defined relative to the full matrix size, not the
% (possibly smaller) elliptical sampling domain
Nacs = nnz(acsMask);
Ndomain = nnz(domainMask);
Ntotal = max(round(Ny*Nz/R), Nacs); % ACS points are always included
if Ntotal > Ndomain
    warning('GenerateUndersamplingMask:DomainTooSmall', ...
        'Requested %d samples exceed the %d points available in the sampling domain; sampling the full domain instead.', Ntotal, Ndomain);
    Ntotal = Ndomain;
end
Nrandom = Ntotal - Nacs; % additional variable-density points needed per frame

% Candidate pool for the variable-density Poisson disc: domain points
% outside the ACS region
candMask = domainMask & ~acsMask;
[candY, candZ] = find(candMask);
candDensity = density(sub2ind([Ny Nz], candY, candZ));

% Base minimum-distance of the disc, from the average 2-D Poisson-disc
% packing efficiency (~0.7) over the candidate pool
if Nrandom > 0
    dBase = sqrt(0.7 * numel(candY) / (pi*Nrandom));
else
    dBase = Inf;
end

%% Generate an independent pattern per frame
mask = false(Ny, Nz, Nt);
for t = 1:Nt
    mask(:,:,t) = acsMask | localGenerateFrameSamples(candY, candZ, candDensity, dBase, Nrandom, Ny, Nz);
end

end

function frameMask = localGenerateFrameSamples(candY, candZ, candDensity, dBase, Nrandom, Ny, Nz)
% Variable-density Poisson-disc dart-throwing for a single frame. Each
% candidate's local minimum spacing shrinks with its sampling density, so
% high-density (e.g. central) regions are packed more tightly than the
% periphery.

frameMask = false(Ny, Nz);
if Nrandom <= 0
    return
end

localMinDist = dBase ./ sqrt(max(candDensity, eps));

nCand = numel(candY);
accepted = false(nCand, 1);
acceptedXY = zeros(Nrandom, 2);
nAccepted = 0;

relaxation = 1; % progressively relaxed if the target count is not reached
maxRelaxSteps = 20;

for step = 1:maxRelaxSteps
    order = randperm(nCand); % fresh random dart order every pass and frame
    for k = order
        if accepted(k) || nAccepted >= Nrandom
            continue
        end
        d = localMinDist(k) * relaxation;
        if nAccepted == 0
            ok = true;
        else
            dy = acceptedXY(1:nAccepted,1) - candY(k);
            dz = acceptedXY(1:nAccepted,2) - candZ(k);
            ok = all(dy.^2 + dz.^2 >= d^2);
        end
        if ok
            nAccepted = nAccepted + 1;
            accepted(k) = true;
            acceptedXY(nAccepted,:) = [candY(k), candZ(k)];
        end
    end
    if nAccepted >= Nrandom
        break
    end
    relaxation = relaxation * 0.85; % shrink required spacing and retry unaccepted candidates
end

% Safeguard so every frame has exactly the same point count even if the
% spacing constraint alone cannot reach the target (e.g. high R, small sigma)
if nAccepted < Nrandom
    remaining = find(~accepted);
    remaining = remaining(randperm(numel(remaining)));
    fillIdx = remaining(1:(Nrandom-nAccepted));
    accepted(fillIdx) = true;
end

idx = sub2ind([Ny Nz], candY(accepted), candZ(accepted));
frameMask(idx) = true;

end