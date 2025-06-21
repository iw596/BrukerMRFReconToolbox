%%
params = LoadBrukerData("C:\Users\kpqv532\OneDrive - University of Leeds\20250606_122813_MRF_Phantom_MRFDev_06062025_1_31\10");
data = params.data;

% Calculate how much padding per line of k-space
NLineSize = params.NCol * params.NCha;
nextMultiple = 128 * ceil(NLineSize / 128);
padding = nextMultiple - NLineSize; 



% First sort data
data = reshape(data,[nextMultiple, params.NLin * params.NPar * params.NRep]);
data = data(1:NLineSize,:); % Trim padding
% Reshape into Read-Cha-Lines-Par-Rep
data = reshape(data,[params.NCol,params.NCha,params.NLin,params.NPar* params.NRep]);
% Permute into Read-Lines-Par-Cha-Rep
data = permute(data,[1 3 2 4]);
% FFT into imgs for each channel
imgs = abs(fftcn(data,[1 2 3]));