addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")


%% Open bruker MRF dataset
%pth = "datasets\MRF_ISMRM_Dataset\17";
pth = "datasets\MRFLowFA\42";
params = LoadBrukerData(pth);



%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
%[FA,TR] = ReadMRFList("datasets\MRFPattern.txt");
FA = ReadMRFList("datasets\MRFLowFA\MRFPattern.txt");
rawdata = reshape(rawdata, [params.NCol length(FA)*8 params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
imgs = fftcn(rawdata,[1 2]);
%imgs = fftshift(fft2((rawdata)));
figure; imagesc(abs(mean(imgs,3)));
figure(1); montage(mat2gray(abs(imgs)));


se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)));

% Normalise Dictionary
normalisedDict = [];
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
       normalized_mrfsignal = imgs(i,j,:)/scaleFactor;
       inner_product=abs(squeeze(normalized_mrfsignal)' * (normalisedDict));
       % Find best matching pattern
       [maxValue, max_index] = max(inner_product);
       T1Map(i,j) = LUT(max_index,1);
       T2Map(i,j) = LUT(max_index,2);
       MRFMask(i,j) = 1;
       dotProductMaximums(i,j) = maxValue;
       LUTIndex(i,j) =  max_index;
    end
end

figure(10); imagesc(T1Map.*mask);
figure(11); imagesc(T2Map.*mask);

rowN = 27;
colN = 25;
scaleFactor = sqrt(sum(imgs(rowN,colN,:).*conj(imgs(rowN,colN,:))));
normalized_mrfsignal = imgs(rowN,colN,:)/scaleFactor;

scaleFactor = sqrt(sum(dict(:,1).*conj(dict(:,1))));
gtDict = dict(:,1) / scaleFactor;
figure(15);
plot(squeeze(abs(squeeze(normalized_mrfsignal))),"Color","blue");
hold on;
plot(abs(normalisedDict(:,LUTIndex(rowN,colN))),"Color","green")
hold on;
plot(abs(gtDict),"Color","red")
legend("Measured Signal","Matched MRF Signal (T1 = 160, T2 = 46)","Ground Truth MRF (T1 = 240,T2 = 120)","Fontsize",15)



