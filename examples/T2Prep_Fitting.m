addpath(genpath(".\."))
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250724_164854_MRF_Phantom_MRF_24072025_1_37\107";
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