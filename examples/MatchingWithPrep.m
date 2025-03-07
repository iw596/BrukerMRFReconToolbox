addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")


%% Open bruker MRF dataset
%pth = "datasets\MRF_ISMRM_Dataset\17";
pth = "datasets\20250225_122413_MRF_Phantom_MRF_PhantomDev_25022028v2_1_7/6/";
params = LoadBrukerData(pth);



%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
%[FA,TR] = ReadMRFList("datasets\MRFPattern.txt");
[FA,~] = ReadMRFList("datasets\20250211_141529_IW_Phantom_NiCl2_MRF_Dev_11_02_2025_1_5\MRFPattern.txt");
rawdata = reshape(rawdata, [params.NCol length(FA)*8 params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
imgs = ifftcn(rawdata,[1 2]);
figure(1); plot(FA); title("Flip Angle Pattern");
%% Create binary mask from mean of images
se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)),);


% Normalise Dictionary
normalisedDict = zeros(size(dict));

cnt=size(dict,2);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(:,c).*conj(dict(:,c))));
    normalisedDict(:,c) = dict(:,c) / scaleFactor;
end
T1Map = [];
T2Map = [];
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


%% Load T1 FAIR RARE
pth = "datasets\20250211_141529_IW_Phantom_NiCl2_MRF_Dev_11_02_2025_1_5\33";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol 128 params.NInv]);
fclose(fid);
T1RefMap = T1Fitting(data,params.InvTimes);

%% Load T2 MSME
pth = "datasets\20250211_141529_IW_Phantom_NiCl2_MRF_Dev_11_02_2025_1_5\34";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol 128 params.NEcho]);
T2RefMapMask = imbinarize(mat2gray(data));
T2RefMapMask = T2RefMapMask(:,:,1);
fclose(fid);
T2RefMap = T2Fitting(data,params.MSMETimes);

figure(2); 
subplot(1,2,1); imagesc(T1Map,[0,2500]); colormap("turbo"); colorbar; title("MRF T1 Map")
subplot(1,2,2); imagesc(T1RefMap,[0,2500]); colormap("turbo"); colorbar; title("Ref T1 Map")

figure(3); 
subplot(1,2,1);imagesc(T2Map,[0,500]); colormap("turbo"); colorbar; title("MRF T2 Map"); axis square;
subplot(1,2,2);imagesc(T2RefMap,[0,500]); colormap("turbo"); colorbar; title("Ref T2 Map"); axis image;