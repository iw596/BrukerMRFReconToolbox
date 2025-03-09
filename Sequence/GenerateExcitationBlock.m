function [RFFull,G] = GenerateExcitationBlock(RF,GSliSel,GSliRphs,durSliSel,durSliRphs,riseTime,dt)
    

    NPointsRF = round((riseTime + durSliSel + riseTime + riseTime + durSliRphs + riseTime) /dt);
    RFFull = zeros([NPointsRF,1]);
    
    % Rising edge of slice selection gradient (RF = zero)
    sliceSelRisingEdge = linspace(0,GSliSel,round(riseTime/dt));
    RFFull(round(riseTime/dt)) = 0;
    sliceSelFlatTop = ones([1,round(durSliSel/dt)]) .* GSliSel;
    sliceSelFallingEdge = linspace(GSliSel,0,round(riseTime/dt));
    RFFull(round(riseTime/dt)+1:round(riseTime/dt) + round((durSliSel)/dt)) = RF;
    % Now rephasing gradient
    sliceRphsRisingEdge = linspace(0,-1*GSliRphs,round(riseTime/dt));
    sliceRphsFlatTop = -1*ones([1,round(durSliRphs/dt)]) .* GSliRphs;
    sliceRphsFallingEdge = linspace(-1*GSliRphs,0,round(riseTime/dt));

    
    G = [sliceSelRisingEdge sliceSelFlatTop sliceSelFallingEdge sliceRphsRisingEdge sliceRphsFlatTop sliceRphsFallingEdge];
    

end