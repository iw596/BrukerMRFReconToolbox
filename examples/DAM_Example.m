%% Script to reconstruction B1 Map using DAM method
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")

% Load 45 degree dataset
pth = "datasets\MRF_17122024\DAM_FLASH45";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,params.NLin,params.NPar]);
DAMImg1 = ifftcn(data,[1 2 3]);

% Load 90 degree dataset
pth = "datasets\MRF_17122024\DAM_FLASH90";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,params.NLin,params.NPar]);
DAMImg2 = ifftcn(data,[1 2 3]);

B1= DAMB1(DAMImg1,DAMImg2,45);
figure; imagesc(abs(B1(:,:,32)), [0.9,1.1]); colormap("turbo")


% Load AFI data
pth = "datasets\Yasaman_MRF10122024\14";
params = LoadBrukerData(pth);
AFIdata = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
AFIdata = permute(AFIdata, [1 3 4 2]);
AFIImgs = ifftcn(AFIdata,[1 2 3]);

%% Create binary mask from mean of images
se = strel('disk', 20, 0);
AFIMask = mean(AFIImgs,4);
AFIMask = imbinarize(mat2gray(abs(AFIMask)));
AFIMask = imclose(AFIMask, se);
AFIMask = imfill(AFIMask, 'holes');

AFIB1 =  FitAFIB1(AFIImgs,60,params.TR,params.TR * params.AFIRatio,[5,5]);
AFIB1 = medfilt3(AFIB1,[5 5 1]);
figure; imagesc(medfilt2(abs(AFIB1(:,:,24)).*AFIMask(:,:,24),[5 5]), [0.8 1.2]); colormap("turbo")
