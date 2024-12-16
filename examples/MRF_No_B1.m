addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")


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
mask = imfill(mask, 'holes');


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

figure(3);
%subplot(1,3,1); imagesc(flipdim(rot90(abs(mean(imgs,3))),2));axis square;
subplot(1,2,1); imagesc(T1Map.*mask); axis square;
subplot(1,2,2); imagesc(T2Map.*mask); axis square;


T1MRFMean = mean(nonzeros(T1Map.*mask))
T1MRFStd = T1Map.*mask;
T1MRFStd(T1MRFStd==0) = nan; % Set to nan wherever there is a 0.
T1MRFStd = std(T1MRFStd, 0, 'all', 'omitnan') % Compute st dev along the third dimension, ignoring nans.

T2MRFMean = mean(nonzeros(T2Map.*mask))
T2MRFStd = T2Map.*mask;
T2MRFStd(T2MRFStd==0) = nan; % Set to nan wherever there is a 0.
T2MRFStd = std(T2MRFStd, 0, 'all', 'omitnan') % Compute st dev along the third dimension, ignoring nans.




%% Load T1 FAIR RARE
pth = "datasets\22";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol 64 params.NInv]);
fclose(fid);
T1RefMap = T1Fitting(data,params.InvTimes);
T1RefMean = mean(nonzeros(T1RefMap.*mask))
T1RefStd = T1RefMap.*mask;
T1RefStd(T1RefStd==0) = nan; % Set to nan wherever there is a 0.
T1RefStd = std(T1RefStd, 0, 'all', 'omitnan'); % Compute st dev along the third dimension, ignoring nans.



%% Load T2 MSME
pth = "datasets\21";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[128 params.NLin params.NEcho]);
fclose(fid);
T2RefMap = T2Fitting(data,params.MSMETimes);
T2RefMean = mean(nonzeros(T2RefMap.*mask))
T2RefStd = T2RefMap.*mask;
T2RefStd(T2RefStd==0) = nan; % Set to nan wherever there is a 0.
T2RefStd = std(T2RefStd, 0, 'all', 'omitnan'); % Compute st dev along the third dimension, ignoring nans.






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




