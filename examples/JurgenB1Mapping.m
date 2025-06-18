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

figure(5);
subplot(4,1,1); plot(squeeze(real(imgs_cha(45,24,24,4,:))));
subplot(4,1,2); plot(squeeze(imag(imgs_cha(45,24,24,4,:))));
subplot(4,1,3); plot(squeeze(abs(imgs_cha(45,24,24,4,:)./imgs_cha(45,24,24,4,1) )  ) );
subplot(4,1,4); plot(sin(FA + pi)); hold on;  plot(sin(FA + pi).^2); 






imgs_rssq = squeeze(rssq(imgs_cha,4));


DAMB1 = acosd(imgs_rssq(:,:,:,4)./(2.*imgs_rssq(:,:,:,9)))./78;

RFDurs = linspace(params.EPICB1Map.RFPulseStart,params.EPICB1Map.RFPulseEnd,params.EPIC_RFPulseNoExp);
FA = (pi/2).*(RFDurs/1000)./params.ExcRFDur;

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
%noisedata  = permute(noisedata,[2 1]);


dmtx = ismrm_calculate_noise_decorrelation_mtx(noisedata);
%
%% Create Noise covariance matrix
psi = 1/(size(noisedata,2) - 1) * (noisedata * noisedata');

 
figure; plot(squeeze(imgs_rssq(45,24,24,:)));
tmp_decor = [];
for i = 1:20
    tmp_decor(:,:,:,:,i) =  ismrm_apply_noise_decorrelation_mtx(imgs_cha(:,:,:,:,i), dmtx);
end


tmp = permute(squeeze(tmp_decor(:,:,:,:,2)),[4,1,2,3]);
[im, cmap, wfull] = openadapt(tmp, true, psi, [], 1, 'noMessage');

ccm_walsh = permute(cmap, [2 3 4 1]);
im_walsh = [];
for i = 1:20
    im_walsh(:,:,:,i) = sum(conj(ccm_walsh).*tmp_decor(:,:,:,:,i),4)./sum(ccm_walsh.*conj(ccm_walsh),4);
end
im_walsh = abs(sum(tmp_decor .* ccm_walsh, 4));
im_walsh = squeeze(im_walsh);

for c = 1:size(imgs_cha,5)
    tmp = permute(squeeze(imgs_cha(:,:,:,:,c)),[4,1,2,3]);
    recon(:,:,:,c) = im;
end

tmp = squeeze(recon(45,24,20,:));
[~,idx] = max(abs(tmp));
% Pin phase to second value
ttt = tmp;%.* exp(1j.*angle(tmp(idx)));


size(recon)

figure(14);
montage(mat2gray(real(squeeze(recon(:,:,24,:))))); title("Adaptive Recon");

figure(2);
montage(mat2gray(abs(squeeze(imgs_rssq(:,:,24,:))))); title("RSSQ Recon");

figure(15); 
subplot(3,1,1); plot(abs(squeeze(imgs_rssq(30,24,43,:)))./max(abs(squeeze(imgs_rssq(30,24,43,:))))); title("Magnitude");title("Real");hold on; plot(sin(FA))
subplot(3,1,2); plot(abs(real(squeeze(imgs_rssq(45,24,24,:))))./max(abs(real(squeeze(imgs_rssq(45,24,24,:)))))); title("Real");hold on; plot(sin(FA).^2)
subplot(3,1,3); plot(abs(imag(squeeze(imgs_rssq(45,24,24,:))))); title("Imag");

figure(16); 
subplot(4,1,1); plot(abs(tmp)./max(abs(tmp))); title("Magnitude");
subplot(4,1,2);hold on; plot(rad2deg(FA),squeeze(real(im_walsh(45,28,23,:))));
subplot(4,1,3);hold on; plot(rad2deg(FA),squeeze(imag(im_walsh(45,28,23,:))));
subplot(4,1,4); plot(sin(2.3.*FA).^2);
%subplot(3,1,3); plot(rad2deg(FA),imag(tmp)); title("Imag");

%% Fit sin to pixel
%y =squeeze((im_walsh(45,24,24,:)));
%y = abs(y./y(1));
y = squeeze(imgs_cha(45,24,24,1,:));
y = abs(y./y(1));
% Sine model function
%sineFunc = @(params, x) (params(1).*sin(params(2).*x + params(3)) + params(4)).^2; 
sineFunc = @(params) abs(sin(params(1).*FA.' + params(2))./sin(params(1).*FA(1) + params(2))) - y;
% Estimate amplitude and offset
%A0 = max(y)/2;
%D0 = 1;
% Initial guess: [A, B, C, D]
%initParams = [A0, 1, 0, D0];

% Bounds: [A, B, C, D]
%lb = [0, 0, -Inf, -Inf];  % B must be ≥ 0
%ub = [ Inf, Inf, Inf, Inf];


initParams = [1,0];
% Fit the parameters
paramsFit = lsqnonlin(sineFunc, initParams);




% Plot result

fittedY = sineFunc(paramsFit);
figure(70)
plot(FA, y, 'x-', FA, fittedY, 'r-')
legend('Data', 'Fitted Sine Curve')
title('Sine Fit Using lsqcurvefit')
xlabel('x'), ylabel('y')


save("Results\Walsh_31P","recon","psi","imgs_rssq");