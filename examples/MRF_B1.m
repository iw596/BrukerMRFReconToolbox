%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")

pth = "datasets\MRFDataset1\AFI_Exp7";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
imgs = ifftcn(data,[1 2 3]);
AFIB1Map = AFIB1(imgs,60,20,100);
figure(1); imagesc(squeeze(AFIB1Map(:,:,16))); axis square;


%%%% Now load and reconstruct Bruker MRF data
pth = "datasets\MRFDataset1\MRF_Exp28";
params = LoadBrukerData(pth);


%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
FA = ReadFAList("datasets\MRFFAPattern.txt");
rawdata = reshape(rawdata, [params.NCol length(FA) params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
imgs = ifftcn(rawdata,[1 2]);
figure(2); montage(mat2gray(abs(imgs)));
figure(3); plot(abs(squeeze(imgs(64,32,:))));

se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)));
mask = imclose(mask, se);
mask = imfill(mask, 'holes');


% Normalise Dictionary
normalisedDict = [];
cnt=length(dict);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(c,:).*conj(dict(c,:))));
    normalisedDict(c,:) = dict(c,:) / scaleFactor;
end



% Iterate through each voxel
parfor i = 1:128
    i
    for j = 1:64
       % Find closest B1 value in LUT and restrict dictionary search to this area
       measuredB1Val = squeeze(AFIB1Map(i,j,16));
       [val,idx] = min(abs(measuredB1Val-squeeze(LUT(:,3))));
       closestB1 = LUT(idx,3);
       idx=find(LUT(:,3) == closestB1);
       subDict = normalisedDict(idx,:);
       subLUT = LUT(idx,:)
       % for k = 1:size(mrfsignal, 3)
       scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
       normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
       inner_product=abs(subDict*squeeze(normalized_mrfsignal));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       matched_indices(i, j) = max_index;
       T1Map(i,j) = subLUT(max_index,1);
       T2Map(i,j) = subLUT(max_index,2);
       B1Map(i,j) = subLUT(max_index,3);
       MRFMask(i,j) = 1;

    end
end
