addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
addpath("ROMEO\");
addpath("NIfTI_20140122\")
addpath("lib\")

% Try and open exc pulse
pulse = ReadRFPulseFile("datasets\IWFermiPuilse.exc");
% Normalise pulse amplitude
B1Envelope = pulse./max(pulse);
pth = "datasets\BlochSiegertData\20";
%pth = "datasets\21";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin]);
data = permute(data,[1 3 2]);
imgs = ifftcn(data,[1 2]);

gamma = 4258* 2*pi; %Gauss/radians





imgPos = imgs(:,:,1);
imgNeg = imgs(:,:,2);

figure(20);
subplot(1,2,1); imshow(abs(imgPos),[]); title("Magntiude of positive Bloch-siegert image")
subplot(1,2,2); imshow(abs(imgNeg),[]); title("Magntiude of negative Bloch-siegert image")


dwrf = 7500;
PhaseDiff=angle(imgPos.*conj(imgNeg));
% Perform ROMEO phase unwrapping
parameters.output_dir = fullfile(tempdir, 'romeo_tmp'); % temporary ROMEO output folder
mkdir(parameters.output_dir) ;
parameters.mask = 'nomask';
[uwpPhaseDiff] = ROMEO(PhaseDiff, parameters);
rmdir(parameters.output_dir, 's') % remove the temporary ROMEO output folder
uwpPhaseDiff = uwpPhaseDiff ;

B1_normalized = 0.650376473268939;
KBS = gamma.^2*0.0052./(2*2*pi*dwrf)
map = sqrt(uwpPhaseDiff./(2*KBS));
figure; imshow(abs(map./0.11),[])


