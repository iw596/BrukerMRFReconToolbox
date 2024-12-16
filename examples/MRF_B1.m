%% Example of B1 mapping using Actual Flip Angle technqiue
addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")

pth = "datasets\Yasaman_MRF10122024\14";
params = LoadBrukerData(pth);
AFIdata = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
AFIdata = permute(AFIdata, [1 3 4 2]);
AFIImgs = ifftcn(AFIdata,[1 2 3]);

%% Create binary mask from mean of images
se = strel('disk', 20, 0);
AFIMask = mean(AFIImgs,4);
AFIMask = imbinarize(mat2gray(abs(AFIMask)));
AFIMask = imclose(AFIMask, se);
AFIMask = imfill(AFIMask, 'holes');

AFIB1 =  FitAFIB1(AFIImgs,60,params.TR,params.TR * params.AFIRatio);
AFIB1 = medfilt3(AFIB1,[5 5 1]);
figure; imagesc(medfilt2(abs(AFIB1(:,:,24)).*AFIMask(:,:,24),[5 5]), [0.8 1.2]); colormap("turbo")

%% Open bruker MRF dataset
%pth = "datasets\MRF_ISMRM_Dataset\17";
pth = "datasets\Yasaman_MRF10122024\MRF_IWFISP";
params = LoadBrukerData(pth);



%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
%[FA,TR] = ReadMRFList("datasets\MRFPattern.txt");
[FA,~] = ReadMRFList("datasets\Yasaman_MRF10122024\MRFPattern.txt");
rawdata = reshape(rawdata, [params.NCol length(FA) params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
imgs = ifftcn(rawdata,[1 2]);
%imgs = fftshift(fft2((rawdata)));
figure; imagesc(abs(mean(imgs,3)));
figure(1); montage(mat2gray(abs(imgs)));
figure(2);plot(abs(squeeze(imgs(64,64,:))));
%figure(2); imshow(abs(imgs(:,:,300)),[])


%% Create binary mask from mean of images
se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)));
mask = imclose(mask, se);
mask = imfill(mask, 'holes');% Normalise Dictionary
normalisedDict = [];
cnt=length(dict);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(c,:).*conj(dict(c,:))));
    normalisedDict(c,:) = dict(c,:) / scaleFactor;
end


AFIB1Resized = imresize(AFIB1(:,:,24),[128,128]);
% Iterate through each voxel
parfor i = 1:128
    i
    for j = 1:128
        if (mask(i,j) == 1)
            % Find closest B1 value in LUT and restrict dictionary search to this area
            measuredB1Val = AFIB1Resized(i,j);
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
        else
            T1Map(i,j) = 0;
            T2Map(i,j) = 0;
            B1Map(i,j) = 0;
            MRFMask(i,j) = 0;
        end
    end
end

figure(3);
%subplot(1,3,1); imagesc(flipdim(rot90(abs(mean(imgs,3))),2));axis square;
subplot(1,2,1); imagesc(T1Map.*mask); axis square;
subplot(1,2,2); imagesc(T2Map.*mask); axis square;


T1MRFMean = mean(nonzeros(T1Map.*mask))
T1MRFStd = T1Map.*mask;
T1MRFStd(T1MRFStd==0) = nan; % Set to nan wherever there is a 0.
T1MRFStd = std(T1MRFStd, 0, 'all', 'omitnan'); % Compute st dev along the third dimension, ignoring nans.

T2MRFMean = mean(nonzeros(T2Map.*mask))
T2MRFStd = T2Map.*mask;
T2MRFStd(T2MRFStd==0) = nan; % Set to nan wherever there is a 0.
T2MRFStd = std(T2MRFStd, 0, 'all', 'omitnan'); % Compute st dev along the third dimension, ignoring nans.

