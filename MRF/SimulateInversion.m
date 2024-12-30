%% Function performing a very simple simulation of an inversion pulse
%% we assume perfect inversion efficieny
function MNew = SimulateInversion(M)
    MNew = M(3,:) * -1;
end