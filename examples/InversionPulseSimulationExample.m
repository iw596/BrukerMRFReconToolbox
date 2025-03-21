params = LoadBrukerData("datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/11",false);
T1 = [100e-3:100e-3:3000e-3];
T2_1 = 200e-3;
T2_2 = 50e-3;
T2_3 = 15e-3;

NSpin = 200;
pos = linspace(-1e-3,1e-3,NSpin);
signalFullSimulationT2_1 = zeros(size(T1));
signalFullSimulationT2_2 = zeros(size(T1));
signalFullSimulationT2_3 = zeros(size(T1));

TI = 21e-3;
for i = 1:size(T1,2)
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = SimulateT1PrepSech(params,TI,M,pos,T1(i),T2_1);
    signalFullSimulationT2_1(i) = mean(M(3,:));

    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = SimulateT1PrepSech(params,TI,M,pos,T1(i),T2_2);
    signalFullSimulationT2_2(i) = mean(M(3,:));

    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = SimulateT1PrepSech(params,TI,M,pos,T1(i),T2_3);
    signalFullSimulationT2_3(i) = mean(M(3,:));
end

figure(1); 
plot(T1,signalFullSimulationT2_1,'Color','blue')
hold on;
plot(T1,signalFullSimulationT2_2,'Color','red')
hold on;
plot(T1,signalFullSimulationT2_3,'Color','green')