%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")



pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250718_133850_MRF_Phantom_3dMRFDev_v2_18072025_1_36\14";
params = LoadBrukerData(pth);
nextMultiple = 128 * ceil((params.NCol) / 128);
padding = nextMultiple - params.NCol;
data = params.data;
data = reshape(data,[nextMultiple,2,params.NLin,params.NPar]);
data = data(1:params.NCol,:,:);
data = reshape(data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
imgs = ifftcn(data,[1 2 3]);
AFIB1Map = FitAFIB1(imgs,60,20,20*5);
AFIB1MapFiltered = medfilt3(AFIB1Map,[1, 1, 1]);
figure; imagesc(abs(squeeze(AFIB1MapFiltered(:,:,params.NPar/2))),[0.5 1.2]); axis square;
colormap("turbo")

