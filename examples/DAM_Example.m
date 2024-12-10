%% Script to reconstruction B1 Map using DAM method
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")

% Load 30 degree dataset
pth = "datasets\20241205_164758_NaClPhantom_IW_NaCl_05122024_1_5\3";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,params.NLin,params.NPar]);
DAMImg1 = ifftcn(data,[1 2 3]);

% Load 90 degree dataset
pth = "datasets\20241205_164758_NaClPhantom_IW_NaCl_05122024_1_5\4";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,params.NLin,params.NPar]);
DAMImg2 = ifftcn(data,[1 2 3]);

B1= DAMB1(DAMImg1,DAMImg2);
figure; imagesc(B1(:,:,32)./60, [0.9,1.1]);


% Load AFI data
pth = "datasets\20241205_164758_NaClPhantom_IW_NaCl_05122024_1_5\20";
params = LoadBrukerData(pth);
AFIdata = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
AFIdata = permute(AFIdata, [1 3 4 2]);
AFIImgs = ifftcn(AFIdata,[1 2 3]);
AFIB1 =  FitAFIB1(AFIImgs,60,params.TR,params.TR * params.AFIRatio);
figure; imagesc(abs(AFIB1(:,:,32)), [0.9,1.1]);
