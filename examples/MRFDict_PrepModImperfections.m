%% Simulation incorporating slice profile


addpath(genpath("../."))

params = LoadBrukerData("datasets/20250318_102411_MRF_Phantom_MRF_Phantom_Dev_18032025_1_12/63",false);


% Read preplist and preptimes
prepList = ReadMRFPrepList("datasets\20250318_102411_MRF_Phantom_MRF_Phantom_Dev_18032025_1_12/63/MRFPrepList.txt");


%% Set-up LUT
%T1Range = [10e-3:10e-3:100e-3 100e-3:50e-3:2.6];
%T2Range = [10e-3:10e-3:450e-3];
T1Range = 1.5;
T2Range = 50e-3;
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
pos = linspace(-params.Thickness,params.Thickness,NSpin);
grad_dt = 10e-6;
GSpoil = GenSliceSpoiler(params.MRFSpoiler.amplitude/1000,params.MRFSpoiler.duration/1000,params.RiseTime,grad_dt);
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

% Convert preplist times from ms to s
prepList(:,2) = prepList(:,2)/1000;
waitTimes = params.MRFWaitingTimes;
dict = zeros(size(prepList,1) * params.NPointsPerPrep,size(LUT,1));

for i = 1:size(LUT,1)
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
            M = SimulateT1PrepSech(params,prepList(p,2),M,pos,T1Tmp,T2Tmp,true);
            %M = SimulateInversion(M,T1Tmp,T2Tmp,prepList(p,2));
        elseif (prepList(p,1) == 1)
           % M = T2PrepModuleInstantRF(M,prepList(p,2),T2PrepModSpoilerCycles,T1Tmp,T2Tmp);
            %M = SimulateT2Prep(M,prepList(p,2),NSpin,2,T1Tmp,T2Tmp);
        end
       % Run through the correct portion of the FA train
        for f = 1:params.NPointsPerPrep
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
             for cpos = 1:size(M,2)
                for cGrad = 1:length(GSpoil)
                   % Calculate z-rotation due to gradient
                   RG = zrot(2*pi*42.56e6*pos(cpos)*GSpoil(cGrad)*grad_dt);
                   M(:,cpos) = RG*M(:,cpos);
                   M(:,cpos) = A*M(:,cpos) + B;
                end
            end
            faCounter = faCounter + 1;
            curEntry = curEntry + 1;
        end
        
        % Wait for delay time
        [A,B] = freeprecess(waitTimes(p),T1Tmp,T2Tmp);
        M = A*M + B;

    end

end