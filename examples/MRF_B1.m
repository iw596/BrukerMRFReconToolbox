%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")

pth = "datasets\20250324_111056_MRF_Phantom_MRF_Dev_24052025_1_14\13";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
imgs = ifftcn(data,[1 2 3]);
AFIB1Map = FitAFIB1(imgs,60,20,20*5);


%%%% Now load and reconstruct Bruker MRF data
pth = "datasets/20250324_111056_MRF_Phantom_MRF_Dev_24052025_1_14/11";
params = LoadBrukerData(pth);


%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
rawdata = reshape(rawdata, [params.NCol params.NPointsPerPrep * params.MRFNPrepModules params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
imgs = ifftcn(rawdata,[1 2]);

se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)));
mask = imclose(mask, se);
mask = imfill(mask, 'holes');


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

            % Find closest B1 value in LUT and restrict dictionary search to this area
            measuredB1Val = squeeze(testB1(i,j));
            [val,idx] = min(abs(1-squeeze(LUT(:,3))));
            closestB1 = LUT(idx,3);
            idx=find(LUT(:,3) == closestB1);
            subDict = normalisedDict(:,idx);
            subLUT = LUT(idx,:);
            % for k = 1:size(mrfsignal, 3)
            scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
            normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
            inner_product=abs(squeeze(normalized_mrfsignal)'* (subDict));
            % Find best matching pattern
            [maxValue, max_index] = max(abs(inner_product));
            matched_indices(i, j) = max_index;
            T1Map(i,j) = subLUT(max_index,1);
            T2Map(i,j) = subLUT(max_index,2);
            B1Map(i,j) = subLUT(max_index,3);
            MRFMask(i,j) = 1;
            indexMap(i,j) = max_index;
 
    end
end


T1MRFMean = mean(nonzeros(T1Map.*mask))
T1MRFStd = T1Map.*mask;
T1MRFStd(T1MRFStd==0) = nan; % Set to nan wherever there is a 0.
T1MRFStd = std(T1MRFStd, 0, 'all', 'omitnan'); % Compute st dev along the third dimension, ignoring nans.

T2MRFMean = mean(nonzeros(T2Map.*mask))
T2MRFStd = T2Map.*mask;
T2MRFStd(T2MRFStd==0) = nan; % Set to nan wherever there is a 0.
T2MRFStd = std(T2MRFStd, 0, 'all', 'omitnan'); % Compute st dev along the third dimension, ignoring nans.

