
params = LoadBrukerData("C:\Users\kpqv532\OneDrive - University of Leeds\SharedDataSets\YasamanData\MRF_23052025\12",false);
%% Set-up LUT
T1Range = [ ...
    0.050:0.010:0.300, ...
    0.320:0.010:0.500, ...
    0.525:0.010:0.800, ...
    0.850:0.050:2.000, ...
    2.100:0.100:3.000 ...
];    

T2Range = unique([0.002:0.0005:0.0295, 0.030:0.005:0.600]);

[TT1, TT2] = ndgrid(T1Range, T2Range);
mask = TT1 >= TT2;
LUT  = [TT1(mask), TT2(mask)];
NDictionaryEntries = size(LUT,1);

%% ⚠️ MODIFY THE TIME POINTS TO MATCH YOUR SIGNAL
% Goal: Make dictionary have 1500 time points
NPrep = size(prepList,1);  %% <-- MOVED here to compute below
NPerPrep = ceil(targetTimePoints / NPrep);   %% <-- ADDED/UPDATED
params.NPointsPerPrep = NPerPrep;            %% <-- ADDED/UPDATED
totalTimePoints = NPrep * NPerPrep;          %% <-- ADDED

dict = complex(zeros(totalTimePoints, NDictionaryEntries));  %% <-- MODIFIED

%% Set up FA train to match time points
FAList = repmat(params.MRFFA, ceil(totalTimePoints / length(params.MRFFA)), 1);  %% <-- MODIFIED
FAList = FAList(1:totalTimePoints);  %% <-- MODIFIED

phi    = linspace(-pi,pi,200);   % NSpin = 200
rg     = arrayfun(@(ph) rotmat([0 0 ph]), phi, 'UniformOutput', false);
Rg     = blkdiag(rg{:});

TR     = params.TR;
TE     = params.TE;
waitTs = params.MRFWaitingTimes;

tic
for idx = 1:NDictionaryEntries
    T1Tmp = LUT(idx,1);
    T2Tmp = LUT(idx,2);

    M = zeros(3, 200);  M(3,:) = 1;

    entryPtr = 1;
    faCnt    = 1;
    for p = 1:NPrep
        if prepList(p,1)==0
            M = T1PrepModuleInstantRF(M, prepList(p,2)/1e3, params.T1PrepSpoiler.NCycles*2, T1Tmp, T2Tmp);
        else
            M = T2PrepModuleInstantRF(M, prepList(p,2), params.T2PrepSpoiler.NCycles*2, T1Tmp, T2Tmp);
        end

        for f = 1:NPerPrep
            R  = RotateTheta(deg2rad(FAList(faCnt)), 0);
            M  = R*M;
            [A,B] = freeprecess(TE, T1Tmp, T2Tmp);
            M  = A*M + B;
            dict(entryPtr, idx) = -1i * mean(M(1,:) + 1i*M(2,:));
            [A,B] = freeprecess(TR-TE, T1Tmp, T2Tmp);
            M  = A*M + B;
            M  = Rg * M(:);
            M  = reshape(M, [3, 200]);
            faCnt    = faCnt + 1;
            entryPtr = entryPtr + 1;
        end

        [A,B] = freeprecess(waitTs(p), T1Tmp, T2Tmp);
        M = A*M + B;
    end
end
toc

%% ✅ Save
save('veryFine_MRF_dictionary_1500tp.mat', 'dict', 'LUT', 'T1Range', 'T2Range');

%% ✅ Optional: quick check
figure; plot(abs(dict(:,end))); title('Dictionary signal length check');
xlabel('Time points'); ylabel('|Signal|');
