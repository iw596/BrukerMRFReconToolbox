%% Script to test T2 preparation module
params = LoadBrukerData("datasets/20250317_095411_MRF_Phantom_MRF_Dev_17032025_1_11/11",false);
NSpin = 200;
T1 = 1400;
T2 = [1:1:10 10:10:400];

signalSimpleSimulationTE40 = zeros(size(T2));

TE = 40;
dt = 1e-3;
pos = linspace(-1e-3,1e-3,NSpin);
for i = 1:size(T2,2)
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = SimulateAdiabaticT2Prep(params,TE,M,pos,T1,T2(i),true);
    signalSimpleSimulationTE40(i) = mean(M(3,:));
end

