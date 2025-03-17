addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")


%% Open bruker MRF dataset
params = LoadBrukerData("datasets/20250317_095411_MRF_Phantom_MRF_Dev_17032025_1_11/15");


% Read preplist and preptimes
prepList = ReadMRFPrepList("datasets\20250317_095411_MRF_Phantom_MRF_Dev_17032025_1_11/15/MRFPrepList.txt");



%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;

rawdata = reshape(rawdata, [params.NCol params.NPointsPerPrep * params.MRFNPrepModules params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
imgs = ifftcn(rawdata,[1 2]);
%figure(1); plot(FA); title("Flip Angle Pattern");
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
%normalisedDict = normalisedDict*-1;
T1Map = [];
T2Map = [];
NRead = params.NCol;
NPE = params.NLin;
% Iterate through each voxel
parfor i = 1:NRead
    i
    for j = 1:NPE

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

figure(13);plot(squeeze(angle(imgs(42,100,:)))); hold on; plot(angle((normalisedDict(:,end))));
legend("Measured","Dict");

%% Load T1 FAIR RARE
pth = "datasets/20250225_122413_MRF_Phantom_MRF_PhantomDev_25022028v2_1_7/4";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol 128 1 params.NInv]);
fclose(fid);

Model = inversion_recovery;
% TI in ms
TI = [params.InvTimes];
Model.Prot.IRData.Mat = [TI];
Model.Prot.TimingTable.Mat = [params.TR * 1000];
T1RefData = struct();
T1RefData.IRData = double(data);
T1FitResults = FitData(T1RefData,Model,0);


%% Load T2 MSME
pth = "datasets/20250317_095411_MRF_Phantom_MRF_Dev_17032025_1_11/16";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol 128 1 params.NEcho]);
fclose(fid);

Model = mono_t2;
EchoTime  = params.MSMETimes;
% EchoTime (ms) is a vector of [30X1]
Model.Prot.SEdata.Mat = [EchoTime];
T2MSMEdata = struct();
T2MSMEdata.SEdata=double(data);
T2FitResults = FitData(T2MSMEdata,Model,0);


figure(2); 
subplot(2,2,1); imagesc(T1Map); colormap("turbo"); colorbar; title("MRF T1 Map"); axis square;
subplot(2,2,2); imagesc(T1FitResults.T1,[0,2500]); colormap("turbo"); colorbar; title("Ref T1 Map");  axis square;
subplot(2,2,3);imagesc(T2Map,[0,600]); colormap("turbo"); colorbar; title("MRF T2 Map"); axis square;
subplot(2,2,4);imagesc(T2FitResults.T2,[0,600]); colormap("turbo"); colorbar; title("Ref T2 Map"); axis image;