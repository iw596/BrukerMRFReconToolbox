function [RF] = GenerateExcitationBlock(RF,GSliSel,GSliRphs,durSliSel,durSliRphs,riseTime,dt)
    

    
    % Rising edge of slice selection gradient (RF = zero)
    sliceSelRisingEdge = linspace(0,GSliSel,round(riseTime/dt));
    sliceSelFlatTop = ones([round(durSliSel/dt),1]) .* GSliSel;
    sliceSelFallingEdge = linspace(GSliSel,0,round(riseTime/dt));

    % Now rephasing gradient
    sliceRphsRisingEdge = linspace(0,GSliRphs,round(riseTime/dt));
    sliceRphsFlatTop = -1*ones([round(durSliRphs/dt),1]) .* GSliRphs;
    sliceRphsFallingEdge = linspace(GSliRphs,0,round(riseTime/dt));

    

end