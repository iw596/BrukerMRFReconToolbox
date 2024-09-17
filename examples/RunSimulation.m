addpath("Simulations\")

%% Script to test FISP simulation
tissueParams.T1 = 500; %ms;
tissueParams.T2 = 10; %ms

%% Set-up sequence parameters
seqParams.TI = 0; % ms
seqParams.TR = 10;  %ms
seqParams.TE = 4;   %ms
seqParams.FA = [90];

M_Echo = FISPSimulation(seqParams,tissueParams,1);

