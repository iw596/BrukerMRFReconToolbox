addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")


%% Open bruker MRF dataset
params = LoadBrukerData("datasets/20250318_102411_MRF_Phantom_MRF_Phantom_Dev_18032025_1_12/63");


% Read preplist and preptimes
prepList = ReadMRFPrepList("datasets\20250318_102411_MRF_Phantom_MRF_Phantom_Dev_18032025_1_12/63/MRFPrepList.txt");



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
    normalisedDict(:,c) = -1*dict(:,c) / scaleFactor;
end
%normalisedDict = normalisedDict*-1;
T1Map = [];
T2Map = [];
B1Map = [];
indexMap = [];
% Iterate through each voxel
parfor i = 1:128
    i
    for j = 1:64

       scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
       normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
       inner_product=abs(squeeze(normalized_mrfsignal)'* (normalisedDict));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       T1Map(i,j) = LUT(max_index,1);
       T2Map(i,j) = LUT(max_index,2);
       B1Map(i,j) = LUT(max_index,3);
       %B1Map(i,j) = LUT(max_index,3);
       MRFMask(i,j) = 1;
       dotProductMaximums(i,j) = maxValue;
       indexMap(i,j) = max_index;

    end
end

figure(13);plot(squeeze(abs(imgs(29,40,:)))); hold on; plot(abs((normalisedDict(:,7296)))); hold on; plot(abs((normalisedDict(:,7291))));
legend("Measured","Dict matched","Dict Actual");

%% Load T1 FAIR RARE
pth = "datasets/20250317_095411_MRF_Phantom_MRF_Dev_17032025_1_11/17";
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


figure(13); 
subplot(2,2,1); imagesc(T1Map*1000); colormap("turbo"); colorbar; title("MRF T1 Map"); axis square;
subplot(2,2,2); imagesc(T1FitResults.T1,[0,2500]); colormap("turbo"); colorbar; title("Ref T1 Map");  axis square;
subplot(2,2,3);imagesc(T2Map*1000); colormap("turbo"); colorbar; title("MRF T2 Map"); axis square;
subplot(2,2,4);imagesc(T2FitResults.T2,[0,500]); colormap("turbo"); colorbar; title("Ref T2 Map"); axis image;

save("Results\Matlab_InstantRF_B1Est","T1Map","T2Map","B1Map","dict","LUT","T1FitResults","T2FitResults");






%% Very very very crude analysis code


ROI1Row = [93:103];
ROI1Col = [34:44];
T1MRFROI1 = T1Map(ROI1Row,ROI1Col);
T1MRFROI1Mean = mean(T1Map(ROI1Row,ROI1Col),'all');
T1MRFROI1Std = std(T1MRFROI1,1,"all");
T1RefROI1 = mean(T1RefMap(ROI1Row,ROI1Col),'all');

ROI2Row = [67:77];
ROI2Col = [18:28];
T1MRFROI2 = T1Map(ROI2Row,ROI2Col);
T1MRFROI2Mean = mean(T1Map(ROI2Row,ROI2Col),'all');
T1MRFROI2Std = std(T1MRFROI2,1,"all");
T1RefROI2 = mean(T1RefMap(ROI2Row,ROI2Col),'all');

MRFROI3Row = [37:47];
MRFROI3Col = [27:37];
ROI3Row = [39:49];
ROI3Col = [22:32];
T1MRFROI3 = T1Map(MRFROI3Row,MRFROI3Col);
T1MRFROI3Mean = mean(T1Map(MRFROI3Row,MRFROI3Col),'all');
T1MRFROI3Std = std(T1MRFROI3,1,"all");
T1RefROI3 = mean(T1RefMap(ROI3Row,ROI3Col),'all');

MRFROI4Row = [19:29];
MRFROI4Col = [55:65];
ROI4Row = [20:30];
ROI4Col = [46:56];
T1MRFROI4 = T1Map(MRFROI4Row,MRFROI4Col);
T1MRFROI4Mean = mean(T1Map(MRFROI4Row,MRFROI4Col),'all');
T1MRFROI4Std = std(T1MRFROI4,1,"all");
T1RefROI4 = mean(T1RefMap(ROI4Row,ROI4Col),'all');

ROI5Row = [49:59];
ROI5Col = [62:72];
T1MRFROI5 = T1Map(ROI5Row,ROI5Col);
T1MRFROI5Mean = mean(T1Map(ROI5Row,ROI5Col),'all');
T1MRFROI5Std = std(T1MRFROI5,1,"all");
T1RefROI5 = mean(T1RefMap(ROI5Row,ROI5Col),'all');


ROI6Row = [98:108];
ROI6Col = [71:81];
T1MRFROI6 = T1Map(ROI6Row,ROI6Col);
T1MRFROI6Mean = mean(T1Map(ROI6Row,ROI6Col),'all');
T1MRFROI6Std = std(T1MRFROI6,1,"all");
T1RefROI6 = mean(T1RefMap(ROI6Row,ROI6Col),'all');

ROI7Row = [81:92];
ROI7Col = [92:102];
RefROI7Row = [52:62];
RefROI7Col = [9:106];
T1MRFROI7 = T1Map(ROI7Row,ROI7Col);
T1MRFROI7Mean = mean(T1Map(ROI7Row,ROI7Col),'all');
T1MRFROI7Std = std(T1MRFROI7,1,"all");
T1RefROI7 = mean(T1RefMap(ROI7Row,ROI7Col),'all');

MRFROI8Row = [52:62];
MRFROI8Col = [100:110];
RefROI8Row = [52:62];
RefROI8Col = [94:106];
T1MRFROI8 = T1Map(MRFROI8Row,MRFROI8Col);
T1MRFROI8Mean = mean(T1Map(MRFROI8Row,MRFROI8Col),'all');
T1MRFROI8Std = std(T1MRFROI8,1,"all");
T1RefROI8 = mean(T1RefMap(RefROI8Row,RefROI8Col),'all');


