%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")

pth = "C:\Users\kpqv532\CODERepository\BrukerData\20250502_083210_Phantom_PhosphoricAcid_Phantom_PhosphoricA_1_14\";
%files = ["27","28","29","30","31","32","33","34","35"];
files = ["18"];

fullPth = strcat(pth,files(1));
params = LoadBrukerData(fullPth);
data = params.data;


% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 

data = reshape(data,[nextMultiple, 2 * params.NLin * params.NPar]);
data = data(1:NLineSize,:); % Trim padding

% Reshape into Read-Cha-Echo-Lines-Par
data = reshape(data,[params.NCol,params.NCha,2,params.NLin,params.NPar]);
% Permute into Read-Lines-Par-Cha-echo
data = permute(data,[1 4 5 2 3]);
% FFT into imgs for each channel
imgs_cha = ifftcn(data,[1 2 3]);
imgs_rssq = squeeze(rssq(imgs_cha,4));

figure;
subplot(1,3,1); imagesc(imgs_rssq(:,:,24,1));
subplot(1,3,2); imagesc(imgs_rssq(:,:,24,2));
subplot(1,3,3); imagesc(imgs_rssq(:,:,24,1)./imgs_rssq(:,:,24,2));

mask = imbinarize(mat2gray(abs(squeeze(imgs(:,:,:,1)))));
mask = imfill(mask, 'holes');


AFIB1Map = FitAFIB1(imgs_rssq,60,20,20*5);
AFIB1MapFiltered = medfilt3(AFIB1Map,[3, 3, 3]);


figure; imagesc(squeeze(AFIB1MapFiltered(:,24,:)));

%figure; imagesc(abs(rot90(squeeze(AFIB1MapFiltered(:,:,48)).*mask(:,:,49),-1)),[0.8 1]); axis square; 
colormap("turbo"); 
title("31P B1 Map")
colorbar;
%figure; imagesc(abs(squeeze(AFIB1MapFiltered(:,55,:))),[0.8 1]); axis square;
colormap("turbo")

