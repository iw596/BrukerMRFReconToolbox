
addpath(genpath("./."));
params = LoadBrukerData("C:\Users\isaac\OneDrive - University of Leeds\20250606_122813_MRF_Phantom_MRFDev_06062025_1_31\10");
FA = pi/2;
RFwaveform = params.ExcRFShape;
RFDur = params.ExcRFDur;
dt = RFDur/length(RFwaveform);
gamma = 42.577e6;

% Scale waveform
RFwaveform = RFwaveform.*FA/(sum(RFwaveform))/(2*pi*gamma*dt);
% Convert gradient in Hz/mm to T/m
GSliSel = (params.SliceSelGrad * 1000)/(gamma);
GSliRphs = (params.SliceSelRephGrad * 1000)/(gamma);
durSliSel = params.ExcRFDur;
riseTime = params.RiseTime; 
durSliRphs = params.RephGradDur - riseTime;

[RFFull,G] = GenerateExcitationBlock(RFwaveform,GSliSel,GSliRphs,durSliSel,durSliRphs,riseTime,dt);
    



%figure(1);
%plot(real(RFwaveform)); title("RF waveform")


% Set-up spin system
T1 = 2000e-3;
T2 = 50e-3;
NSpin = 200;
pos = zeros(3,NSpin);
pos(3,:) = linspace(-1e-3,1e-3,NSpin);
M = zeros([3,NSpin]);
M(3,:) = 1;
options.gradient_waveform = zeros([3,length(G)]);
options.gradient_waveform(3,:) = G;
options.pos = pos;
% Run simulation
tic
M = RFExcitation(M,T1,T2,dt,RFFull,'gradient_waveform',options.gradient_waveform,'pos',options.pos,'ignore_decay',false);
mTime = toc

% Run MEX simulation
% Convert to Hz and Hz/cm for Bloch simulations
T.gam =    4.2577e+07; % Gyromagnetic ration in Hz/T
B1_Hz        = RFFull     * T.gam;
GSliSel_Hzcm  = options.gradient_waveform * T.gam/100;
pos_cm = (options.pos.*100).';
tic
[mx,my,mz] = bloch_Hz(B1_Hz, GSliSel_Hzcm.', dt, T1, T2, 0, (options.pos.*100).', 0, 0); % Label
mexTime = toc

%M = RFExcitation(RFwaveform,dt,M,G,pos,T1,T2);
Mxy = complex(M(1,:), M(2,:));

figure(3);
subplot(2,2,1); plot(real(Mxy)); xlabel("Position [mm]"); title("real (Mxy)");
subplot(2,2,2); plot(imag(Mxy)); xlabel("Position [mm]"); title("imag (Mxy)");
subplot(2,2,3); plot(M(3,:)); xlabel("Position [mm]"); title("Mz");

figure(4);
subplot(2,2,1); plot(mx); xlabel("Position [mm]"); title("real (Mxy)");
subplot(2,2,2); plot(my); xlabel("Position [mm]"); title("imag (Mxy)");
subplot(2,2,3); plot(mz); xlabel("Position [mm]"); title("Mz");
