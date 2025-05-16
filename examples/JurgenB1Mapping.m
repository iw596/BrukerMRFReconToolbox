%% Load 31P data
pth = uigetdir();
params = LoadBrukerData(pth);


data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 



% First sort data in channels, in this case we have 4
data = reshape(data,[nextMultiple, params.EPIC_RFPulseNoExp * params.NLin * params.NPar]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,params.NCha,params.NLin,params.NPar,params.EPIC_RFPulseNoExp]);
% Permute into Read-Lines-Par-Cha-Rep
data = permute(data,[1 3 4 2 5]);
% FFT into imgs for each channel
imgs_cha = ifftcn(data,[1 2 3]);
imgs_rssq = squeeze(rssq(imgs_cha,4));




%% Load noise scan
pth_noise = uigetdir();
params_noise = LoadBrukerData(pth_noise);
noisedata = params_noise.data;
% First sort data in channels, in this case we have 4
noisedata = reshape(noisedata,[nextMultiple, params_noise.NRep * params_noise.NLin * params_noise.NPar]);
noisedata = noisedata(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
noisedata = reshape(noisedata,[params_noise.NCol,params_noise.NCha,params_noise.NLin,params_noise.NPar,params_noise.NRep]);
% Permute into Read-Lines-Par-Rep-Cha
noisedata = permute(noisedata,[1 3 4 5 2]);
% Vectorise into a read*lines*par*rep X Cha matrix
noisedata = reshape(noisedata,[params_noise.NCol*params_noise.NLin*params_noise.NPar*params_noise.NRep params_noise.NCha]);
% Permute to Cha x Samples matrix
noisedata  = permute(noisedata,[2 1]);

%% Create Noise covariance matrix
psi = 1/(size(noisedata,2) - 1) * (noisedata * noisedata');


figure; plot(squeeze(imgs_rssq(50,22,24,:)));

for c = 1:size(imgs_cha,5)
    recon(:,:,:,c) = adapt_array_recon(imgs_cha(:,:,:,:,c),psi);
end

save("Results\Walsh_31P","recon","psi","imgs_rssq");