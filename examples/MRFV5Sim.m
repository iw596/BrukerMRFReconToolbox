addpath(genpath("../."))

params = LoadBrukerData("datasets/20250318_102411_MRF_Phantom_MRF_Phantom_Dev_18032025_1_12/63",false);


% Read preplist and preptimes
prepList = ReadMRFPrepList("datasets\20250318_102411_MRF_Phantom_MRF_Phantom_Dev_18032025_1_12/63/MRFPrepList.txt");


%% Set-up LUT

%T1Range = [40e-3:10e-3:90e-3, 100e-3:20e-3:1 , 1:40e-3:2, 2050e-3:100e-3:2.4];
%T2Range = [10e-3:5e-3:100e-3,110e-3:10e-3:300e-3, 350e-3:50e-3:550e-3];
%B1Range = [0.9:0.02:1.1];
%T1Range = 50e-3:100e-3:2.5;
%T2Range =5e-3:10e-3:550e-3;

T1Range = [20e-3:10e-3:100e-3 100e-3:25e-3:2.4];
T2Range = (10e-3:10e-3:550e-3);
B1Range = (1);
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


gg= GenSliceSpoiler(params.MRFSpoiler.amplitude/1000,params.MRFSpoiler.duration/1000,params.RiseTime,10e-5);

NSpin = 200;
phi = linspace(-pi,pi,NSpin);
TR = params.TR;
TE = params.TE;
% Format FA array
FAList = repmat(params.MRFFA, ceil((params.NPointsPerPrep * size(prepList,1)) / length(params.MRFFA)), 1);

% Truncate FAList to correct dimensions
FAList = FAList(1:params.NPointsPerPrep * size(prepList,1));

%%% Gradient dephasing matrix
rg={};
for jj=1:NSpin
    rg{jj} = rotmat([0 0 phi(jj)]);
end
Rg = blkdiag(rg{:});


waitTimes = params.MRFWaitingTimes;
dict = zeros(size(prepList,1) * params.NPointsPerPrep,size(LUT,1));
InversionModSpoilerCycles =params.T1PrepSpoiler.NCycles*2;
T2PrepModSpoilerCycles = params.T2PrepSpoiler.NCycles*2;
NPointsPerPrep = params.NPointsPerPrep;
NPrep = size(prepList,1);
tic
for i = 1:size(LUT,1)
    i
    T1Tmp = LUT(i,1);
    T2Tmp = LUT(i,2);
    B1Tmp = LUT(i,3);
    % Set-up starting magnetization
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    curEntry = 1;
    faCounter = 1;
     % Run through prep modules
    for p = 1:NPrep
        if (prepList(p,1) == 0)
            M = T1PrepModuleInstantRF(M,prepList(p,2)/1000,InversionModSpoilerCycles,T1Tmp,T2Tmp);
            %M = SimulateInversion(M,T1Tmp,T2Tmp,prepList(p,2));
        elseif (prepList(p,1) == 1)
            M = T2PrepModuleInstantRF(M,prepList(p,2),T2PrepModSpoilerCycles,T1Tmp,T2Tmp);
            %M = SimulateT2Prep(M,prepList(p,2),NSpin,2,T1Tmp,T2Tmp);
        end
       % Run through the correct portion of the FA train
        for f = 1:NPointsPerPrep
            R = RotateTheta(deg2rad(FAList(faCounter)).*B1Tmp,0);
            %R = throt(FAList(faCounter).*B1Tmp,0);
            M = R*M;
            % Precess to TE
            [A,B] = freeprecess(TE,T1Tmp,T2Tmp);
            M = A*M + B; 
            % Store signal 
            dict(curEntry,i) =-1i * mean(complex(M(1,:),M(2,:)));
            % Precess until next TR
            [A,B] = freeprecess(TR - TE,T1Tmp,T2Tmp);
            M = A*M + B;

            % Apply spoiling as rotation in z direction
            for j = 1:NSpin
                M(:,j) = zrot(phi(j)) * M(:,j);
                %M(:,j) = rotmat([0 0 phi(j)]) * M(:,j);
            end
            faCounter = faCounter + 1;
            curEntry = curEntry + 1;
        end
        
        % Wait for delay time
        [A,B] = freeprecess(waitTimes(p),T1Tmp,T2Tmp);
        %[A,B] = freeprecess(500,T1Tmp,T2Tmp);
        M = A*M + B;

    end

end
toc
save("datasets/20250324_111056_MRF_Phantom_MRF_Dev_24052025_1_14\dictWB1","dict","LUT")
figure; plot(abs(dict(:,end)))