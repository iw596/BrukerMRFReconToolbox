%% Another MATLAB script to perform dictionary simulation....

%% Set-up path
addpath(genpath("./"))

%% Load in MRF file


%% Define simulation parameters
thickness = 1e-3; %% Thickness in m
NSpin = 200; % Number of spins to simulation
pos = zeros(3,NSpin); %x,y and z positions
pos(3,:) = linspace(-thickness/2,thickness/2,NSpin);
dt = 10e-3; % Simulation raster time
%% Set-up simulation flags
instantPrep = true;
instantRF = true;


%% Set-up T1,T2 and B1 list
T1Range = [100e-3:5e-3:1.5, 1.5:100e-3:2.5]; % in seconds
T2Range = [10e-3:5e-3:100e-3 100e-3:10e-3:250e-3]; % in seconds
B1Range = [1];

%% Set-up LUT
LUT = [];
NDictionaryEntries = 0;
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

%% Load inversion waveform if required

%% Load Excitation waveform if required

%% Load gradient spoiler waveform

%% Set-up Flip angle train



%% Run dictionary simulation
for i = size(LUT,1)
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    Magnetization.M = M;
    Magnetization.T1 = LUT(i,1);
    Magnetization.T2 = LUT(i,2);



end