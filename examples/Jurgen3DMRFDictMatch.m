%% Script to analyse EPIC 3D MRF data

addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")
addpath("MRF\")


%% Open bruker MRF dataset
pth = "datasets\JurgenMRFData\Exp3";
params = LoadBrukerData(pth);

fid = fopen("datasets\JurgenMRFData\Exp3\20241004_182823_15ml_Falcon_1perc_Agarose_50mM_NaCl_1mM_Gd_Exp3_el64x64x64x4096.bin");
rawdata = fread(fid,"double");
rawdata = complex(rawdata(1:2:end),rawdata(2:2:end));
imgs = reshape(rawdata, [64 64 4096]);

T1List = [50:10:1000];
T2List = [10:5:500];

TI = 2.5; %  Inversion Time ms
TR = 3; % Repetition time ms
TE = 1.5;  % Echo time ms
spoilingCycles = 0; % 6 pi spoiling 
B1 = [1]; % i.e. no B1 correction
% Load slice profile
NIso = 100; % Numbe of isochromats used in bloch simulation
sp = ones(NIso,1);
[dict,LUT] = GenerateDictionary(params.EPICFA,TR,TE,TI,T1List,T2List,B1,spoilingCycles,sp,NIso);
figure(1); montage(mat2gray(abs(imgs)));
figure(2);plot(angle(squeeze(imgs(28,32,:))));


%% Create binary mask from mean of images
se = strel('disk', 20, 0);
mask = mean(abs(imgs),3);
mask = imbinarize(mat2gray(abs(mask)));
mask = imclose(mask, se);
mask = imfill(mask, 'holes');
figure; imagesc(mask);


% Normalise Dictionary
normalisedDict = [];
cnt=length(dict);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(c,:).*conj(dict(c,:))));
    normalisedDict(c,:) = dict(c,:) / scaleFactor;
end

% Iterate through each voxel
parfor i = 1:64
    i
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
subplot(1,2,1); imagesc(T1Map); axis square;
subplot(1,2,2); imagesc(T2Map); axis square;

