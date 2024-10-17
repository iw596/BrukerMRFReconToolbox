addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")


%% Open bruker MRF dataset
pth = "datasets\MRF\29";
params = LoadBrukerData(pth);



%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
FA = ReadFAList("datasets\MRFFAPattern.txt");

rawdata = reshape(rawdata, [params.NCol length(FA) params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
imgs = ifftcn(rawdata,[1 2]);

figure(1); montage(mat2gray(abs(imgs)));
figure(2);plot(abs(squeeze(imgs(64,32,:))));
%figure(2); imshow(abs(imgs(:,:,300)),[])


%% Create binary mask from mean of images
se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)));
mask = imclose(mask, se);
mask = imfill(mask, 'holes');


% Normalise Dictionary
normalisedDict = [];
cnt=length(dict);
for c = 1:cnt  
    scaleFactor = sqrt(sum(dict(c,:).*conj(dict(c,:))));
    normalisedDict(c,:) = dict(c,:) / scaleFactor;
end

% Iterate through each voxel
for i = 1:128
    for j = 1:64
       % for k = 1:size(mrfsignal, 3)
       scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
       normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
       inner_product=abs(normalisedDict*squeeze(normalized_mrfsignal));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       matched_indices(i, j) = max_index;
       T1Map(i,j) = LUT(max_index,1);
       T2Map(i,j) = LUT(max_index,2);
       B1Map(i,j) = LUT(max_index,3);
       MRFMask(i,j) = 1;

    end
end

figure(3);
subplot(1,2,1); imagesc(T1Map.*mask); axis square;
subplot(1,2,2); imagesc(T2Map.*mask); axis square;

%% Load T1 FAIR RARE
pth = "datasets\22";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol 64 params.NInv]);
fclose(fid);
T1RefMap = T1Fitting(data,params.InvTimes);


%% Load T2 MSME
pth = "datasets\21";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[128 params.NLin params.NEcho]);
fclose(fid);
T2RefMap = T2Fitting(data,params.MSMETimes);





figure(10);
subplot(1,3,1);imagesc(T1RefMap.*mask); title("Reference T1 Map"); axis square;
subplot(1,3,2);imagesc(T1Map.*mask);  title("MRF T1 Map"); axis square;
subplot(1,3,3);imagesc((T1Map - T1RefMap).*mask); title("Difference Map"); axis square;


figure(11);
subplot(1,3,1);imagesc(T2RefMap.*mask); title("Reference T2 Map"); axis square;
subplot(1,3,2);imagesc(T2Map.*mask);  title("MRF T2 Map"); axis square;
subplot(1,3,3);imagesc((T2Map - T2RefMap).*mask); title("Difference Map"); axis square;


figure(12);
imagesc(B1Map.*mask); title("Reference B1 Map"); axis square;




