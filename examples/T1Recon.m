addpath("FileIO\");
addpath("Simulations\");
addpath("Fitting\");



pth = "datasets/64/pdata/1/2dseq";
params = LoadBrukerData("datasets/64");
fid = fopen(pth);
data = fread(fid,"int16");
data = reshape(data,[128 128 31]);
fclose(fid);

%% Generate Mask from first inversion time
se = strel('disk', 10, 0);
BW = imbinarize(mat2gray(data(:,:,1)));
BW = imclose(BW, se);
BW = imfill(BW, 'holes');


maps = T1Fitting(data,params.InvTimes,BW);

%% Perform T2 fitting on MSME data
pth = "datasets/65/pdata/1/2dseq";
params = LoadBrukerData("datasets/65");
fid = fopen(pth);
data = fread(fid,"int16");
data = reshape(data,[128 128 20]);
fclose(fid);
T2map = T2Fitting(data,params.MSMETimes,BW);
figure(3); imagesc(T2map)