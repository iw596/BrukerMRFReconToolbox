params = LoadBrukerData("datasets/20250211_141529_IW_Phantom_NiCl2_MRF_Dev_11_02_2025_1_5/35");


FA = pi/2;

waveform = params.ExcRFShape;
RFDur = params.ExcRFDur;
dt = RFDur/length(waveform);

% Scale waveform
waveform = waveform.*FA/(sum(waveform))/(2*pi*42.57e6*dt);
% Convert gradient in Hz/mm to T/m
G = (params.SliceSelGrad * 1000)/(42.57e6);


figure(1);
plot(real(waveform)); title("RF waveform")


% Set-up spin system
T1 = 1.5;
T2 = 50e-3;
NSpin = 200;
pos = linspace(-1e-3,1e-3,NSpin);
M = zeros([3,NSpin]);
M(3,:) = 1;

% Run simulation
M = RFExcitation(waveform,dt,M,G,pos,T1,T2);
Mxy = complex(M(1,:), M(2,:));

figure(2);
plot(pos*1000,imag(Mxy)); xlabel("Position [mm]")