%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")



pth = "datasets\Yasaman_MRF10122024\14";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
imgs = ifftcn(data,[1 2 3]);
AFIB1Map = FitAFIB1(imgs,60,20,20*5);
AFIB1MapFiltered = medfilt3(AFIB1Map,[5, 5, 1]);
figure; imagesc(abs(squeeze(AFIB1MapFiltered(:,:,24)).*mask(:,:,24)),[0.8 1.2]); axis square;
colormap("turbo")

