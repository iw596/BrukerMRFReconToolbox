function [RF,G,dt] = GenerateT1PrepModule(params,TI)
    % Inversion time is defined as center of inversion pulse to center of
    % excitation pulse, thus we need to trim off
    
    [A,phs] = ReadRFPulseFile("BrukerRFFiles\sech.inv");
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
    RF = peakB1.*A.*exp(-1j.*deg2rad(phs)); 
    dt = (params.MRFInversionPulse.duration/1000)/length(RF);

    spoilerAmplitude
    spoilerFlatTime
    spoilerRiseTime

    %
    


end