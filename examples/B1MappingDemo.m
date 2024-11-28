addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
addpath("ROMEO\");
addpath("NIfTI_20140122\")
addpath("lib\")

% Try and open exc pulse
%pulse = ReadRFPulseFile("datasets\FERMI_BlochSiegert.exc");
pulse = ReadRFPulseFile("datasets\IWFermiPuilse.exc");
% Normalise pulse amplitude
B1Envelope = pulse./max(pulse);
pth = "datasets\BlochSiegertData\20";
%pth = "datasets\21";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin]);
data = permute(data,[1 3 2]);
imgs = ifftcn(data,[1 2]);






%Vpulse = sqrt(params.BSPulsePower * 50); % Peak voltage assuming 50ohm load
%Vref = sqrt(params.RefPow * 50); % Peak voltage assuming 50ohm load

%B1ref = (pi/2)./(2*pi*42.6*10^6*1e-3); % Peak B1 in T
%B1nom = (B1ref./Vref) .*  Vpulse; % in T

imgPos = imgs(:,:,1);
imgNeg = imgs(:,:,2);

PhaseDiff=angle(imgPos .*conj(imgNeg));
PhaseDiff = unwrap_phase(PhaseDiff);

% unwrap phase difference using ROMEO phase uwnrapping
parameters.output_dir = fullfile(tempdir, 'romeo_tmp'); % temporary ROMEO output folder
mkdir(parameters.output_dir) ;
parameters.mask = 'nomask';
[uwpPhaseDiff] = ROMEO(PhaseDiff, parameters);
rmdir(parameters.output_dir, 's') % remove the temporary ROMEO output folder




kFermi = sum(B1Envelope.^2)/length(B1Envelope);
dwrf = 2*pi* 7500;
KBS = gamma.^2*0.0052./(dwrf);
map = sqrt((PhaseDiff)./(2*KBS));


B1hp = sqrt(uwpPhaseDiff * K);
B1ref = (pi/2)./(2*pi*42.6*10^6*1e-3); % Peak B1 in T

FAMap = abs(B1hp).*(2*pi*42.6*10^6*8e-3);


