function MNew = SimulateAdiabaticT2Prep(params,TE,M,pos,T1,T2,instantRFFlag)
    if (nargin < 7)
        instantRFFlag = true;
    end
    

    gamma = 42.57e6;
    % Generate spoiler


    if (instantRFFlag == true)
        % Generate spoiler
        amp = ((params.PVM_GradCalConst*params.T2PrepSpoiler.amplitude/100)*1000)/gamma;
        gradDur = params.T2PrepSpoiler.duration - params.RiseTime;
        dt_spoil = 10e-6;
        G = GenSliceSpoiler(amp,gradDur,params.RiseTime,dt_spoil);
        % Inital 90 degree tip 
        R = RotateTheta(pi/2,0);
        M = R*M; 
        % Precess TE/4
        [A,B] = freeprecess(TE/4,T1,T2);
        M = A*M + B;
        % 180 degree RF
        R = RotateTheta(pi,0);
        M = R*M;
        % Precess TE/2
        [A,B] = freeprecess(TE/2,T1,T2);
        M = A*M + B;
        
        % 180 degree RF
        M = R*M;
        
        % Precess TE/4
        [A,B] = freeprecess(TE/4,T1,T2);
        M = A*M + B;
        
        % 90 degree tip-back RF
        R = RotateTheta(pi/2,pi);
        M = R*M;
        
        % Simulate spoiler gradient
        [A,B] = freeprecess(dt_spoil,T1,T2);
        for p = 1:size(M,2)
            for i = 1:length(G)
                % Calculate z-rotation due to gradient
                RG = zrot(2*pi*gamma*pos(p)*G(i)*dt_spoil);
                M(:,p) = RG*M(:,p);
                M(:,p) = A*M(:,p) + B;
            end
        end
    else
        % Load sech pulse
        [A,phs]  = ReadRFPulseFile("BrukerRFFiles\sech.inv");
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
        gradDur = params.T1PrepSpoiler.duration - params.RiseTime;
        G = GenSliceSpoiler(amp,gradDur/1000,params.RiseTime,dt);
    end
    MNew = M;

end