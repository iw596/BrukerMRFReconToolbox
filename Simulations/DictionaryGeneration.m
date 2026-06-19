classdef DictionaryGeneration
    %DICTIONARYGENERATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FA
        TR
        TE
        InversionPulse
        inversionPulseAmplitude_uT
        inversionPulseDuration_ms

        instantInversionFlag
        dt % Simulation time step in seconds
        LUT
        T1Range
        T2Range
        B1Range
        Thickness
        NIso
        riseTime
        preparationSpoilerFlatTopTime
        imagingSpoilerFlatTopTime_ms
        preparationSpoilerAmplitude_mT
        imagingSpoilerAmplitude_mT
    end
    
    methods
        function obj = DictionaryGeneration(params)
            %DICTIONARYGENERATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.TR = params.TR;
            obj.TE = params.TE;
            obj.FA = params.FA;
            obj.T1Range = params.T1;
            obj.T2Range = params.T2;
            obj.B1Range = params.B1;
            obj.Thickness = params.SliceThickness_mm ./ 10; % Convert mm to cm
            obj.NIso = params.NIsochromats;
            if isfield(params, 'dt')
                obj.dt = params.dt;
            end
        end
        
        function RunSimulation(obj)
            %% When called this function runs the dictionary simulation. First it generates a look-up table LUT
            %% with all valid pairs of T1, T2 and B1
            NDictionaryEntries = 0 ;
            gyro = 42.577e6; %Hz/T
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

            df = 0; % Ignore off-resonance for now
            dp = zeros([NSpin,3]); 
            dp(:,3) = linspace(-obj.Thickness,obj.Thickness,obj.NIso); %in cm
            dv = 0;


            % NOTE: Full Bloch simulation pipeline is not implemented in this class yet.
            % We still produce a valid LUT so downstream code can proceed.
            fprintf('DictionaryGeneration: prepared LUT with %d entries.\n', NDictionaryEntries);
            

            %% Prepare Inversion RF pulse if required
            if (obj.instantInversionFlag == false)
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

            
        end
    end
end

