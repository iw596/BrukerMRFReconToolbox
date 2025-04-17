%% Script to reconstruct 3D MRF data and perform matching

%% Load data and preplist
params = LoadBrukerData("datasets/20250411_152139_MRF_Phantom_MRF_3D_Experiment_11042025_1_17/14");
prepList = ReadMRFPrepList("datasets\20250411_152139_MRF_Phantom_MRF_3D_Experiment_11042025_1_17/14/MRFPrepList.txt");

rawdata  = params.data;
rawdata = reshape(rawdata, [params.NCol params.NPointsPerPrep * params.MRFNPrepModules params.NLin params.NPar]);
rawdata = permute(rawdata, [1 3 4 2 ]);
imgs = ifftcn(rawdata,[1 2 3]);

NPar = params.NPar;
NLin = params.NLin;
NCol = params.NCol;


% Normalise Dictionary
normalisedDict = zeros(size(dict));

cnt=size(dict,2);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(:,c).*conj(dict(:,c))));
    normalisedDict(:,c) = -1*dict(:,c) / scaleFactor;
end

% Perform 3D matching
T1Map = [];
T2Map = [];
B1Map = [];
indexMap = [];
% Iterate through each voxel
parfor i = 1:NCol
    i
    for j = 1:NLin
        for k = 1:NPar
           scaleFactor = sqrt(sum(imgs(i,j,k,:).*conj(imgs(i,j,k,:))));
           normalized_mrfsignal = conj(imgs(i,j,k,:))/scaleFactor;
           inner_product=abs(squeeze(normalized_mrfsignal)'* (normalisedDict));
           % Find best matching pattern
           [maxValue, max_index] = max(abs(inner_product));
           T1Map(i,j,k) = LUT(max_index,1);
           T2Map(i,j,k) = LUT(max_index,2);
           MRFMask(i,j) = 1;
           dotProductMaximums(i,j,k) = maxValue;
           indexMap(i,j,k) = max_index;
       end
    end
end

%% Load T1 map


%% Load T2 map




figure;
imagesc(T2Map(:,:,16).*1000)  