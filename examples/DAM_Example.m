%% Script to reconstruction B1 Map using DAM method
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")

% Load 45 degree dataset
pth = "datasets\DAM_B1_Data\38";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,params.NLin,params.NPar]);
DAMImg1 = ifftcn(data,[1 2 3]);

% Load 90 degree dataset
pth = "datasets\DAM_B1_Data\39";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,params.NLin,params.NPar]);
DAMImg2 = ifftcn(data,[1 2 3]);

B1= DAMB1(DAMImg1,DAMImg2,45);
figure; imagesc(abs(B1(:,:,64)), [1,1.5]);


% Load AFI data
pth = "datasets\20241101_185137_TubeArray_ISMRMDatv2_1_2\AFI_29";
params = LoadBrukerData(pth);
AFIdata = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
AFIdata = permute(AFIdata, [1 3 4 2]);
AFIImgs = ifftcn(AFIdata,[1 2 3]);
AFIB1 =  FitAFIB1(AFIImgs,60,params.TR,params.TR * params.AFIRatio);
figure; imagesc(medfilt2(abs(AFIB1(:,:,15)),[5 5]), [0.9,1.1]);
