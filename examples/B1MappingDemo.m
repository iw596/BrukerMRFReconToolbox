addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
addpath("ROMEO\");
addpath("NIfTI_20140122\")
addpath("lib\")

% Try and open exc pulse
pulse = ReadRFPulseFile("datasets\FERMI_BlochSiegert.exc");
% Normalise pulse amplitude
B1Envelope = pulse./max(pulse);
<<<<<<< Updated upstream
pth = "datasets\BlochSiegertData\9";
=======


% Amplitude integral will be sum of all pulse elements
ampInt = sum(B1Envelope)
















































































pth = "datasets\BlochSiegertData\5";
>>>>>>> Stashed changes
%pth = "datasets\21";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin]);
data = permute(data,[1 3 2]);
imgs = ifftcn(data,[1 2]);
Vpulse = sqrt(params.BSPulsePower * 50); % Peak voltage assuming 50ohm load
Vref = sqrt(params.RefPow * 50); % Peak voltage assuming 50ohm load
B1Ref = (pi/2)./(2*pi*42.6*10^6*1e-3); % Peak B1 in T
BSSB1 = (B1Ref./Vref) .*  Vpulse; % in T

gamma = 2*pi*42.58e6;           %rad/s/T
deltat = 1e-6;                  %s 
deltaOmega = 2 * pi * params.BSFreqOffset;
Kbs = sum( pulse.^2) * gamma^2 * deltat / (deltaOmega);
imgPos = imgs(:,:,1);
imgNeg = imgs(:,:,2);
PhaseDiff = -angle(imgs(:,:,1).*conj(imgs(:,:,2)));
PhaseDiff = PhaseDiff./2; % Combining phases from BSS+ and BSS- 
B1Map_full = sqrt(PhaseDiff / (Kbs));

alphaBS = 300;

flipAngleMap_full = B1Map_full *180/pi / alphaBS *100;








B1ref = (pi/2)./(2*pi*42.6*10^6*1e-3); % Peak B1 in T
B1nom = (B1ref./Vref) .*  Vpulse; % in T

<<<<<<< Updated upstream


magB1 = abs(pulse);
phaseB1 = angle(pulse);
ampInt_R_Component = sum(magB1.*cos(phaseB1));
ampInt_I_Component = sum(magB1.*sin(phaseB1));
ampInt = sqrt(ampInt_R_Component^2 + ampInt_I_Component^2);
powerInt = sum( (magB1.*cos(phaseB1)).^2 + (magB1.*sin(phaseB1)).^2 );



absInt = sum(magB1);
theta = pi/2; %rad/s
t_pulse = 1*10^-3; %seconds
B1_ref_90 = (theta)/(gyromagnetic_ratio_7T*t_pulse); %Tesla
f_BS = 2*pi*params.BSFreqOffset;
t_BS = 8e-3;
=======
>>>>>>> Stashed changes

%Pint from Fermi pulse
B1_normalized = 0.3769;
% Solve for K_BS
<<<<<<< Updated upstream
gamma = 26745; % in rad/G

imgPos = imgs(:,:,1);
imgNeg = imgs(:,:,2);



se = strel('disk', 20, 0);
BW = imbinarize(mat2gray(abs(imgs(:,:,1))));
BW = imclose(BW, se);
BW = imfill(BW, 'holes');


PhaseDiff=angle(imgPos.*conj(imgNeg));
% unwrap phase difference using ROMEO phase uwnrapping
parameters.output_dir = fullfile(tempdir, 'romeo_tmp'); % temporary ROMEO output folder
mkdir(parameters.output_dir) ;
parameters.mask = 'nomask';
[uwpPhaseDiff] = ROMEO(PhaseDiff, parameters);
rmdir(parameters.output_dir, 's') % remove the temporary ROMEO output folder

KBS = gamma.^2*8e-3*B1_normalized/(2*f_BS);

map = sqrt(uwpPhaseDiff./KBS);


tmp = BW.*map./(1.9562e-05 * 10000);
figure; imagesc(BW.*map./(1.9562e-05 * 10000));







=======
>>>>>>> Stashed changes



%% Create Binary mask
 se = strel('disk', 20, 0);
 BW = imbinarize(mat2gray(abs(imgs(:,:,1))));
 %BW = imclose(BW, se);
 %BW = imfill(BW, 'holes');

PhaseDiff = -angle(imgs(:,:,1).*conj(imgs(:,:,2)));
PhaseDiff = PhaseDiff./2; % Combining phases from BSS+ and BSS- 
GAMMA_RAD       = 267.52218744e6;  % rad/(sT);
powerIntegral = 0.3769;
KBS = GAMMA_RAD*GAMMA_RAD * powerIntegral * 1e-6./(2 * f_BS);
K_BS = GAMMA_RAD.^2*t_BS*B1_normalized/(2*f_BS);

B1pk = sqrt(PhaseDiff / K_BS);
figure; imagesc(BW.*(abs(B1pk))); axis square;

%dwrf = params.BSFreqOffset;

% Perform ROMEO phase unwrapping
%parameters.output_dir = fullfile(tempdir, 'romeo_tmp'); % temporary ROMEO output folder
%mkdir(parameters.output_dir) ;
%parameters.mask = 'nomask';
%[uwpPhaseDiff] = ROMEO(PhaseDiff, parameters);
%rmdir(parameters.output_dir, 's') % remove the temporary ROMEO output folder
%uwpPhaseDiff = uwpPhaseDiff/2;
%%   [B1classic KBS]=gadgetron.FIL.utils.ComputeBSSB1Map(uwpPhaseDiff/2,RefVoltage,BSPulseVoltage,BSPulseDuration,OffsetFrequencyHz);





GAMMA_RAD.^2/(2*f_BS) .* trapz(linspace(0,6e-3,1000),abs(H))
B1nom = (pi/2)/(gamma * 1e-3);

bsB1 = (B1nom./Vref) .*  Vpulse; % in T

B1pk = sqrt((PhaseDiff)./(2 * pi* K_BS));

% Divide by Refernce B1 to get fraction relative to 


ttt = BW.*(abs(B1pk./B1_ref_90.*90))./220;

ttt = medfilt2(ttt,[5,5]);


ppp = abs((AFIB1Map(:,:,16) - ttt))./(0.5*(ttt+AFIB1Map(:,:,16)));
ppp = ppp.*100;
figure; imagesc(ppp.*BW(:,:,16))
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
