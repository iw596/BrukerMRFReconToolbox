% Example of calculating and saving slice profile
addpath("FileIO\")
addpath(genpath("rf_tools\"))

BW =  3000; % Hz
thickness = 0.1; % in cm


%Gz = (2 * pi * BW)./(42.57 * 10^(6) * thickness); % Gradient value in T/m
% Convert to Gauss/cm
%Gz = Gz * 100;
Gz = BW./(42.57 * 10^(6) * thickness * 1/10000); % In Gauss/cm
df = 0;		% kHz, off-resonance.
[pulse,phase] = ReadRFPulseFile("datasets\sinc10H.exc");

ttt = real(pulse.*exp(1j*deg2rad(phase)));
ttt = ttt./sum(ttt);
spatialPos = linspace(-thickness,thickness,250);

rf = (pi/2) * ttt;
x = cm2gt(spatialPos,Gz,6.66666666);
%x2 = [-20:0.01:20];
spatialPos2 = gt2cm(x,Gz,6.666);
profile= ab2ex(abr((rf),x));
save("Dictionaries\Sinc10Profile.mat","spatialPos2","profile");


figure(1);
%plot(gt2cm(x2,Gz,6.666),abs(ab2ex(abr((rf),x2)))); xlabel("Position (cm)")
plot(spatialPos,abs(ab2ex(abr((rf),x))))