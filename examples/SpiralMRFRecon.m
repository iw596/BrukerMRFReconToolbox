%% Script to perform spiral MRF recon  
addpath(genpath('./.'));
%% Load data
pth = uigetdir;
params = LoadBrukerData(pth,true);


%% Trim raw data 
nextMultiple = 128 * ceil((params.Traj.PVM_SpiralSize + params.Traj.PVM_SpiralPostSize) / 128);
padding = nextMultiple - params.Traj.PVM_SpiralSize;
data = params.data;
data = reshape(data,[nextMultiple,params.NPointsPerPrep*params.MRFNPrepModules,params.Traj.MRFNoInterleaves]);
data = data(1:params.Traj.PVM_SpiralSize,:,:);
data = permute(data,[1 3 2]);
data = reshape(data,[params.Traj.PVM_SpiralSize * params.Traj.MRFNoInterleaves,params.NPointsPerPrep*params.MRFNPrepModules]);

%% Form trajectory
k = params.Traj.PVM_TrajKScale(1) .* params.Traj.kx + 1j*params.Traj.PVM_TrajKScale(2) .*params.Traj.ky;
k = reshape(k,[params.Traj.PVM_SpiralSize + params.Traj.PVM_SpiralPostSize ,params.Traj.PVM_SpiralNbOfInterleaves]);
k = k(:,1:params.Traj.MRFNoInterleaves); % Only extract interleaves we use
k = k(1:params.Traj.PVM_SpiralSize,:);
k = reshape(k,[params.Traj.PVM_SpiralSize *params.Traj.MRFNoInterleaves,1]);
area = voronoidens(k.*2*pi);
k = [real(k(:))*2*pi , imag(k(:)*2*pi)];  % [N x 2]
N = params.NCol;             % Grid size
Nd = [N N];          % Image dimensions
% Create NUFFT structure
J = [6 6];            % interpolation neighborhood
K = 2*length(k);              % oversampling
nufft_st = nufft_init(k, Nd, J, Nd*2, Nd/2);  % using MIRT



img = nufft_adj(area.*(data), nufft_st);  % adjoint (gridding);
img = flipdim(img,1);
img = flipdim(img,1);

figure; imshow(abs(img(:,:,10)),[]);
figure; plot(squeeze(abs(img(37,97,:))))

% Normalise Dictionary
normalisedDict = zeros(size(dict));

cnt=size(dict,2);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(:,c).*conj(dict(:,c))));
    normalisedDict(:,c) = dict(:,c) / scaleFactor;
end
T1Map = [];
T2Map = [];
indexMap = [];
% Iterate through each voxel
parfor i = 1:128
    i
    for j = 1:128

       scaleFactor = sqrt(sum(img(i,j,:).*conj(img(i,j,:))));
       normalized_mrfsignal = conj(img(i,j,:))/scaleFactor;
       inner_product=abs(squeeze(normalized_mrfsignal)'* (normalisedDict));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       T1Map(i,j) = LUT(max_index,1);
       T2Map(i,j) = LUT(max_index,2);
       B1Map(i,j) = LUT(max_index,3);
       MRFMask(i,j) = 1;
       dotProductMaximums(i,j) = maxValue;
       indexMap(i,j) = max_index;

    end
end

figure; 
subplot(1,2,1); imagesc(T1Map)
subplot(1,2,2); imagesc(T2Map)

%% Load T1 FAIR
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250529_085103_MRF_Phantom_MRFDev_29052025_1_29\69";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol 128 1 params.NInv]);
fclose(fid);
data = data./max(data,[],'all');
data = flipdim(data,2);
data = flipdim(data,1);

Model = inversion_recovery;
% TI in ms
TI = [params.InvTimes];
Model.Prot.IRData.Mat = [TI];
Model.Prot.TimingTable.Mat = [10000];
Model.options.fitModel = 'General';
T1RefData = struct();
T1RefData.IRData = double(data);
T1FitResults = FitData(T1RefData,Model,0);



%% Load T2 MSME
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250529_085103_MRF_Phantom_MRFDev_29052025_1_29\67";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol 128 1 params.NEcho]);
data = data./max(data,[],'all');
fclose(fid);
data = flipdim(data,2);
data = flipdim(data,1);

Model = mono_t2;
EchoTime  = params.MSMETimes;
% EchoTime (ms) is a vector of [30X1]
Model.Prot.SEdata.Mat = [EchoTime];
T2MSMEdata = struct();
T2MSMEdata.SEdata=double(data);
Model.options.DropFirstEcho = true;
Model.options.OffsetTerm = true;

T2FitResults = FitData(T2MSMEdata,Model,0);


T2Map_MRF = T2Map * 1000;
T1Map_MRF = T1Map.* 1000;
figure(58);
subplot(2,2,1); imagesc(T1Map_MRF ,[0 2000]); axis image;  colormap("turbo"); colorbar;
subplot(2,2,2); imagesc(T2Map_MRF,[0 400]); axis image;  colormap("turbo"); colorbar;
subplot(2,2,3); imagesc(T1FitResults.T1,[0 2000]); axis image;  colormap("turbo"); colorbar;
subplot(2,2,4); imagesc(T2FitResults.T2,[0 400]);axis image;  colormap("turbo"); colorbar;


figure(50);
imagesc(T1Map_MRF ,[0 2000]); axis image;  colormap("turbo"); colorbar;
title('Draw 8 ROIs on the Image');
% Initialize arrays to store mean values
MRFT1_meanValues = zeros(1, 8);
MRFT2_meanValues = zeros(1, 8);

% Initialize ROI handles
roiHandles = gobjects(1, 8);
% Draw 8 ROIs and calculate mean values
for i = 1:8
    roiHandles(i) = drawrectangle('Label', sprintf('ROI %d', i), 'Color', 'r');
    wait(roiHandles(i));  % Wait for the user to draw the ROI
    
    % Create mask for the ROI
    mask = createMask(roiHandles(i));
    
    MRFT1_meanValues(i) = mean(T1Map_MRF(mask));
    MRFT2_meanValues(i) = mean(T2Map_MRF(mask));

    fprintf('Mean value for ROI %d: %.2f\n', i, MRFT1_meanValues(i));
end

%% Repeat for reference methods
figure(51);
imagesc(T1FitResults.T1 ,[0 2000]); axis image;  colormap("turbo"); colorbar;
title('Draw 8 ROIs on the Image');
% Initialize arrays to store mean values
Ref1_meanValues = zeros(1, 8);
RefT2_meanValues = zeros(1, 8);

% Initialize ROI handles
roiHandles = gobjects(1, 8);
% Draw 8 ROIs and calculate mean values
for i = 1:8
    roiHandles(i) = drawrectangle('Label', sprintf('ROI %d', i), 'Color', 'r');
    wait(roiHandles(i));  % Wait for the user to draw the ROI
    
    % Create mask for the ROI
    mask = createMask(roiHandles(i));
    
    Ref1_meanValues(i) = mean(T1FitResults.T1(mask));
    RefT2_meanValues(i) = mean(T2FitResults.T2(mask));

    fprintf('Mean value for ROI %d: %.2f\n', i, MRFT1_meanValues(i));
end


% Fit a polynomial p of degree 1 to the data:
degree = 1;
p = polyfit(RefT2_meanValues(1:end),MRFT2_meanValues(1:end),degree);

% Evaluate the fitted polynomial p and plot:
f = polyval(p,RefT2_meanValues(1:end));
eqn = poly_equation(p); % polynomial equation (string)
Rsquared = my_Rsquared_coeff(MRFT2_meanValues(1:end),f); % correlation coefficient

figure(59);
plot(RefT2_meanValues(1:end),MRFT2_meanValues(1:end),'x',RefT2_meanValues(1:end),f,'--',LineWidth=2)
legend('data',eqn)
xlabel("T2 ground truth [ms]","Fontsize",20);
ylabel("T2 MRF [ms]","Fontsize",20)
axis = gca;
axis.FontSize = 20;
title(['Data fit - R squared = ' num2str(Rsquared)]);


%% T1 Results
% Fit a polynomial p of degree 1 to the data:
degree = 1;
p = polyfit(Ref1_meanValues(1:end),MRFT1_meanValues(1:end),degree);

% Evaluate the fitted polynomial p and plot:
f = polyval(p,Ref1_meanValues(1:end));
eqn = poly_equation(p); % polynomial equation (string)
Rsquared = my_Rsquared_coeff(MRFT1_meanValues(1:end),f); % correlation coefficient

figure(60);
plot(Ref1_meanValues(1:end),MRFT1_meanValues(1:end),'x',Ref1_meanValues(1:end),f,'--',LineWidth=2)
legend('data',eqn)
xlabel("T1 ground truth [ms]","Fontsize",20);
ylabel("T1 MRF [ms]","Fontsize",20)
axis = gca;
axis.FontSize = 20;
title(['Data fit - R squared = ' num2str(Rsquared)]);
