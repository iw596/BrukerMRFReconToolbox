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

% Generate phase images for both offsets

phsImg1 = angle(imgs(:,:,1));
phsImg2 = angle(imgs(:,:,2));

tmp = (unwrap(flipud(angle(imgs(:,:,1))))-unwrap(flipud(angle(imgs(:,:,2)))));
[B1Map] = BlochSiegertB1(imgs,pulse,8e-3,params)