addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")
% Try and open exc pulse
pulse = ReadRFPulseFile("datasets\FERMI_BlochSiegert.exc");
% Normalise pulse amplitude
pulse = pulse./max(pulse);
pth = "datasets\7";
params = LoadBrukerData(pth);
data = reshape(params.data,[128,2,128]);
data = permute(data,[1 3 2]);
imgs = ifftcn(data,[1 2]);

%% Calculate the phase images for both slices
img1Phs = angle(imgs(:,:,1));
img2Phs = angle(imgs(:,:,2));

gamma = 2*pi*4258; % Rad/Gauss
pulseShape = pulse;
pulseLength = 8e-3;
offset = 2*pi*4000;
dT = pulseLength/2048;
kbs = gamma * gamma * trapz((abs(pulseShape).^2)./(2*offset))*dT' % rads/Gauss^2




% Generate phase images for both offsets
