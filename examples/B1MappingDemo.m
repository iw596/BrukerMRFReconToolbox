addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
% Try and open exc pulse
pulse = ReadRFPulseFile("datasets\FERMI_BlochSiegert.exc");
% Normalise pulse amplitude
pulse = pulse./max(pulse);
pth = "datasets\BlochSiegertData\21";
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



%% Create Binary mask
se = strel('disk', 20, 0);
BW = imbinarize(mat2gray(abs(imgs(:,:,1))));
BW = imclose(BW, se);
BW = imfill(BW, 'holes');

phaseImage = atan2(imag(imgs(:,:,1)./imgs(:,:,2)),real(imgs(:,:,1)./imgs(:,:,2)));


gamma = 42.58 * 10^6; % Hz/T
pulseShape = pulse;
pulseLength = 8e-3;
offset = 4000; % Hz
dT = pulseLength/2048;

BHat = trapz((abs(pulseShape).^2))*dT'; % Normalized pulse-envelope squared integral

ttt = sqrt((phaseImage.*offset)./(2*pi*BHat));
ttt = ttt./(gamma * peakB1);
figure; imagesc(medfilt2(abs(ttt),[5,5]).*BW,[0.5,1])

kbs = gamma * gamma * trapz((abs(pulseShape).^2)./(2*offset))*dT'; % rads/Gauss^2
ttt = sqrt(phaseImage./ kbs);
ttt = medfilt2(abs(ttt),[5,5]);

%B1Map_full = sqrt(phaseImage / kbs);
%flipAngleMap_full = B1Map_full * gamma*sum(pulseShape)*dT*180/pi / 1200 *100;


%bsB1Map = (abs(img2Phs - img1Phs)<pi).*sqrt(abs(img2Phs - img1Phs)./2./kbs)+ (abs(img2Phs - img1Phs)>=pi).*sqrt(abs(img2Phs - img1Phs-2*pi)./2./kbs); % in Gauss
%bsB1Map = gamma * peakB1.*bsB1Map; %in radians
%bsB1Map = bsB1Map./pi.*180; % in degrees



%ttt = (img1Phs-img2Phs);
% Generate phase images for both offsets

%ttt = atan2(imag(imgs(:,:,2)./imgs(:,:,1)),real(imgs(:,:,2)./imgs(:,:,1)));
%B1 = sqrt(abs(ttt))./kbs;