addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
% Try and open exc pulse
pulse = ReadRFPulseFile("datasets\FERMI_BlochSiegert.exc");
% Normalise pulse amplitude
pulse = pulse./max(pulse);
pth = "datasets\BlochSiegertData\10";
%pth = "datasets\21";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin]);
data = permute(data,[1 3 2]);
imgs = ifftcn(data,[1 2]);

%% Calculate peak B1 of BS pulse
refB1 = (pi/2)./(2*pi*42.6*10^6*1e-3); % Peak B1 in T
% Calculate reference peak voltage assuming 50 ohm load
refPeakVolage = sqrt(params.RefPow * 50);
% Calculate pulse peak voltage assuming 50 ohm load
pulsePeakVoltage = sqrt(params.BSPulsePower * 50);
% Peak B1 of pulse is refB1/refvoltage * pulse peak voltage
peakB1 = (refB1./refPeakVolage) .*  pulsePeakVoltage; % in T
peakB1 = peakB1 * 10000; % Gauss


%% Create Binary mask
se = strel('disk', 20, 0);
BW = imbinarize(mat2gray(abs(imgs(:,:,1))));
BW = imclose(BW, se);
BW = imfill(BW, 'holes');


bsPulseDuration = 8e-3;
bsFreqOffset = 2 * pi * params.BSFreqOffset;



kbs = 