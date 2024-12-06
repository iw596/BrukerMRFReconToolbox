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
pth = "datasets\BlochSiegertData\17";
%pth = "datasets\21";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin]);
data = permute(data,[1 3 2]);
imgs = ifftcn(data,[1 2]);

imgPos = imgs(:,:,1);
imgNeg = imgs(:,:,2);

PhaseDiff=angle(imgPos .* conj(imgNeg));
% unwrap phase difference using ROMEO phase uwnrapping
parameters.output_dir = fullfile(tempdir, 'romeo_tmp'); % temporary ROMEO output folder
mkdir(parameters.output_dir) ;
parameters.mask = 'nomask';
[uwpPhaseDiff] = ROMEO(PhaseDiff, parameters);
rmdir(parameters.output_dir, 's') % remove the temporary ROMEO output folder
Pint = 0.650376473268939;

GAMMA_RAD       = 4258*2*pi
dT       = 1e-6
KBS = GAMMA_RAD.^2 * trapz(linspace(0,8e-3,2048),B1Envelope.^2)./(2*2*pi*4000)


B1_BS_Peak_measured = sqrt(PhaseDiff/(KBS));
Calculated_Power_BlochSiegert = (((B1ref./B1_BS_Peak_measured)^2)*params.BSPulsePower);





B1 = sqrt(uwpPhaseDiff./(2*K));

B1hp = sqrt(uwpPhaseDiff * K);
B1ref = (pi/2)./(2*pi*42.6*10^6*1e-3); % Peak B1 in T

FAMap = abs(B1hp).*(2*pi*42.6*10^6*8e-3);


