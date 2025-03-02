% Example of calculating and saving slice profile
addpath("FileIO\")
addpath(genpath("rf_tools\"))

% Set-up waveform
[pulse,phase] = ReadRFPulseFile("datasets\sinc10H.exc");
dur = 7.8e-3;
dT = dur/length(pulse);
flip = pi/2;
BW = 5e3;

pos = linspace(-1e-3,1e-3,250);
waveform = pulse.*exp(1j*deg2rad(phase));
waveform = waveform.*flip/(sum(waveform))/(2*pi*42.57e6*dT);

Gz = (2*pi*BW)/(2*pi*42.57e6*1e-3);
M = zeros([3,250]);
M(3,:) = 1;



MNew = RFExcitation(waveform,dT,M,Gz,pos);
res = complex(MNew(1,:),MNew(2,:));
figure; plot(abs(res))