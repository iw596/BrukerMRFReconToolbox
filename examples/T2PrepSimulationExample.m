%% Script to test T2 preparation module
params = LoadBrukerData("datasets/20250311_095117_MRF_Phantom_MRF_dev_11032025_1_8/11",false);
NSpin = 200;
T1 = 1400;
T2 = [1:1:4 5:5:200];
signalFullSimulationTE150 = zeros(size(T2));
signalSimpleSimulationTE150 = zeros(size(T2));
signalFullSimulationTE80 = zeros(size(T2));
signalSimpleSimulationTE80 = zeros(size(T2));
signalFullSimulationTE40 = zeros(size(T2));
signalSimpleSimulationTE40 = zeros(size(T2));
signalFullSimulationTE20 = zeros(size(T2));
signalSimpleSimulationTE20 = zeros(size(T2));
TE1 = 150;
TE2 = 80;
TE3 = 40;
TE4 = 20;
dt = 1e-3;
pos = linspace(-1e-3,1e-3,NSpin);
for i = 1:size(T2,2)
    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = SimulateT2PrepMLEV4(params,TE1,dt,M,pos,T1,T2(i));
    signalFullSimulationTE150(i) = mean(M(3,:));

    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = T2PrepModuleInstantRF(M,TE1,0,T1,T2(i));
    signalSimpleSimulationTE150(i) = mean(M(3,:));

    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = SimulateT2PrepMLEV4(params,TE2,dt,M,pos,T1,T2(i));
    signalFullSimulationTE80(i) = mean(M(3,:));

    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = T2PrepModuleInstantRF(M,TE2,0,T1,T2(i));
    signalSimpleSimulationTE80(i) = mean(M(3,:));

    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = SimulateT2PrepMLEV4(params,TE3,dt,M,pos,T1,T2(i));
    signalFullSimulationTE40(i) = mean(M(3,:));

    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = T2PrepModuleInstantRF(M,TE3,0,T1,T2(i));
    signalSimpleSimulationTE40(i) = mean(M(3,:));

    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = SimulateT2PrepMLEV4(params,TE4,dt,M,pos,T1,T2(i));
    signalFullSimulationTE20(i) = mean(M(3,:));

    M = zeros([3,NSpin]);
    M(3,:) = 1;
    M = T2PrepModuleInstantRF(M,TE4,0,T1,T2(i));
    signalSimpleSimulationTE20(i) = mean(M(3,:));

end


figure(1);
plot(T2,signalFullSimulationTE150,"Color","red","LineStyle","-")
hold on;
plot(T2,signalSimpleSimulationTE150,"Color","black","LineStyle","--")
hold on
plot(T2,signalFullSimulationTE80,"Color","red","LineStyle","-")
hold on;
plot(T2,signalSimpleSimulationTE80,"Color","black","LineStyle","--")
hold on
plot(T2,signalFullSimulationTE40,"Color","red","LineStyle","-")
hold on;
plot(T2,signalSimpleSimulationTE40,"Color","black","LineStyle","--")
hold on
plot(T2,signalFullSimulationTE20,"Color","red","LineStyle","-")
hold on;
plot(T2,signalSimpleSimulationTE20,"Color","black","LineStyle","--")