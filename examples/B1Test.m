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
pth = "datasets\BlochSiegertData\20";
%pth = "datasets\21";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin]);
data = permute(data,[1 3 2]);
imgs = ifftcn(data,[1 2]);
Vpulse = sqrt(params.BSPulsePower * 50); % Peak voltage assuming 50ohm load
Vref = sqrt(params.RefPow * 50); % Peak voltage assuming 50ohm load

B1ref = (pi/2)./(2*pi*42.6*10^6*1e-3); % Peak B1 in T
B1nom = (B1ref./Vref) .*  Vpulse; % in T

gamma = 4258* 2*pi; %Gauss/radians





imgPos = imgs(:,:,1);
imgNeg = imgs(:,:,2);

figure(20);
subplot(1,2,1); imshow(abs(imgPos),[]); title("Magntiude of positive Bloch-siegert image")
subplot(1,2,2); imshow(abs(imgNeg),[]); title("Magntiude of negative Bloch-siegert image")


dwrf = params.BSFreqOffset;
PhaseDiff=angle(imgPos.*conj(imgNeg));
PhaseDiff = PhaseDiff * 0.5;
% Perform ROMEO phase unwrapping
parameters.output_dir = fullfile(tempdir, 'romeo_tmp'); % temporary ROMEO output folder
mkdir(parameters.output_dir) ;
parameters.mask = 'nomask';
[uwpPhaseDiff] = ROMEO(PhaseDiff, parameters);
rmdir(parameters.output_dir, 's') % remove the temporary ROMEO output folder
uwpPhaseDiff = uwpPhaseDiff/2;

B1_normalized = 0.3769;
KBS = gamma.^2*B1_normalized * 8e-3 ./(2*2*pi*params.BSFreqOffset)
map = sqrt(uwpPhaseDiff./KBS);


