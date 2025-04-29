%% Script to test spiral MRF reconstruction

params = LoadBrukerData("Datasets/20250415_145604_MRF_Phantom_MRF_Spiral_Dev_2_1_20\27",true);

nextMultiple = 128 * ceil(261 / 128);
padding = nextMultiple - params.Traj.PVM_SpiralSize; % Includes padding and rewinder

% Form the data
data = params.data;
data = reshape(data,[nextMultiple,params.NPointsPerPrep*params.MRFNPrepModules,params.Traj.PVM_SpiralNbOfInterleaves]);
data = data(1:params.Traj.PVM_SpiralSize,:,:);
data = permute(data,[1 3 2]);
data = reshape(data,[params.Traj.PVM_SpiralSize * params.Traj.PVM_SpiralNbOfInterleaves,params.NPointsPerPrep*params.MRFNPrepModules]);
% Form trajectory
k = params.Traj.PVM_TrajKScale(1) .* params.Traj.kx + 1j*params.Traj.PVM_TrajKScale(2) .*params.Traj.ky;
k = reshape(k,[params.Traj.PVM_SpiralSize + params.Traj.PVM_SpiralPostSize ,params.Traj.PVM_SpiralNbOfInterleaves]);
k = k(1:params.Traj.PVM_SpiralSize,:);

% Calculate dcf using pipe - menon method

% Assume k-space coordinates (e.g. radial)
k = [real(k(:))*2*pi , imag(k(:)*2*pi)];  % [N x 2]
N = 64;             % Grid size
Nd = [N N];          % Image dimensions
% Create NUFFT structure
J = [6 6];            % interpolation neighborhood
K = 2*length(k);              % oversampling
nufft_st = nufft_init(k, Nd, J, Nd*2, Nd/2);  % using MIRT


% Initalise DCF estimation parameters
Npts = size(k,1);
w = ones(Npts, 1);  % initial guess
n_iter = 30;

for it = 1:n_iter
    % Create gridded image from current DCF
    %g = nufft_adj(dcf .* ones_data, nufft_st);  % adjoint (gridding)
    %g = abs(g).^2;

    % Forward NUFFT (from image to k-space)
    GHGw = nufft(nufft_adj(w, nufft_st),nufft_st);  % should be [Npts x 1]
    w = w./(abs(GHGw));
    resid = max(abs(GHGw - 1),[],"all")
end

img = nufft_adj(w.*data, nufft_st);  % adjoint (gridding);
figure; imshow(abs(img(:,:,10)),[]);

FT = NUFFT(k,1,[0,0],[64 64]);

d

img = FT'*(reshape(dcf,size(dataSub)).*dataSub);

