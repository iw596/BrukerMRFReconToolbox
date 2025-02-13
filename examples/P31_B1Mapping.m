%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")

pth = "C:\Users\kpqv532\OneDrive - University of Leeds\31PT1Data\20250207_150306_Phantom_PhosphoricAcid_Phantom_31P_B1Testin_1_1\";
%files = ["27","28","29","30","31","32","33","34","35"];
files = ["27","28"];


NFiles = size(files,2);
imgs = zeros([96,96,96,2,4]);
for i = 1:NFiles
    fullPth = strcat(pth,files(i));
    params = LoadBrukerData(fullPth);
    data = reshape(params.data,[params.NCol,4,2,params.NLin,params.NPar]);
    data = permute(data,[1 4 5 3 2]);
    data = ifftcn(data,[1 2 3]);
    imgs = imgs + data;
end
imgs = imgs./NFiles;

imgs = rssq(imgs,5);
figure;
subplot(1,3,1); imagesc(imgs(:,:,48,1));
subplot(1,3,2); imagesc(imgs(:,:,48,2));
subplot(1,3,3); imagesc(imgs(:,:,48,1)./imgs(:,:,48,2));

mask = imbinarize(mat2gray(abs(squeeze(imgs(:,:,:,1)))));
mask = imfill(mask, 'holes');


AFIB1Map = FitAFIB1(imgs,60,20,20*5);
AFIB1MapFiltered = medfilt3(AFIB1Map,[5, 5, 5]);


figure; imagesc(squeeze(AFIB1MapFiltered(:,53,:)));

%figure; imagesc(abs(rot90(squeeze(AFIB1MapFiltered(:,:,48)).*mask(:,:,49),-1)),[0.8 1]); axis square; 
colormap("turbo"); 
title("31P B1 Map")
colorbar;
%figure; imagesc(abs(squeeze(AFIB1MapFiltered(:,55,:))),[0.8 1]); axis square;
colormap("turbo")

