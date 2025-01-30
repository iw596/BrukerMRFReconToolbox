%% Function performing a very simple simulation of an inversion pulse
%% we assume perfect inversion efficieny
function MNew = SimulateInversion(MOrig,T1,T2,TI)
MNew = MOrig;
%Invert magnetization    
MNew(3,:) = MOrig(3,:) .* -1;
% Precess magnetization for inverstion time (TI)
[A,B] = freeprecess(TI,T1,T2);
MNew = A*MNew + B;
end