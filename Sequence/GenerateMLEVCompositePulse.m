
%% This function generates a MLEV composite inversion pulse. The 90 degree pulse has duration tau. The raster time is set
%% through dt. phaseSwitch is a boolean variable, if false the phase is +y if true the phase is -y
function [RF,dur] = GenerateMLEVCompositePulse(tau,dt,phaseSwitch)
    dur = tau*4; % x4 as two 90 degree pulses and one 180 degree pulse
    
    if (phaseSwitch == false)   
    % Gem
    else
    end

end