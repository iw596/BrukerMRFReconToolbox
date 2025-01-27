%% Script to generate dictioanry, assuming instantaneous rotation
addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("FileIO\")

addpath("Fitting\")
% Calculate all T1, T2 and B1 pairs
T1List = [10e-3:5e-3:400e-3];
T2List = [5e-3:1.25e-3:300e-3];
T1Length = length(T1List);
T2Length = length(T2List);
NDictionaryEntries = 0 ;
% Prepare look-up table containing all valid pairs
for ii = 1:T1Length
    for jj = 1:T2Length
        % Only keep physically feasible pairs (i.e. T1 > T2)
        if (T1List(ii)>=T2List(jj))
            LUT(NDictionaryEntries+1,[1:2]) = [T1List(ii),T2List(jj)];
            NDictionaryEntries = NDictionaryEntries + 1;
        end
    end
end


parfor d = 1:length(LUT)
    TR = 17e-3;
    TE = 4e-3;
    T1 = LUT(d,1);
    T2 = LUT(d,2);
    [FATrain,~] = ReadMRFList("C:\Users\isaac\OneDrive - University of Leeds\MRF_FA_Patterns\MRFPattern.txt");
    prepList = [0,0,0,1,1,1];
    prepTimes = [25e-3,55e-3,120e-3,100e-3,80e-3,40e-3];
    waitTime = 100e-3;
    NIso = 400;
    phi = linspace(-pi,pi,NIso); 
    dT = 10e-6; % Simulation step-size
    M = zeros([3,NIso]);
    M(3,:) = 1;
    MOld = [];
    MEcho = [];
    counter = 1;
    for p = 1:length(prepList)
        if (prepList(p) == 0)
            R = throt(180,0.0);
            M = R*M;
            % Free-precession of duration inversion time
            invT = prepTimes(p);
            nSteps = round(invT /dT);
            [A,B] = freeprecess(invT,T1,T2);
            M = A*M + B;
        elseif (prepList(p) == 1) 
            T2PrepTE = prepTimes(p);
            % T2-prep
            R = throt(90,0.0);
            M = R*M;
            % Precess by TE/8
            [A,B] = freeprecess(T2PrepTE/8,T1,T2);
            M = A*M + B;
            R = throt(180,90);
            M = R*M;
            
            % Precess by TE/4
            [A,B] = freeprecess(T2PrepTE/4,T1,T2);
            M = A*M + B;
            R = throt(180,90);
            M = R*M;
    
            % Precess by TE/4
            [A,B] = freeprecess(T2PrepTE/4,T1,T2);
            M = A*M + B;
            R = throt(180,270);
            M = R*M;
    
            % Precess by TE/4
            [A,B] = freeprecess(T2PrepTE/4,T1,T2);
            M = A*M + B;
            R = throt(180,270);
            M = R*M;
    
            % Precess by TE/8
            [A,B] = freeprecess(T2PrepTE/8,T1,T2);
            M = A*M + B;
            R = throt(90,180);
            M = R*M;
    
        end
        % FA train
        for f = 1:length(FATrain)
            % Apply RF rotation
            R = throt(FATrain(f),0);
            M = R*M;
            % Precess to echo and store result
            [A,B] = freeprecess(TE,T1,T2);
            M = A*M + B;
            % Store signal 
            MEcho(counter) = mean(complex(M(1,:),M(2,:)));
            counter = counter+1;
            % Precess until next TR
            [A,B] = freeprecess(TR - TE,T1,T2);
            M = A*M + B;
            % Apply spoiling as rotation in z direction
            for j = 1:NIso
                M(:,j) = zrot(phi(j)) * M(:,j);
            end
        end
        % Wait time between prep-modules
        [A,B] = freeprecess(waitTime,T1,T2);
        M = A*M + B;
    end
    dict(:,d) = MEcho;
end

