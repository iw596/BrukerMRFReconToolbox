addpath(genpath("./."))
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

RFDurs = linspace(params.EPICB1Map.RFPulseStart,params.EPICB1Map.RFPulseEnd,params.EPIC_RFPulseNoExp);
gamma = 17.24e6;  % Gyromagnetic ratio of 31P in Hz/T
% Calculate B1 from reference power
refpow = params.RefPow;
refvolt = sqrt(refpow.^2/50);
% Calculate B1 for 1ms, 90 degree block pulse
refB1 = (pi/2)/(2*pi*gamma*1e-3);
% Starting FA is 90 degrees, therefore we just need to scale by extra
% duration
FA = (pi/2).*RFDurs./(RFDurs(1));

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
    tmp = permute(squeeze(imgs_cha(:,:,:,:,c)),[4,1,2,3]);
    [im, cmap, wfull] = openadapt(tmp, false, psi, [], 1, 'noMessage');
    recon(:,:,:,c) = im;
end

% Pin phase to second value

ttt = recon .* exp(-1j.*angle(recon(:,:,:,1)));


size(recon)

figure(1);
montage(mat2gray(ang(squeeze(recon(:,:,24,:))))); title("Adaptive Recon");

figure(2);
montage(mat2gray(abs(squeeze(ttt(:,:,24,:))))); title("RSSQ Recon");

figure(15); 
subplot(3,1,1); plot(abs(squeeze(recon(45,24,24,:)))); title("Magnitude");
subplot(3,1,2); plot(abs(real(squeeze(recon(45,24,24,:))))); title("Real");
subplot(3,1,3); plot(abs(imag(squeeze(recon(45,24,24,:))))); title("Imag");

figure(16); 
subplot(3,1,1); plot(abs(squeeze(ttt(45,24,24,:)))); title("Magnitude");
subplot(3,1,2); plot((real(squeeze(ttt(45,24,24,:))))); title("Real");
subplot(3,1,3); plot((imag(squeeze(ttt(45,24,24,:))))); title("Imag");


save("Results\Walsh_31P","recon","psi","imgs_rssq");