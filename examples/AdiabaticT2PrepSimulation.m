%% Script to test T2 preparation module
params = LoadBrukerData("datasets/20250317_095411_MRF_Phantom_MRF_Dev_17032025_1_11/11",false);
NSpin = 200;
T1 = 0.2;
T2 = 10e-3;



TE = [20,30,40,80,120]*10^(-3);
signal = zeros(size(TE,2),1);

dt = 1e-3;
pos = linspace(-1e-3,1e-3,NSpin);
for i = 1:length(TE)
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = T2PrepModule(M,TE(i),T1,T2);
    signal(i) = mean(M(3,:));
end

