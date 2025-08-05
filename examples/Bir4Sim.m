
%% Load, recon and fit AFI data
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250711_165219_PhosphoricAcid_B1Mappping_11072025_1_6\13";
params = LoadBrukerData(pth);
nextMultiple = 128 * ceil((params.NCol) / 128);
padding = nextMultiple - params.NCol;
data = reshape(params.data,[nextMultiple,2,params.NLin,params.NPar params.NRep]);
data = data(1:params.NCol,:,:,:);
data = permute(data,[1 3 4 2 5]);
imgs = ifftcn(data,[1 2 3]);
AFIB1 =  FitAFIB1(imgs,60,params.TR,params.TR * params.AFIRatio);
AFIB1_filt = medfilt3(abs(AFIB1),[5,5,5]);

figure; imagesc(abs(squeeze(AFIB1(32,:,:))),[0.5,1.5]);colormap("turbo")

%% Load DAM 45
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250711_165219_PhosphoricAcid_B1Mappping_11072025_1_6\7";
params = LoadBrukerData(pth);
nextMultiple = 128 * ceil((params.NCol) / 128);
padding = nextMultiple - params.NCol;
data = reshape(params.data,[nextMultiple,params.NLin,params.NPar params.NRep]);
data = data(1:params.NCol,:,:,:);
imgs_45 = ifftcn(data,[1 2 3]);

%% Load DAM 90
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250711_165219_PhosphoricAcid_B1Mappping_11072025_1_6\8";
params = LoadBrukerData(pth);
nextMultiple = 128 * ceil((params.NCol) / 128);
padding = nextMultiple - params.NCol;
data = reshape(params.data,[nextMultiple,params.NLin,params.NPar params.NRep]);
data = data(1:params.NCol,:,:,:);
imgs_90 = ifftcn(data,[1 2 3]);

alphaNom = 45;
DAMB1 = acosd(abs(imgs_90)./(2*abs(imgs_45)));
DAMB1 = DAMB1./alphaNom;
DAMB1_filt = medfilt3(abs(DAMB1),[5,5,5]);

figure; imagesc(abs(squeeze(DAMB1_filt(32,:,:))),[0.5,1.5]);colormap("turbo")








%% Load and recon DAM images
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250711_165219_PhosphoricAcid_B1Mappping_11072025_1_6\6";
params = LoadBrukerData(pth);
nextMultiple = 128 * ceil((params.NCol) / 128);
padding = nextMultiple - params.NCol;
data = reshape(params.data,[nextMultiple,params.NLin,params.NPar params.NRep]);
data = data(1:params.NCol,:,:,:);
imgs = ifftcn(data,[1 2 3]);
alphaNom = 45;
DAMB1 = acosd(abs(imgs(:,:,:,2))./(2*abs(imgs(:,:,:,1))));
DAMB1 = DAMB1./alphaNom;
DAMB1_filt = medfilt3(abs(DAMB1),[5,5,5]);

figure; imagesc(abs(squeeze(DAMB1_filt(32,:,:))),[0.5,1.5]);colormap("turbo")





pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250711_165219_PhosphoricAcid_B1Mappping_11072025_1_6\4";
params = LoadBrukerData(pth);
nextMultiple = 128 * ceil((params.NCol) / 128);
padding = nextMultiple - params.NCol;
data = reshape(params.data,[nextMultiple,params.NLin,params.NPar params.NRep]);
data = data(1:params.NCol,:,:,:);
imgs = ifftcn(data,[1 2 3]);
figure; 
plot(squeeze(imag(data(32,24,24,:))));
