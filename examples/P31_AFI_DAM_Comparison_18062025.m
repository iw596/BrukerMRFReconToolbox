addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")


params = LoadBrukerData("C:\Users\kpqv532\OneDrive - University of Leeds\20250616_120344_PhosphoricAcid_B1Mapping_16062025_1_4\19");
data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 
% First sort data
data = reshape(data,[nextMultiple,  params.NLin params.NPar params.NRep]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,params.NCha,params.NLin params.NPar,params.NRep]);
% Permute into Read-Lines-Par-Cha-Rep
data = permute(data,[1 3 4 2 5]);
data = data(:,:,:,:);
data = mean(data,5);
% FFT into imgs for each channel
imgs_45 = ifftcn(data,[1 2 3]);
imgs_45_rssq = rssq(imgs_45,4);

params = LoadBrukerData("C:\Users\kpqv532\OneDrive - University of Leeds\20250616_120344_PhosphoricAcid_B1Mapping_16062025_1_4\7");
data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 
% First sort data
data = reshape(data,[nextMultiple,  params.NLin params.NPar params.NRep]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,params.NCha,params.NLin params.NPar params.NRep]);
% Permute into Read-Lines-Par-Cha-Rep
data = permute(data,[1 3 4 2 5]);
data = data(:,:,:,:);

data = mean(data,5);

% FFT into imgs for each channel
imgs_90 = ifftcn(data,[1 2 3]);
imgs_90_rssq = rssq(imgs_90,4);

DAMB1 = acosd(imgs_90_rssq./(2.*imgs_45_rssq))./45;
DAMB1MapFiltered = medfilt3(abs(DAMB1),[3, 3, 1]);


for i = 1:4
    DAMB1MapCha(:,:,:,i) = acosd(abs(imgs_90(:,:,:,i))./(2.*abs(imgs_45(:,:,:,i))))./45;
end






pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250616_120344_PhosphoricAcid_B1Mapping_16062025_1_4\";
%files = ["27","28","29","30","31","32","33","34","35"];
files = ["9"];

fullPth = strcat(pth,files(1));
params = LoadBrukerData(fullPth);
data = params.data;


% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 

data = reshape(data,[nextMultiple, 2 * params.NLin * params.NPar*params.NRep]);
data = data(1:NLineSize,:); % Trim padding

% Reshape into Read-Cha-Echo-Lines-Par
data = reshape(data,[params.NCol,params.NCha,2,params.NLin,params.NPar params.NRep]);
% Permute into Read-Lines-Par-Cha-echo
data = permute(data,[1 4 5 2 3 6]);
data = data(:,:,:,:,:,:);
data = mean(data,6);

% FFT into imgs for each channel
imgs_cha = ifftcn(data,[1 2 3]);
AFIB1MapCha = [];
for i = 1:4
    AFIB1MapCha(:,:,:,i) = FitAFIB1(squeeze(abs(imgs_cha(:,:,:,i,:))),60,15,75);
end

imgs_rssq = squeeze(rssq(imgs_cha,4));




% figure;
% subplot(1,3,1); imagesc(imgs_rssq(:,:,24,1));
% subplot(1,3,2); imagesc(imgs_rssq(:,:,24,2));
% subplot(1,3,3); imagesc(imgs_rssq(:,:,24,1)./imgs_rssq(:,:,24,2));


AFIB1Map = FitAFIB1(imgs_rssq,60,params.TR,params.TR*params.AFIRatio);
AFIB1MapFiltered = medfilt3(AFIB1Map,[3, 3, 1]);

se = strel('disk', 20, 0);
mask = mean(imgs_rssq,4);
mask = imbinarize(mat2gray(abs(mask)));
mask = imclose(mask, se);
mask = imfill(mask, 'holes');


figure; imagesc(squeeze(AFIB1MapFiltered(45,:,:)));

%figure; imagesc(abs(rot90(squeeze(AFIB1MapFilterd(:,:,48)).*mask(:,:,49),-1)),[0.8 1]); axis square; 
colormap("turbo"); 
title("31P B1 Map")
colorbar;
%figure; imagesc(abs(squeeze(AFIB1MapFiltered(:,55,:))),[0.8 1]); axis square;
colormap("turbo")
DAMB1MapFiltered_masked  = DAMB1MapFiltered.*mask;
AFIB1MapFiltered_masked = AFIB1MapFiltered.*mask;
figure(70); 
imagesc(abs(squeeze(DAMB1(45,:,:))),[0.5 1.2]); colormap("turbo"); colorbar;title("Double Angle Method");axis image;

figure(71);
imagesc(abs(squeeze(AFIB1Map(45,:,:))),[0.5 1.2]); colormap("turbo");colorbar;title("AFI"); axis image;

idx = 25;  % Row index you want to analyze
% Do a profile plot
AFI_tmpImg = abs(squeeze(AFIB1MapFiltered_masked(45,:,:)));
AFI_profile = squeeze(AFI_tmpImg(idx,:));
DAM_tmpImg = abs(squeeze(DAMB1MapFiltered_masked(45,:,:)));
DAM_profile = squeeze(DAM_tmpImg(idx,:));


figure(10);
subplot(1,2,1);
imagesc(DAM_tmpImg, [0.5 1.2]); colormap("turbo");
hold on;
subplot(2,2,3);

figure(11);
subplot(1,2,1); 
imagesc(DAM_tmpImg, [0.5 1.2]); colormap("turbo");
line([1 size(DAM_tmpImg,2)], [idx idx], 'Color', 'r', 'LineWidth', 1);  % Draw horizontal red line
subplot(1,2,2);
plot(DAM_profile,'LineWidth',1.5); hold on; plot(AFI_profile,'LineWidth',1.5);
xlabel("Position","FontSize",12);
ylabel("B1 value","FontSize",12);
legend("DAM Profile","AFI Profile");

% Difference image

diffImg = DAM_tmpImg - AFI_tmpImg;
figure(12);
imagesc(diffImg); colormap("gray"); title("DAM-AFI");colorbar;

figure(13)
subplot(1,2,1);imagesc(abs(squeeze(DAMB1(45,:,:))),[0.5 1.2]); colormap("turbo"); colorbar;title("Double Angle Method");
subplot(1,2,2); imagesc(abs(squeeze(AFIB1Map(45,:,:))),[0.5 1.2]); colormap("turbo");colorbar;title("AFI")


%% Save Double-angle B1 map

sa