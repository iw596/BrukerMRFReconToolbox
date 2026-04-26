addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
addpath("ROMEO\");
addpath("NIfTI_20140122\")
addpath("lib\")

% Try and open exc pulse
%pulse = ReadRFPulseFile("datasets\FERMI_BlochSiegert.exc");
pulse = ReadRFPulseFile("datasets/IWFermiPuilse.exc");
% Normalise pulse amplitude
B1Envelope = pulse./max(pulse);
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250606_122813_MRF_Phantom_MRFDev_06062025_1_31\29";
%pth = "datasets\21";
params = LoadBrukerData(pth);
nextMultiple = 128 * ceil(params.NCol / 128);
padding = nextMultiple - params.NCol;
data = params.data;
data = reshape(data,[nextMultiple,2,params.NLin]);
data = data(1:params.NCol,:,:);
data = permute(data,[1 3 2]);
imgs = ifftcn(data,[1 2]);

imgPos = imgs(:,:,1);
imgNeg = imgs(:,:,2);

phaseDiffImg = angle(imgPos .* conj(imgNeg))./2;
gamma = 42.56e6;

%% Calculate Fermi pulse peak amplitude
refPower = params.RefPow;
refVol = sqrt(refPower*50);
% Calculate pulse B1 required to achieve pi/2 flip for 1 ms block pulse
refB1 = (pi/2)./(2*pi*gamma*1e-3); % Peak B1 in T
% Calculate pulse peak voltage assuming 50 ohm load
pulsePeakVoltage = sqrt(params.BSPulse.power * 50);
% Peak B1 of pulse is refB1/refvoltage * pulse peak voltage
peakB1 = (refB1./refVol) .*  pulsePeakVoltage; % in T

dt = params.BSPulse.dur/length(B1Envelope);
dwRF = 2.*pi.*params.BSFreqOffset;
Kbs = sum(dt*((gamma .* B1Envelope).^2 ./ (2*(-dwRF))));
B1 = sqrt(phaseDiffImg./(2*Kbs));

B1ref = (pi/2)./(2*pi*42.6*10^6*1e-3); % Peak B1 in T
B1pk = sqrt( (phaseDiffImg) ./ (Kbs) ) ./pulsePeakVoltage .*refVol ./ refB1;
 figure; imagesc(abs(B1pk))

FAMap = abs(B1hp).*(2*pi*42.6*10^6*8e-3);


