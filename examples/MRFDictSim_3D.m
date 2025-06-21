%% Script to calculate dictionary,  incorporating position 


%% Load data 
params = LoadBrukerData("datasets/20250411_152139_MRF_Phantom_MRF_3D_Experiment_11042025_1_17/14",false);
prepList = ReadMRFPrepList("datasets\20250411_152139_MRF_Phantom_MRF_3D_Experiment_11042025_1_17/14/MRFPrepList.txt");


%% Create LUT
T1Range = [100e-3:100e-3:2000e-3];
T2Range = [10e-3:5e-3:200e-3];
B1Range = [0.9:0.025:1.1];
% Exclude T2 > T1
NDictionaryEntries = 0 ;
% Prepare look-up table containing all valid pairs
LUT = [];
for kk = 1:length(B1Range)
    for ii = 1:length(T1Range)
        for jj = 1:length(T2Range)
            % Only keep physically feasible pairs (i.e. T1 > T2)
            if (T1Range(ii)>=T2Range(jj))
                LUT(NDictionaryEntries+1,[1:3]) = [T1Range(ii),T2Range(jj),B1Range(kk)];
                NDictionaryEntries = NDictionaryEntries + 1;
            end
        end
    end
end


%% Set-up spin system and simulation parameters
NSpin = 150;
thickness = 2e-3;
pos = linspace(-thickness/2,thickness/2,NSpin);
NExc = params.NPointsPerPrep * size(prepList,1);
NPrep = size(prepList,1);
NPointsPerPrep = params.NPointsPerPrep; 
% Format FA array
FAList = repmat(params.MRFFA, ceil((params.NPointsPerPrep * size(prepList,1)) / length(params.MRFFA)), 1);
% Truncate FAList to correct dimensions
FAList = FAList(1:params.NPointsPerPrep * size(prepList,1));
waitTimes = params.MRFWaitingTimes;
dt = 10e-6; % 10us sampling raster
gamma = 42.57*10^6; % Gyromagnetic constant of 1H is MHz/T
TR = params.TR;
TE = params.TE;
%% Set-up spoiler gradient
G = GenSliceSpoiler(params.MRFSpoiler.amplitude/1000,params.MRFSpoiler.duration/1000,params.RiseTime,dt);

%% Set-up inversion RF pulse
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

%% Set-up dictionary to store results
dict = zeros(size(prepList,1) * params.NPointsPerPrep,size(LUT,1));
NDict = size(dict,2);
NTimePoints = size(dict,1);
% Pre-slice LUT to avoid broadcasting the LUT in the parfor
T1List = LUT(:, 1);
T2List = LUT(:, 2);
B1List = LUT(:, 3);
parfor i = 1:size(dict,2)
   % Set-up starting magnetization
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    signal = zeros(NTimePoints, 1);  % local temporary variable
    T1Tmp = T1List(i);
    T2Tmp = T2List(i);
    B1Tmp = B1List(i);
    
    curEntry = 1;
    for p = 1:NPrep
        if (prepList(p,1) == 0)
            %M = SimulateT1PrepSech(i params,prepList(p,2)/1000,M,pos,T1,T2,true);
           % M = SimulateInversion(M,T1Tmp,T2Tmp,prepList(p,2)/1000.);
            M = SimulateInversionModule(prepList(p,2)/1000,M,T1Tmp,T2Tmp,pos,params,dt,true,false,InversionRF);
        elseif (prepList(p,1) == 1)
            % M = T2PrepModuleInstantRF(M,prepList(p,2),T2PrepModSpoilerCycles,T1,T2);
            %M = SimulateT2Prep(M,prepList(p,2),NSpin,2,T1Tmp,T2Tmp);
        end
        for f = 1:NPointsPerPrep
            % Excitation
            R = RotateTheta(deg2rad(FAList(curEntry)).*B1Tmp,0);
            M = R*M;
            % Relax until TE
            [A,B] = freeprecess(TE,T1Tmp,T2Tmp);
            M = A*M + B; 
            signal(curEntry) = mean(complex(M(1,:),M(2,:)));
            % Relax until spoiler
            [A,B] = freeprecess(TR - TE - params.MRFSpoiler.duration/1000 - 2*params.RiseTime,T1Tmp,T2Tmp);
            M = A*M + B;
            % Apply spoiling as rotation in z direction
            [A,B] = freeprecess(dt,T1Tmp,T2Tmp);
            for curPos = 1:size(M,2)
                for curG = 1:length(G)
                    RG = zrot(-2*pi*gamma*pos(curPos)*G(curG)*dt);
                    M(:,curPos) = RG*M(:,curPos);
                    M(:,curPos) = A*M(:,curPos) + B;
                end
            end
            curEntry = curEntry + 1;
        end
    end
     dict(:, i) = signal;  % Assign entire column
end

save("Dictionaries/Dict1","dict","LUT");

