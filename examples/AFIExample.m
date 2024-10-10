%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
pth = "datasets\AFIData\19";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
imgs = ifftcn(data,[1 2 3]);

B1Map = AFIB1(imgs,60,20,100);