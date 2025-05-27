% Load bruker sech pulse
[A,phs] = ReadRFPulseFile("BrukerRFFiles/sech.inv");
RF  = A./max(A) .* exp(1j.*deg2rad(phs));
% Define duration
T = 14e-3;

% Scale to 20uT amplitude
RF = 10e-6.*RF;
dt = 10e-6;


% Interpolate pulse to 10us resolution
RF = InterpolateRFWaveform(RF,T,T/length(RF),dt);

% Generate spoiler
GenSliceSpoiler(amp,dur,riseTime,dt)


% Set-up spin system
NSpin = 200;
M = zeros([3,NSpin]);
M(3,:) = 1;
T1 = 2000.5000;
T2 = 50000e-3;

MNew = RFExcitation(M,T1,T2,dt,RF,"ignore_decay",true);






