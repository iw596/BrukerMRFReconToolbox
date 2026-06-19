function [outputArg1,outputArg2] = SimulateFISPMRF(MRFParams,PrepList,T1Array,T2Array,dt,NIso,instantInversionFlag)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    MRFParams
    PrepList
    T1Array
    T2Array
    dt
    NIso
    instantInversionFlag = true;
end

arguments (Output)
    outputArg1
    outputArg2
end

disp("Starting MRF Simulation")

disp("Building look-up table")
%% Prepare look-up table containing all valid pairs
obj.LUT = [];
for kk = 1:length(obj.B1Range)
    for ii = 1:length(obj.T1Range)
        for jj = 1:length(obj.T2Range)
            % Only keep physically feasible pairs (i.e. T1 > T2)
            if (obj.T1Range(ii)>=obj.T2Range(jj))
                obj.LUT(NDictionaryEntries+1,[1:3]) = [obj.T1Range(ii),obj.T2Range(jj),obj.B1Range(kk)];
                NDictionaryEntries = NDictionaryEntries + 1;
            end
        end
    end
end
fprintf('DictionaryGeneration: prepared LUT with %d entries.\n', NDictionaryEntries);




%% Prepare Inversion RF pulse if required
if (obj.instantInversionFlag == false)
    disp("Preparing Inversion Pulse")
    refPower = params.RefPow;
    refVol = sqrt(refPower*50);
    % Calculate pulse B1 required to achieve pi/2 flip
    % for 1 ms block pulse
    refB1 = (pi/2)./(2*pi*42.57*10^6*1e-3); % Peak B1 in T
    % Calculate pulse peak voltage assuming 50 ohm load
    pulsePeakVoltage = sqrt(params.MRFInversionPulse.power * 50);
    % Peak B1 of pulse is refB1/refvoltage * pulse peak voltage
    peakB1 = (refB1./refVol) .*  pulsePeakVoltage; % in T
    [mag,phs] = ReadRFPulseFile("BrukerRFFiles/sech.inv");
    InversionRF = peakB1.*mag./max(mag).*exp(1j.*deg2rad(phs));
    InversionRF = InterpolateRFWaveform(InversionRF,params.MRFInversionPulse.duration,params.MRFInversionPulse.duration/length(mag),dt);
    InversionB1 = InversionRF * gyro;
end

outputArg1 = inputArg1;
outputArg2 = inputArg2;



disp("MRF Simulation Finished")
end