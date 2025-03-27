%% Run simulation with specific spatial positions

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



NSpin = 200;
thickness = 1e-3;
pos = linspace(-thickness/2,thickness/2,NSpin);
dict = zeros(size(prepList,1) * params.NPointsPerPrep,size(LUT,1));
NExc = params.NPointsPerPrep * size(prepList,1);
NPrep = size(prepList,1);
% Format FA array
FAList = repmat(params.MRFFA, ceil((params.NPointsPerPrep * size(prepList,1)) / length(params.MRFFA)), 1);
% Truncate FAList to correct dimensions
FAList = FAList(1:params.NPointsPerPrep * size(prepList,1));
waitTimes = params.MRFWaitingTimes;
phi = linspace(-pi,pi,NSpin);
pos = linspace(-1e-3,1e-3,NSpin);

tic
parfor i = 1:size(dict,2)
    i
    T1Tmp = LUT(i,1);
    T2Tmp = LUT(i,2);
    B1Tmp = LUT(i,3);
    % Set-up starting magnetization
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    curEntry = 1;
    %dict(:,i) = CalcDictionaryEntry(T1Tmp,T2Tmp,B1Tmp,prepList,FAList,waitTimes,M,phi,params);
    dict(:,i) = CalcDictionaryEntryWithPos(T1Tmp,T2Tmp,B1Tmp,prepList,FAList,waitTimes,M,pos,params);
end
toc

