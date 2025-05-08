addpath(genpath("./."))
%% Comparison of my spiral recon to bruker recon

%% Load Bruker rawdata and recon
params = LoadBrukerData("datasets/20250501_163652_MRF_Phantom_MRF_Dev_01052025_1_21/23",true);

nextMultiple = 128 * ceil(params.Traj.PVM_SpiralSize / 128);
padding = nextMultiple - params.Traj.PVM_SpiralSize; % Includes padding and rewinder

% Form the data
data = params.data;
data = reshape(data,[nextMultiple,params.Traj.PVM_SpiralNbOfInterleaves]);
data = data(1:params.Traj.PVM_SpiralSize,:);
data = reshape(data,[params.Traj.PVM_SpiralSize * params.Traj.PVM_SpiralNbOfInterleaves,1]);
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
n_iter = 20;

for it = 1:n_iter
    % Create gridded image from current DCF
    %g = nufft_adj(dcf .* ones_data, nufft_st);  % adjoint (gridding)
    %g = abs(g).^2;

    % Forward NUFFT (from image to k-space)
    GHGw = nufft(nufft_adj(w, nufft_st),nufft_st);  % should be [Npts x 1]
    w = w./(abs(GHGw));
    resid = max(abs(GHGw - 1),[],"all")
end

iwReconImg = nufft_adj(w.*data, nufft_st);  % adjoint (gridding);
figure; imshow(abs(iwReconImg),[]);


%% Load bruker spiral imgs 
spiralImgs = read_2dseq('datasets/20250501_163652_MRF_Phantom_MRF_Dev_01052025_1_21/23/pdata/1');


figure(1);
subplot(1,2,1); imshow(mat2gray(abs(iwReconImg)),[]); axis on; title("Custom Recon");

subplot(1,2,2); imshow(mat2gray(abs(spiralImgs)),[]); axis on; title("Bruker Recon");




