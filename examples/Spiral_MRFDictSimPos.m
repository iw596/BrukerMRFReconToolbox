params = LoadBrukerData("C:\Users\kpqv532\OneDrive - University of Leeds\20250602_110808_MRF_Phantom_MRF_Dev_02062025_1_30\10",true);

% Read preplist and preptimes
prepList = ReadMRFPrepList("C:\Users\kpqv532\OneDrive - University of Leeds\20250602_110808_MRF_Phantom_MRF_Dev_02062025_1_30\PrepList.txt");



%% Set-up LUT
T1Range = [100e-3:10e-3:2600e-3];
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
gyro = 42.577e6;
thickness = params.Thickness;
pos = linspace(-thickness,thickness,NSpin);

%% Extract useful timing parameters
TR = params.TR;
TE = params.TE ;
RiseT = params.RiseTime;
dt = 10e-6;

%% Generate spoiler for inversion module
flatTime = params.T1PrepSpoiler.duration - RiseT;
amplitude = (params.PVM_GradCalConst *  (params.T1PrepSpoiler.amplitude/100))*1000/gyro;
spoiler_inv = GenSliceSpoiler(amplitude,flatTime,RiseT,dt);

%% Generate spoiler for acquisition






% Format FA array
FAList = repmat(params.MRFFA, ceil((params.NMRFFA * size(prepList,1)) / length(params.MRFFA)), 1);
% Truncate FAList to correct dimensions
FAList = FAList(1:params.NMRFFA * size(prepList,1));



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
            % Instant inversion
            % Apply spoiler
            % Delay for time TI
        elseif (prepList(p,1) == 1)
        end
       % Run through the correct portion of the FA train
         for f = 1:NPointsPerPrep
            R = RotateTheta(deg2rad(FAList(faCounter)).*B1Tmp,0);
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
            for j = 1:NSpin
                M(:,j) = zrot(phi(j)) * M(:,j);
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

save("Dictionaries\SpiralDict_Positions","dict","LUT");