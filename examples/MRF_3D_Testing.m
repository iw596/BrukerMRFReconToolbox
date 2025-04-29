%% Script to reconstruct 3D MRF data and perform matching

%% Load B1 map
params = LoadBrukerData("datasets/20250411_152139_MRF_Phantom_MRF_3D_Experiment_11042025_1_17/39");
data = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
imgs = ifftcn(data,[1 2 3]);
AFIB1Map = FitAFIB1(imgs,60,20,20*5);

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
           
            % Find closest B1 value in LUT and restrict dictionary search to this area
            measuredB1Val = squeeze(AFIB1Map(i,j,k));
            [val,idx] = min(abs(1-squeeze(LUT(:,3))));
            closestB1 = LUT(idx,3);
            idx=find(LUT(:,3) == closestB1);
            subDict = normalisedDict(:,idx);
            subLUT = LUT(idx,:);
            scaleFactor = sqrt(sum(imgs(i,j,k,:).*conj(imgs(i,j,k,:))));
            normalized_mrfsignal = conj(imgs(i,j,k,:))/scaleFactor;
            inner_product=abs(squeeze(normalized_mrfsignal)'* (subDict));
            % Find best matching pattern
            [maxValue, max_index] = max(abs(inner_product));
            matched_indices(i, j,k) = max_index;
            T1Map(i,j,k) = subLUT(max_index,1);
            T2Map(i,j,k) = subLUT(max_index,2);
            B1Map(i,j,k) = subLUT(max_index,3);
            MRFMask(i,j,k) = 1;
            indexMap(i,j,k) = max_index; 
            
           % scaleFactor = sqrt(sum(imgs(i,j,k,:).*conj(imgs(i,j,k,:))));
           % normalized_mrfsignal = conj(imgs(i,j,k,:))/scaleFactor;
           % inner_product=abs(squeeze(normalized_mrfsignal)'* (normalisedDict));
           % % Find best matching pattern
           % [maxValue, max_index] = max(abs(inner_product));
           % T1Map(i,j,k) = LUT(max_index,1);
           % T2Map(i,j,k) = LUT           (max_index,2);
           % MRFMask(i,j) = 1;
           % dotProductMaximums(i,j,k) = maxValue;
           % indexMap(i,j,k) = max_index;
       end
    end
end

%% Load T1 map
pth = "datasets/20250411_152139_MRF_Phantom_MRF_3D_Experiment_11042025_1_17/31";
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

%% Load T2 map
pth = "datasets/20250411_152139_MRF_Phantom_MRF_3D_Experiment_11042025_1_17/16";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol params.NLin params.NPar params.NEcho]);
fclose(fid);
data = data(:,:,16,:);
Model = mono_t2;
EchoTime  = params.MSMETimes;
% EchoTime (ms) is a vector of [30X1]
Model.Prot.SEdata.Mat = [EchoTime];
T2MSMEdata = struct();
T2MSMEdata.SEdata=double(data);
T2FitResults = FitData(T2MSMEdata,Model,0);



figure(15); 
subplot(2,2,1); imagesc(T1Map(:,:,16)*1000,[0,2500]); colormap("turbo"); colorbar; title("MRF T1 Map"); axis square;
subplot(2,2,2); imagesc(T1FitResults.T1,[0,2500]); colormap("turbo"); colorbar; title("Ref T1 Map");  axis square;
subplot(2,2,3);imagesc(T2Map(:,:,16)*1000,[0,500]); colormap("turbo"); colorbar; title("MRF T2 Map"); axis square;
subplot(2,2,4);imagesc(T2FitResults.T2,[0,500]); colormap("turbo"); colorbar; title("Ref T2 Map"); axis image; 


figure(16); 
T1MapMid = T1Map(:,:,16);
T2MapMid = T2Map(:,:,16);

imagesc(T1Map(:,:,16)*1000,[0,2500]);
% Initialize array to store ROI handles and means
roiHandles = gobjects(9, 1);
meanValuesMRFT1 = zeros(9, 1);
meanValuesMRFT2 = zeros(9, 1);
meanValuesRefT1 = zeros(9, 1);
meanValuesRefT2 = zeros(9, 1);

% Draw ROIs and calculate mean
for i = 1:9
    roiHandles(i) = drawrectangle('Label', sprintf('ROI %d', i), ...
                                  'Color', 'r');
    wait(roiHandles(i));  % Wait for user to double-click and finish drawing
    
    % Create a binary mask from the ROI
    mask = createMask(roiHandles(i));
    
    % Calculate mean within the mask
    meanValuesMRFT1(i) = mean(T1MapMid(mask));
    meanValuesMRFT2(i) = mean(T2MapMid(mask));
    meanValuesRefT1(i) = mean(T1FitResults.T1(mask));
    meanValuesRefT2(i) = mean(T2FitResults.T2(mask));
    
    % Display mean value on the figure
    pos = roiHandles(i).Position;
    text(pos(1), pos(2) - 10, sprintf('Mean: %.2f', meanValuesMRFT1(i)), ...
         'Color', 'yellow', 'FontSize', 10, 'FontWeight', 'bold');
end


meanValuesRefT2SSorted = sort(meanValuesRefT2);
meanValuesMRFT2Sorted = sort(meanValuesMRFT2).*1000;

meanValuesRefT1SSorted = sort(meanValuesRefT1);
meanValuesMRFT1Sorted = sort(meanValuesMRFT1).*1000;

% Fit a polynomial p of degree 1 to the data:
degree = 1;
p = polyfit(meanValuesRefT2SSorted,meanValuesMRFT2Sorted,degree);

% Evaluate the fitted polynomial p and plot:
f = polyval(p,meanValuesRefT2SSorted);
eqn = poly_equation(p); % polynomial equation (string)
Rsquared = my_Rsquared_coeff(meanValuesMRFT2Sorted,f); % correlation coefficient




figure(6);
plot(meanValuesRefT2SSorted,meanValuesMRFT2Sorted,'x',meanValuesRefT2SSorted,f,'--',LineWidth=2)
legend('data',eqn)
xlabel("T2 ground truth [ms]","Fontsize",20);
ylabel("T2 MRF [ms]","Fontsize",20)
axis = gca;
axis.FontSize = 20;
title(['Data fit - R squared = ' num2str(Rsquared)]);



% Fit a polynomial p of degree 1 to the data:
degree = 1;
p = polyfit(meanValuesRefT1SSorted,meanValuesMRFT1Sorted,degree);

% Evaluate the fitted polynomial p and plot:
f = polyval(p,meanValuesRefT1SSorted);
eqn = poly_equation(p); % polynomial equation (string)
Rsquared = my_Rsquared_coeff(meanValuesMRFT1Sorted,f); % correlation coefficient




figure(7);
plot(meanValuesRefT1SSorted,meanValuesMRFT1Sorted,'x',meanValuesRefT1SSorted,f,'--',LineWidth=2)
legend('data',eqn)
xlabel("T1 ground truth [ms]","Fontsize",20);
ylabel("T1 MRF [ms]","Fontsize",20)
axis = gca;
axis.FontSize = 20;
title(['Data fit - R squared = ' num2str(Rsquared)]);