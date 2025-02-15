%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")



pth = "datasets\20250211_141529_IW_Phantom_NiCl2_MRF_Dev_11_02_2025_1_5\40";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
imgs = ifftcn(data,[1 2 3]);
AFIB1Map = FitAFIB1(imgs,60,20,20*5);
AFIB1MapFiltered = medfilt3(AFIB1Map,[3, 3, 1]);
figure; imagesc(abs(squeeze(AFIB1MapFiltered(:,:,32))),[0.5 1.2]); axis square;
colormap("turbo")

