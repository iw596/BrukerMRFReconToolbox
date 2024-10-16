%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
pth = "datasets\AFIData\7";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
imgs = ifftcn(data,[1 2 3]);
se = strel('disk', 20, 0);
BW = imbinarize(mat2gray(abs(imgs(:,:,:,1))));
BW = imclose(BW, se);
BW = imfill(BW, 'holes');
B1Map = AFIB1(imgs,60,20,100);
figure; imagesc(B1Map(:,:,16).*BW(:,:,16),[0.5 1.2])