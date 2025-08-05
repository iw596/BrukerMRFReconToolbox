addpath(genpath(".\."))
pth = "C:\Users\kpqv532\OneDrive - University of Leeds\20250801_085320_MRF_Phantom_MRFDev_01082025_1_38\20";
params = LoadBrukerData(pth,false);   
% Set-up starting magnetization
M = zeros([3,NSpin]);
M(3,:) = 1;
NSpin = 200;
gyro = 42.577e6; %Hz/T
thickness = params.Thickness;
df = 0;
dp = zeros([NSpin,3]); 
dp(:,3) = linspace(-1e-3,1e-3,NSpin)*100; % Multiply by 100 to get from m to cm
dv = 0;
NPos = NSpin;
dt = 10e-6;
refPower = params.RefPow;
refVol = sqrt(refPower*50);
% Calculate pulse B1 required to achieve pi/2 flip
% for 1 ms block pulse
refB1 = (pi/2)./(2*pi*42.57*10^6*1e-3); % Peak B1 in T
% Calculate pulse peak voltage assuming 50 ohm load
pulsePeakVoltage = sqrt(params.MRFInversionPulse.power * 50);
% Peak B1 of pulse is refB1/refvoltage * pulse peak voltage
peakB1 = (refB1./refVol) .*  pulsePeakVoltage; % in T
[mag,phs] = ReadRFPulseFile("BrukerRFFiles\sech.inv");
T2PrepInversionRF = peakB1.*mag./max(mag).*exp(1j.*deg2rad(phs));
T2PrepInversionRF = InterpolateRFWaveform(T2PrepInversionRF,params.MRFT2InversionPulse.duration,params.MRFT2InversionPulse.duration/length(mag),dt);
T2PrepInversionB1 = T2PrepInversionRF * gyro;
T1Tmp = 1.5;
T2Tmp = 50e-3;
[mx,my,mz] = bloch_Hz(T2PrepInversionB1,zeros(length(T2PrepInversionB1),1),dt,T1Tmp,T2Tmp,df,dp,dv,0,M(1,:),M(2,:),M(3,:));
figure(12);
subplot(1,2,1); plot(mz);
subplot(1,2,2); plot(mx)