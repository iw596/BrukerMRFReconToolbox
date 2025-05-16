%% Script to test T2 preparation module
params = LoadBrukerData("datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/11",false);
NSpin = 200;
T1 = 1.3;
T2 = 88e-3;
TE = [15e-3 30e-3 50e-3 80e-3 150e-3 300e-3];
TE1 = 15e-3;
TE2 = 80;
TE3 = 40;
TE4 = 20;
dt = 1e-3;
signal= []
 M = zeros([3,NSpin]);
 M(3,:) = 1;
for i = 1:size(TE,2)
    M = T2PrepModule(M,TE(i),T1,T2);
    signal(i) = mean(M(3,:));
    M = ApplyFreePrecession(M,T1,T2,2.5);
end


figure(1);
plot(TE,signal)

fT2 = @(a)(a(1) .* exp(-TE/a(2)) - (signal));

pdInit = 1;
t2Init = 10e-3;
[C] = lsqnonlin(fT2,[pdInit t2Init 0],[],[],options);


