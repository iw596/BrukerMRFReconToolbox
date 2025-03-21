function MNew = SimulateT1PrepSech(params,TI,M,pos,T1,T2,instantRF)
    if (nargin < 7)
        instantRF = true;
    end
    
  
    % Load sech pulse
    [A,phs]  = ReadRFPulseFile("BrukerRFFiles\sech.inv");
    
    % Calculate peak B1 based off reference power
    gamma = 42.57*10^6; % Gyromagnetic constant of 1H is MHz/T
    % Calculate pulse B1 required to achieve pi/2 flip
    % for 1 ms block pulse
    refB1 = (pi/2)./(2*pi*42.57*10^6*1e-3); % Peak B1 in T
    % Calculate reference peak voltage assuming 50 ohm load
    refPeakVolage = sqrt(params.RefPow * 50);
    % Calculate pulse peak voltage assuming 50 ohm load
    pulsePeakVoltage = sqrt(params.MRFInversionPulse.power * 50);
    % Peak B1 of pulse is refB1/refvoltage * pulse peak voltage
    peakB1 = (refB1./refPeakVolage) .*  pulsePeakVoltage; % in T
    RF = peakB1.*A.*exp(1j.*deg2rad(phs)); 
    dt = (params.MRFInversionPulse.duration/1000)/length(RF);

    % Generate spoiler
    amp = ((params.PVM_GradCalConst*params.T1PrepSpoiler.amplitude/100)*1000)/gamma;
    gradDur = params.T1PrepSpoiler.duration/1000 - params.RiseTime;
    G = GenSliceSpoiler(amp,gradDur/1000,params.RiseTime,dt);


    % Calculate delay required to achieve TI 
    if (instantRF == true)
        delay = TI - (params.MRFInversionPulse.duration/1000/2 - params.T1PrepSpoiler.duration/1000 - params.RiseTime);
    else
        delay = TI - (params.MRFInversionPulse.duration/1000/2 - params.T1PrepSpoiler.duration/1000 - params.RiseTime  - params.RiseTime - params.ExcRFDur/1000/2);
    end
    
    % Simulate inversion RF
    M = RFExcitation(RF,dt,M,pos,T1,T2);

    % Simulate spoiler gradient
    [A,B] = freeprecess(dt,T1,T2);
    for p = 1:size(M,2)
        for i = 1:length(G)
           % Calculate z-rotation due to gradient
           RG = zrot(2*pi*gamma*pos(p)*G(i)*dt);
           M(:,p) = RG*M(:,p);
           M(:,p) = A*M(:,p) + B;
        end
    end
    % 
    % % Free precession
    [A,B] = freeprecess(delay,T1,T2);
    M = A*M + B;
    MNew = M;
end