addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")
addpath("FileIO\")

pth = "datasets\MRF_IWFISP";
params = LoadBrukerData(pth);
FA = ReadMRFList("datasets\MRFPattern.txt");
plot(FA);
rawdata  = params.data;
rawdata = reshape(rawdata, [params.NCol length(FA) params.NLin]);
rawdata = permute(rawdata, [1 3 2]);


% FT ( tabdile raw data be image)
imgs = ifftcn(rawdata,[1 2]);

% belafaseleh image ro mitoonim bebinim
figure(2); montage(mat2gray(abs(imgs)));
figure(3); plot(abs(squeeze(imgs(64,64,:))));

% matching process
%% Create binary mask from mean of images
se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)));
%mask = imclose(mask, se);
%mask = imfill(mask, 'holes');
figure;imshow(mask)

% Normalise Dictionary
normalisedDict = [];

cnt=size(dict,1);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(c,:).*conj(dict(c,:))));
    normalisedDict(c,:) = dict(c,:) / scaleFactor;
    %normalisedDict(c,:) =  dict(c,:)./norm(squeeze( dict(c,:)));
end
% Iterate through each voxel
parfor i = 1:128
    i
    for j = 1:128
       % for k = 1:size(mrfsignal, 3)
       scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
       normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
       %normalized_mrfsignal = (imgs(i,j,:))/scaleFactor;
       %normalized_mrfsignal = squeeze(imgs(i,j,:)./norm(squeeze(imgs(i,j,:))));
       inner_product=abs((normalisedDict)*(squeeze(normalized_mrfsignal)));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       T1Map(i,j) = LUT(max_index,1);
       T2Map(i,j) = LUT(max_index,2);
       B1Map(i,j) = LUT(max_index,3);
       MRFMask(i,j) = 1;
       dotProductMaximums(i,j) = maxValue;

    end
end