%% AFI Comparison script
addpath(genpath("./."))

%% Load reference AFI
params = LoadBrukerData("C:\Users\kpqv532\OneDrive - University of Leeds\20250529_085103_MRF_Phantom_MRFDev_29052025_1_29\20");
data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 



% First sort data
data = reshape(data,[nextMultiple, 2 * params.NLin * params.NPar]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,2,params.NCha,params.NLin,params.NPar]);
% Permute into Read-Lines-Par-Cha-Rep
data = permute(data,[1 4 5 2 3]);
% FFT into imgs for each channel
imgs = abs(fftcn(data,[1 2 3]));
AFIB1Map_ref = FitAFIB1(imgs,60,30e-3,150e-3);


%% Load EPIC AFI
params = LoadBrukerData("C:\Users\kpqv532\OneDrive - University of Leeds\20250606_122813_MRF_Phantom_MRFDev_06062025_1_31\40");
data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 



% First sort data
data = reshape(data,[nextMultiple, 2 * params.NLin * params.NPar]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,2,params.NCha,params.NLin,params.NPar]);
% Permute into Read-Lines-Par-Cha-Rep
data = permute(data,[1 4 5 2 3]);
% FFT into imgs for each channel
imgs = abs(fftcn(data,[1 2 3]));
AFIB1Map_epic = FitAFIB1(imgs,60,params.TR,params.TR*params.AFIRatio);


figure(5);

subplot(1,2,1); imagesc(AFIB1Map_ref(:,:,26),[0.5,2]); colormap("turbo"); title("Reference AFI B1");
subplot(1,2,2); imagesc(AFIB1Map_epic(:,:,32),[0.5,2]); colormap("turbo"); title("EPIC AFI B1");

%% Now do double angle mapping
params = LoadBrukerData("C:\Users\kpqv532\OneDrive - University of Leeds\20250606_122813_MRF_Phantom_MRFDev_06062025_1_31\19");
data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 
% First sort data
data = reshape(data,[nextMultiple,  params.NLin params.NPar]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,params.NLin params.NPar]);
% FFT into imgs for each channel
imgs_45 = abs(fftcn(data,[1 2 3]));

params = LoadBrukerData("C:\Users\kpqv532\OneDrive - University of Leeds\20250606_122813_MRF_Phantom_MRFDev_06062025_1_31\18");
data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 
% First sort data
data = reshape(data,[nextMultiple,  params.NLin params.NPar]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,params.NLin params.NPar]);
% Permute into Read-Lines-Par-Cha-Rep
% FFT into imgs for each channel
imgs_90 = abs(fftcn(data,[1 2 3]));

DAMB1 = acosd(imgs_90./(2.*imgs_45))./45;

figure; 
subplot(1,2,1); imagesc(abs(DAMB1(:,:,32)),[0.5 1.2]); colormap("turbo"); title("DAM"); colorbar;
subplot(1,2,2);imagesc(abs(AFIB1Map_epic(:,:,32)),[0.5 1.2]); colormap("turbo"); title("AFI"); colorbar;

figure; imagesc(abs(DAMB1(:,:,32)) -abs(AFIB1Map_epic(:,:,32)))