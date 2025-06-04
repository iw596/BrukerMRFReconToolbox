%% Script to reconstruction B1 Map using DAM method
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")

% Load 45 degree dataset
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250602_110808_MRF_Phantom_MRF_Dev_02062025_1_30\9";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,params.NLin,params.NPar params.NRep]);
DAMImgs = ifftcn(data,[1 2 3]);

alphaNom = 45;
DAMB1 = acosd(abs(DAMImgs(:,:,:,2))./(2*abs(DAMImgs(:,:,:,1))));
DAMB1 = DAMB1./alphaNom;



% Load AFI data
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250515_171014_MRF_Phantom_MRF_Phantom_b1mapping_1_25\20";
params = LoadBrukerData(pth);
AFIdata = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
AFIdata = permute(AFIdata, [1 3 4 2]);
AFIImgs = ifftcn(AFIdata,[1 2 3]);
AFIB1 =  FitAFIB1(AFIImgs,60,params.TR,params.TR * params.AFIRatio);
AFIB1_filt = medfilt3(abs(AFIB1),[5,5,5]);

figure; imagesc(abs(AFIB1_filt(:,:,64)),[0.5,1.1]);colormap("turbo")
