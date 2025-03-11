addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")
addpath("FileIO\")
addpath("MRF\")


T1Range = [100:300:2600 2300];
T2Range = [10:50:450 488];
B1Range = [1];
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

% Read FA train
[FA,~] = ReadMRFList("datasets\20250211_141529_IW_Phantom_NiCl2_MRF_Dev_11_02_2025_1_5\MRFPattern.txt");
% Read preplist and preptimes
prepList = ReadMRFPrepList("datasets\20250211_141529_IW_Phantom_NiCl2_MRF_Dev_11_02_2025_1_5\MRFPrep.txt");
% Read method file
params = LoadBrukerData("datasets\20250211_141529_IW_Phantom_NiCl2_MRF_Dev_11_02_2025_1_5\35");

tic
NSpin = 200;
phi = linspace(-pi,pi,NSpin);
dict = zeros(length(prepList) * length(FA),length(LUT));
TR = params.TR * 1000;
TE = params.TE * 1000;
dict = [];
InversionModSpoilerCycles =params.InversionSpoilerNCycles*2;
T2PrepModSpoilerCycles = params.T2PrepSpoilerNCycles * 2;
for i = 1:size(LUT,1)
    i
    T1Tmp = LUT(i,1);
    T2Tmp = LUT(i,2);
    B1Tmp = LUT(i,3);
    % Set-up starting magnetization
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    curEntry = 1;
 
    % Run through prep modules
    for p = 1:size(prepList,1)
        if (prepList(p,1) == 0)
           % M = SimulateInversion(M,T1Tmp,T2Tmp,prepList(p,2));
            M = T1PrepModuleInstantRF(M,prepList(p,2),InversionModSpoilerCycles,T1Tmp,T2Tmp);
        elseif (prepList(p,1) == 1)
            %M = SimulateT2Prep(M,prepList(p,2),NSpin,2,T1Tmp,T2Tmp);
            M = T2PrepModuleInstantRF(M,prepList(p,2),T2PrepModSpoilerCycles,T1Tmp,T2Tmp);
        end
        % Run through the FA train
        for f = 1:length(FA)
           % R = throt(FA(f).*B1Tmp,0);
            R = RotateTheta(deg2rad(FAList(f)).*B1Tmp,0);
            %R = throt(FAList(faCounter).*B1Tmp,0);
           M = R*M;
            % Precess to TE
            [A,B] = freeprecess(TE,T1Tmp,T2Tmp);
            M = A*M + B;
            % Store signal 
            dict(curEntry,i) = -1i*mean(complex(M(1,:),M(2,:)));
            % Precess until next TR
            [A,B] = freeprecess(TR - TE,T1Tmp,T2Tmp);
            M = A*M + B;

            % Apply spoiling as rotation in z direction
            for j = 1:NSpin
                M(:,j) = zrot(phi(j)) * M(:,j);
            end
            
            curEntry = curEntry + 1;
        end
        % Wait for 500ms
        [A,B] = freeprecess(500,T1Tmp,T2Tmp);
        M = A*M + B;
    end
end
toc