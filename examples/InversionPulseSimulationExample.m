addpath(genpath("."))
params = LoadBrukerData("datasets/20250318_102411_MRF_Phantom_MRF_Phantom_Dev_18032025_1_12/63",false);
T1 = [100e-3:100e-3:3000e-3];
T2_1 = 200e-3;
T2_2 = 50e-3;
T2_3 = 25e-3;

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
InversionRF = peakB1.*mag./max(mag).*exp(1j.*deg2rad(phs));
dt = 10e-6;
% dt = params.MRFInversionPulse.duration/length(mag);
InversionRF = InterpolateRFWaveform(InversionRF,params.MRFInversionPulse.duration,params.MRFInversionPulse.duration/length(mag),dt);
t = dt*(0.5 + [0:length(InversionRF)-1]);
NSpin = 200;
pos = linspace(-1e-3,1e-3,NSpin);
signalFullSimulationT2_1 = zeros(size(T1));
signalFullSimulationT2_2 = zeros(size(T1));
signalFullSimulationT2_3 = zeros(size(T1));

TI = 21e-3;
for i = 1:size(T1,2)
    Magnetization.M = zeros([3,NSpin]);
    %Magnetization.M(3,:) = 1;
    %Magnetization.T1 = T1(i);
    %Magnetization.T2 = T2_2;
    %M2 = SimulateT1PrepSech(params,TI,Magnetization.M ,pos,T1(i),T2_2);
    %M = SimulateInversionModule(TI,Magnetization,pos,params,dt,true,false,InversionRF);
    %signalFullSimulationT2_1(i) = mean(M(3,:));
    %signalFullSimulationT2_2(i) = mean(M2(3,:));
    % 
    % M = zeros([3,NSpin]);
    % M(3,:) = 1;
    % M = SimulateT1PrepSech(params,TI,M,pos,T1(i),T2_2);
    % signalFullSimulationT2_2(i) = mean(M(3,:));
    % 
    % M = zeros([3,NSpin]);
    % M(3,:) = 1;
    % M = SimulateT1PrepSech(params,TI,M,pos,T1(i),T2_3);
    % signalFullSimulationT2_3(i) = mean(M(3,:));
end

figure(6); 
plot(T1,signalFullSimulationT2_1,'Color','blue')
hold on;
plot(T1,signalFullSimulationT2_2,'Color','red')
hold on;
plot(T1,signalFullSimulationT2_3,'Color','green')

tic
M = SimulateT1PrepSech(params,TI,M,pos,T1(i),T2_1);
toc

tic 
R = RotateTheta(pi,0);
R*M;
toc