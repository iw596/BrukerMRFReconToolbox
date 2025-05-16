%% Script to perform spiral MRF recon  
addpath(genpath('./.'));
%% Load data
pth = uigetdir;
params = LoadBrukerData(pth,true);


%% Trim raw data 
nextMultiple = 128 * ceil((params.Traj.PVM_SpiralSize + params.Traj.PVM_SpiralPostSize) / 128);
padding = nextMultiple - params.Traj.PVM_SpiralSize;
data = params.data;
data = reshape(data,[nextMultiple,params.NPointsPerPrep*params.MRFNPrepModules,params.Traj.PVM_SpiralNbOfInterleaves]);
data = data(1:params.Traj.PVM_SpiralSize,:,:);
data = permute(data,[1 3 2]);
data = reshape(data,[params.Traj.PVM_SpiralSize * params.Traj.PVM_SpiralNbOfInterleaves,params.NPointsPerPrep*params.MRFNPrepModules]);

%% Form trajectory
k = params.Traj.PVM_TrajKScale(1) .* params.Traj.kx + 1j*params.Traj.PVM_TrajKScale(2) .*params.Traj.ky;
k = reshape(k,[params.Traj.PVM_SpiralSize + params.Traj.PVM_SpiralPostSize ,params.Traj.PVM_SpiralNbOfInterleaves]);
k = k(1:params.Traj.PVM_SpiralSize,:);
k = reshape(k,[params.Traj.PVM_SpiralSize *params.Traj.PVM_SpiralNbOfInterleaves,1]);
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
n_iter = 10;
for it = 1:n_iter
    % Create gridded image from current DCF
    % Forward NUFFT (from image to k-space)
    GHGw = nufft(nufft_adj(w, nufft_st),nufft_st);  % should be [Npts x 1]
    w = w./(abs(GHGw));
    resid = max(abs(GHGw - 1),[],"all");
end

img = nufft_adj(w.*conj(data), nufft_st);  % adjoint (gridding);
figure; imshow(abs(img(:,:,1)),[]);
figure; plot(squeeze(abs(img(34,21,:))))

% Normalise Dictionary
normalisedDict = zeros(size(dict));

cnt=size(dict,2);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(:,c).*conj(dict(:,c))));
    normalisedDict(:,c) = dict(:,c) / scaleFactor;
end
T1Map = [];
T2Map = [];
indexMap = [];
% Iterate through each voxel
parfor i = 1:64
    i
    for j = 1:64

       scaleFactor = sqrt(sum(img(i,j,:).*conj(img(i,j,:))));
       normalized_mrfsignal = conj(img(i,j,:))/scaleFactor;
       inner_product=abs(squeeze(normalized_mrfsignal)'* (normalisedDict));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       T1Map(i,j) = LUT(max_index,1);
       T2Map(i,j) = LUT(max_index,2);
       MRFMask(i,j) = 1;
       dotProductMaximums(i,j) = maxValue;
       indexMap(i,j) = max_index;

    end
end

figure; plot()