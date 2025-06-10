
addpath(genpath(".\."))
params = LoadBrukerData("C:\Users\isaac\OneDrive - University of Leeds\20250606_122813_MRF_Phantom_MRFDev_06062025_1_31\10",true);

% Read preplist and preptimes
prepList = ReadMRFPrepList("C:\Users\isaac\OneDrive - University of Leeds\20250602_110808_MRF_Phantom_MRF_Dev_02062025_1_30\PrepList.txt");



%% Set-up LUT
T1Range = [100e-3:25e-3:2600e-3];
T2Range = [5e-3:2.5e-3:350e-3];
B1Range = [1];
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

NSpin = 200;
gyro = 42.577e6; %Hz/T
thickness = params.Thickness;
pos = linspace(-thickness/2,thickness/2,NSpin);
NPos = NSpin;
%% Extract useful timing parameters
TR = params.TR;
TE = params.TE ;
RiseT = params.RiseTime;
dt = 10e-6;

%% Simulation Flags
instantInversionFlag = false;


%% Generate spoiler for inversion module
flatTime = params.T1PrepSpoiler.duration - RiseT;
amplitude = (params.PVM_GradCalConst *  (params.T1PrepSpoiler.amplitude/100)); % Hz/mm
amplitude =  amplitude * 1000; % Hz/m
amplitude = amplitude./gyro; % Hz/m -> T/m
spoiler_inv = GenSliceSpoiler(amplitude,flatTime,RiseT,dt);

%% Generate spoiler for acquisition
flatTime =  params.sliceSpoiler.duration - RiseT;
%flatTime = params.sliceSpoiler.duration - RiseT;
amplitude = (params.PVM_GradCalConst *  (params.sliceSpoiler.amplitude/100));
amplitude = amplitude * 1000; % Hz/m
amplitude = amplitude./gyro;
spoiler_acq = GenSliceSpoiler(amplitude,flatTime,RiseT,dt);

%% If required set-up inversion pulse
if (instantInversionFlag == false)
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
    InversionRF = InterpolateRFWaveform(InversionRF,params.MRFInversionPulse.duration,params.MRFInversionPulse.duration/length(mag),dt);
end




nr     = round(RiseT/dt);   % ramp time resolution
nf     = round(flatTime/dt);   % flat top time resolution
ru = (round(1:1:nr)-0.5) / nr;
ft = ones(1, nf);
rd = (round(nr:-1:1)-0.5) / nr;
G  = amplitude * [ru, ft, rd];



%% Adjust preparation timings based on flags
if (instantInversionFlag == false)
    % Adjust all inversion times to account for inversion pulse length
    for p = 1:size(prepList,1)
        if (prepList(p,1) == 0)
             prepList(p,2) = prepList(p,2) - (params.MRFInversionPulse.duration/2 * 1000);
        end
    end

end




% Format FA array
FAList = repmat(params.MRFFA, ceil((params.NMRFFA * size(prepList,1)) / length(params.MRFFA)), 1);
% Truncate FAList to correct dimensions
FAList = deg2rad(FAList(1:params.NMRFFA * size(prepList,1)));



waitTimes = params.MRFWaitingTimes;

InversionModSpoilerCycles =params.T1PrepSpoiler.NCycles*2;
NPointsPerPrep = params.NPointsPerPrep;
dict = zeros(size(prepList,1) * NPointsPerPrep,size(LUT,1));
parfor i = 1:size(LUT,1)
    i
    dictEntry = zeros(size(prepList,1) * NPointsPerPrep,1);
    T1Tmp = LUT(i,1);
    T2Tmp = LUT(i,2);
    B1Tmp = LUT(i,3);
    % Set-up starting magnetization
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    curEntry = 1;
    faCounter = 1;
     % Run through prep modules
    for p = 1:size(prepList,1)
        if (prepList(p,1) == 0)
            if (instantInversionFlag == true)
                % Instant inversion
                M = InstantRFExcitation(M,pi,0);
            else
                M = RFExcitation(M,T1Tmp,T2Tmp,dt,InversionRF);
            end
            % Apply spoiler
            for ii = 1:NPos
                for jj = 1:length(spoiler_inv)
                    Rz = zrot(2*pi*gyro*spoiler_inv(jj)*pos(ii)*dt);
                    M(:,ii) = Rz *M(:,ii);
                end
            end
            % Delay for time TI
            [A,B] = freeprecess(prepList(p,2)/1000,T1Tmp,T2Tmp);
            M = A*M + B; 
        elseif (prepList(p,1) == 1)
        end
       % Run through the correct portion of the FA train
         for f = 1:NPointsPerPrep
            R = RotateTheta(FAList(faCounter).*B1Tmp,0);
            M = R*M;
            % Precess to TE
            [A,B] = freeprecess(TE,T1Tmp,T2Tmp);
            M = A*M + B; 
            % Store signal 
            dictEntry(curEntry) =mean(complex(M(1,:),M(2,:)));
            % Precess until next TR
            [A,B] = freeprecess(TR - TE,T1Tmp,T2Tmp);
            M = A*M + B;

            % Apply spoiling as rotation in z direction
            for ii = 1:NPos
                for jj = 1:length(spoiler_acq)
                    Rz = zrot(2*pi*gyro*G(jj)*pos(ii)*dt);
                    M(:,ii) = Rz *M(:,ii);
                end
            end
            faCounter = faCounter + 1;
            curEntry = curEntry + 1;
        end
        
        % Wait for delay time
        [A,B] = freeprecess(waitTimes(p),T1Tmp,T2Tmp);
        M = A*M + B;

    end
    dict(:,i) = dictEntry;
end

save("Dictionaries\SpiralDict_Positions_inversionRF","dict","LUT");