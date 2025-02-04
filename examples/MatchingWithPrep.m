addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")


%% Open bruker MRF dataset
%pth = "datasets\MRF_ISMRM_Dataset\17";
pth = "datasets\LowFATesting\45";
params = LoadBrukerData(pth);



%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
%[FA,TR] = ReadMRFList("datasets\MRFPattern.txt");
[FA,~] = ReadMRFList("datasets\LowFATesting\MRFPattern.txt");
rawdata = reshape(rawdata, [params.NCol length(FA) * 8 params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
imgs = fftcn(rawdata,[1 2]);

%% Create binary mask from mean of images
se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)));


% Normalise Dictionary
normalisedDict = zeros(size(dict));

cnt=size(dict,2);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(:,c).*conj(dict(:,c))));
    normalisedDict(:,c) = dict(:,c) / scaleFactor;
end

% Iterate through each voxel
parfor i = 1:128
    i
    for j = 1:128

       scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
       normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
       inner_product=abs(squeeze(normalized_mrfsignal)'* (normalisedDict));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       T1Map(i,j) = LUT(max_index,1);
       T2Map(i,j) = LUT(max_index,2);
       MRFMask(i,j) = 1;
       dotProductMaximums(i,j) = maxValue;

    end
end

%% Load reference maps

%% Load T1 FAIR RARE
pth = "datasets\LowFATesting\47";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol 64 params.NInv]);
fclose(fid);
T1RefMap = T1Fitting(data,params.InvTimes);


figure(1); 
subplot(1,2,1); imagesc(T1Map.*mask,[0,400]); colormap("turbo"); colorbar; title("MRF T1 Map")
subplot(1,2,2); imagesc(flip(flip(T1RefMap,1),2),[0,400]); colormap("turbo"); colorbar; title("Ref T1 Map")


figure(2); imagesc(T2Map.*mask); colormap("turbo"); colorbar; title("MRF T2 Map")