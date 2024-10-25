%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
%pth = "datasets\MRFDataset1\AFI_Exp7";
pth = "datasets\AFIData\9"
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
% Zero pad data
imgs = ifftcn(data,[1 2 3]);
se = strel('disk', 20, 0);
%BW = imbinarize(mat2gray(abs(mean(imgs,3))),0.1);
%BW = imclose(BW, se);
%BW = imfill(BW, 'holes');
AFIB1Map = AFIB1(imgs,60,20,100);
figure; imagesc(squeeze(AFIB1Map(:,:,40)),[0.9,1.2]); axis square;