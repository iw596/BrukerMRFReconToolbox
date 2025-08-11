addpath(genpath(".\."))
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250811_102419_MRF_Phantom_T2PrepDev_11082025_1_39\33";
params = LoadBrukerData(pth,true);
nextMultiple = 128 * ceil((params.NCol) / 128);
padding = nextMultiple - params.NCol;
data = reshape(params.data,[nextMultiple,params.NLin,params.NPar params.NRep]);
data = data(1:params.NCol,:,:,:);
imgs_T2Prep = ifftcn(data,[1 2]);
T2PrepTimes = [0;params.T2PrepTimes];


Model = mono_t2;
EchoTime  = T2PrepTimes;
% EchoTime (ms) is a vector of [30X1]
Model.Prot.SEdata.Mat = [EchoTime];
T2MSMEdata = struct();
imgs_T2Prep = reshape(imgs_T2Prep,[params.NCol params.NLin 1 params.NRep]);
imgs_T2Prep = imgs_T2Prep./max(imgs_T2Prep,[],'all');
T2MSMEdata.SEdata=double(imgs_T2Prep);
Model.options.DropFirstEcho = false;
Model.options.OffsetTerm = true;

T2FitResults = FitData(T2MSMEdata,Model,0);

figure; imagesc(abs(T2FitResults.T2),[0,500]); colormap("turbo");


figure(51);
imagesc(abs(T2FitResults.T2) ,[0 500]); axis image;  colormap("turbo"); colorbar;
title('Draw 8 ROIs on the Image');
% Initialize arrays to store mean values
RefT2_meanValues = zeros(1, 8);

% Initialize ROI handles
roiHandles = gobjects(1, 8);
% Draw 8 ROIs and calculate mean values
for i = 1:8
    roiHandles(i) = drawrectangle('Label', sprintf('ROI %d', i), 'Color', 'r');
    wait(roiHandles(i));  % Wait for the user to draw the ROI
    
    % Create mask for the ROI
    mask = createMask(roiHandles(i));
    RefT2_meanValues(i) = mean(T2FitResults.T2(mask));

    fprintf('Mean value for ROI %d: %.2f\n', i, RefT2_meanValues(i));
end
