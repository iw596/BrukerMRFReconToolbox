addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
% Try and open exc pulse
pulse = ReadRFPulseFile("datasets\FERMI_BlochSiegert.exc");
% Normalise pulse amplitude
pulse = pulse./max(pulse);
pth = "datasets\BlochSiegertData\8";
%pth = "datasets\21";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin]);
data = permute(data,[1 3 2]);
imgs = ifftcn(data,[1 2]);




PhaseDiff=angle(imgs(:,:,1).*conj(imgs(:,:,2)));

% Perform ROMEO phase unwrapping







% %% Calculate peak B1 of BS pulse
% refB1 = (pi/2)./(2*pi*42.6*10^6*1e-3); % Peak B1 in T
% % Calculate reference peak voltage assuming 50 ohm load
% refPeakVolage = sqrt(params.RefPow * 50);
% % Calculate pulse peak voltage assuming 50 ohm load
% pulsePeakVoltage = sqrt(params.BSPulsePower * 50);
% % Peak B1 of pulse is refB1/refvoltage * pulse peak voltage
% peakB1 = (refB1./refPeakVolage) .*  pulsePeakVoltage; % in T
% peakB1 = peakB1 * 10000 ; % Gauss
% 
% 
% %% Create Binary mask
% se = strel('disk', 20, 0);
% BW = imbinarize(mat2gray(abs(imgs(:,:,1))));
% BW = imclose(BW, se);
% BW = imfill(BW, 'holes');
% 
% 
% bsPulseDuration = 8e-3;
% bsFreqOffset = 2*pi * params.BSFreqOffset;
% dT = 8e-3/2048;
% kbs = sum(pulse)*dT * gamma^2 * 1./(2*bsFreqOffset)
% imgPos = imgs(:,:,1);
% imgNeg = imgs(:,:,2);
% 
% phaseImage = angle(imgNeg) - angle(imgPos);
% phaseImage(phaseImage<0) = phaseImage(phaseImage<0) + 2*pi;
% B1Map_full = sqrt(angle(imgPos./imgNeg) / (2* kbs));
% flipAngleMap_full = B1Map_full * gamma*sum(pulse)*dT *180/pi / 180 *100;
% 
% 
% 
% 
% deltaOmega = 2*pi*params.BSFreqOffset;
% alphaBS = 180;
% gamma = 2*pi*42.58e6;           %rad/s/T
% deltat = 8e-3./length(pulse);                  %s
% Kbs = sum(pulse.^2) * gamma^2 * deltat / (deltaOmega) / (max(pulse))^2;
% 
% 
% phaseImage = angle(imgNeg) - angle(imgPos);
% phaseImage(phaseImage<0) = phaseImage(phaseImage<0) + 2*pi;
% B1Map_full = sqrt(phaseImage / Kbs);
% 
% 
% flipAngleMap_full = B1Map_full * gamma*sum(pulse)*deltat/max(pulse) *180/pi / alphaBS *100;
% flipAngleMap_full = medfilt2(flipAngleMap_full,[5,5]);
% 
% ttt = AFIB1Map(:,:,16) - flipAngleMap_full./500;
