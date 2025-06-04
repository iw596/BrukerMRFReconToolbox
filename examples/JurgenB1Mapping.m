addpath(genpath("./."))
%% Load 31P data
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250523_141105_Phantom_PhosphoricAcid_B1_Mapping_23052025_1_15\11";
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

RFDurs = linspace(params.EPICB1Map.RFPulseStart,params.EPICB1Map.RFPulseEnd,params.EPIC_RFPulseNoExp);
FA = (pi/2).*RFDurs./(RFDurs(1));

%% Load noise scan
pth_noise = "C:\Users\kpqv532\OneDrive - University of Leeds\20250523_141105_Phantom_PhosphoricAcid_B1_Mapping_23052025_1_15\8";
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
    tmp = permute(squeeze(imgs_cha(:,:,:,:,c)),[4,1,2,3]);
    [im, cmap, wfull] = openadapt(tmp, true, psi, [], 1, 'noMessage');
    recon(:,:,:,c) = im;
end

% Pin phase to second value

ttt = recon .* exp(-1j.*angle(recon(:,:,:,2)));


size(recon)

figure(14);
montage(mat2gray(abs(squeeze(recon(:,:,24,:))))); title("Adaptive Recon");

figure(2);
montage(mat2gray(abs(squeeze(ttt(:,:,24,:))))); title("RSSQ Recon");

figure(15); 
subplot(3,1,1); plot(abs(squeeze(imgs_rssq(45,24,24,:)))); title("Magnitude");
subplot(3,1,2); plot(abs(real(squeeze(imgs_rssq(45,24,24,:))))./max(abs(real(squeeze(imgs_rssq(45,24,24,:)))))); title("Real");hold on; plot(sin(FA))
subplot(3,1,3); plot(abs(imag(squeeze(imgs_rssq(45,24,24,:))))); title("Imag");

figure(16); 
subplot(3,1,1); plot(rad2deg(FA),abs(squeeze(ttt(45,24,24,:)))); title("Magnitude");
subplot(3,1,2); plot(rad2deg(FA),(real(squeeze(ttt(45,24,24,:))))); title("Real");
subplot(3,1,3); plot(rad2deg(FA),(imag(squeeze(ttt(45,24,24,:))))); title("Imag");


save("Results\Walsh_31P","recon","psi","imgs_rssq");