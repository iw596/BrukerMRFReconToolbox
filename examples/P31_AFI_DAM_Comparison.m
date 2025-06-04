addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")


params = LoadBrukerData("C:\Users\isaac\OneDrive - University of Leeds\20250603_154005_PhosphoricAcid_b1mapping_1_2\5");
data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 
% First sort data
data = reshape(data,[nextMultiple,  params.NLin params.NPar]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,params.NCha,params.NLin params.NPar]);
% Permute into Read-Lines-Par-Cha-Rep
data = permute(data,[1 3 4 2]);
% FFT into imgs for each channel
imgs_45 = ifftcn(data,[1 2 3]);
imgs_45_rssq = rssq(imgs_45,4);

params = LoadBrukerData("C:\Users\isaac\OneDrive - University of Leeds\20250603_154005_PhosphoricAcid_b1mapping_1_2\6");
data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 
% First sort data
data = reshape(data,[nextMultiple,  params.NLin params.NPar]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,params.NCha,params.NLin params.NPar]);
% Permute into Read-Lines-Par-Cha-Rep
data = permute(data,[1 3 4 2]);
% FFT into imgs for each channel
imgs_90 = ifftcn(data,[1 2 3]);
imgs_90_rssq = rssq(imgs_90,4);

DAMB1 = acosd(imgs_90_rssq./(2.*imgs_45_rssq))./45;
DAMB1MapFiltered = medfilt3(abs(DAMB1),[3, 3, 1]);









pth = "C:\Users\isaac\OneDrive - University of Leeds\20250603_154005_PhosphoricAcid_b1mapping_1_2\";
%files = ["27","28","29","30","31","32","33","34","35"];
files = ["8"];

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

% figure;
% subplot(1,3,1); imagesc(imgs_rssq(:,:,24,1));
% subplot(1,3,2); imagesc(imgs_rssq(:,:,24,2));
% subplot(1,3,3); imagesc(imgs_rssq(:,:,24,1)./imgs_rssq(:,:,24,2));



AFIB1Map = FitAFIB1(imgs_rssq,60,params.TR,params.TR*5);
AFIB1MapFiltered = medfilt3(AFIB1Map,[3, 3, 1]);


figure; imagesc(squeeze(AFIB1MapFiltered(:,24,:)));

%figure; imagesc(abs(rot90(squeeze(AFIB1MapFiltered(:,:,48)).*mask(:,:,49),-1)),[0.8 1]); axis square; 
colormap("turbo"); 
title("31P B1 Map")
colorbar;
%figure; imagesc(abs(squeeze(AFIB1MapFiltered(:,55,:))),[0.8 1]); axis square;
colormap("turbo")


figure; imagesc(abs(squeeze(DAMB1MapFiltered(24,:,:))),[0.5 1.2]); colormap("turbo")
figure; imagesc(abs(squeeze(AFIB1MapFiltered(24,:,:))),[0.5 1.2]); colormap("turbo")
