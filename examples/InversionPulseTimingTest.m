%% Script to compare speed of matlab inversion module against C implementation
addpath(genpath("."))
%% Load parameters
params = LoadBrukerData("datasets/20250318_102411_MRF_Phantom_MRF_Phantom_Dev_18032025_1_12/63",false);
%% Set-up simulation parameters
dt = 10^(-6);
T1 = 2.5;
T2 = 15e-3;
TI = 1500e-3;
gyro = 42.57e6;
NSpin = 200;
%% Generate inverstion pulse
refPower = params.RefPow;
refVol = sqrt(refPower*50);
% Calculate pulse B1 required to achieve pi/2 flip
% for 1 ms block pulse
refB1 = (pi/2)./(2*pi*42.57*10^6*1e-3); % Peak B1 in T
pulsePeakVoltage = sqrt(params.MRFInversionPulse.power * 50);% Calculate pulse peak voltage assuming 50 ohm load
% Peak B1 of pulse is refB1/refvoltage * pulse peak voltage
peakB1 = (refB1./refVol) .*  pulsePeakVoltage; % in T
[mag,phs] = ReadRFPulseFile("BrukerRFFiles\sech.inv");
InversionRF = peakB1.*mag./max(mag).*exp(1j.*deg2rad(phs));
InversionRF = InterpolateRFWaveform(InversionRF,params.MRFInversionPulse.duration,params.MRFInversionPulse.duration/length(mag),dt);

%% Generate spoiler for inversion module
riseTime = params.RiseTime; 
flatTime = params.T1PrepSpoiler.duration - riseTime;
amplitude = (params.PVM_GradCalConst *  (params.T1PrepSpoiler.amplitude/100)); % Hz/mm
amplitude =  amplitude * 1000; % Hz/m
amplitude = amplitude./gyro; % Hz/m -> T/m
spoiler_inv = GenSliceSpoiler(amplitude,flatTime,riseTime,dt);
d1 = TI - (flatTime + 2*riseTime) - params.MRFInversionPulse.duration/2;


M = zeros(3,NSpin);
M(3,:) = 1;
pos = zeros([NSpin,3]); 
pos(:,3) = linspace(-1e-3,1e-3,NSpin);
%% Matlab implementation
tic
    M = RFExcitation(M,T1,T2,dt,InversionRF);
    % Apply spoiling as rotation in z direction
     for ii = 1:NSpin
         for jj = 1:length(spoiler_inv)
              Rz = zrot(2*pi*gyro*spoiler_inv(jj)*pos(ii,3)*dt);
              M(:,ii) = Rz *M(:,ii);
         end
     end
   % M = ApplyFreePrecession(M,T1,T2,d1);
toc


%% C bloch sim
NPointsDelay = round(d1/dt);
B1_RF = InversionRF.*gyro; % Convert from T to Hz
B1_spoil = zeros([length(spoiler_inv),1]);
B1_delay = zeros(NPointsDelay,1);
B1 = [B1_RF.'; B1_spoil];
G_RF = zeros([length(B1_RF),3]);
G_Spoil = zeros([length(spoiler_inv),3]);
G_Spoil(:,3) = spoiler_inv;

G = [G_RF;G_Spoil];
G = (G.*gyro)/100;
df = 0;
dp = zeros([NSpin,3]); 
dp(:,3) = linspace(-1e-3,1e-3,NSpin)*100; % Multiply by 100 to get from m to cm
dv = 0;


mx = zeros(NSpin,1);
my = zeros(NSpin,1);
mz = ones(NSpin,1);

tic
    [mx,my,mz] = bloch_Hz(B1,G,dt,T1,T2,df,dp,dv,0,mx,my,mz);
    %MTmp = ApplyFreePrecession([mx my mz].',T1,T2,d1);
toc
mz = MTmp(3,:);


figure(10);
plot(M(3,:)); hold on; plot(mz);