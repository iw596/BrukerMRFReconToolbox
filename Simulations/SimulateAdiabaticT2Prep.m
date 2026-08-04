function MNew = SimulateAdiabaticT2Prep(params,TE,M,T1,T2,pos,instantRFFlag)
    if (nargin < 7)
        instantRFFlag = true;
    end
    if (nargin < 6)
        instantRFFlag = true;
        pos = [];
    end

    gamma = 42.57e6;
    % Generate spoiler


    if (instantRFFlag == true)
        % Generate spoiler
        amp = ((params.PVM_GradCalConst*params.T2PrepSpoiler.amplitude/100)*1000)/gamma;
        gradDur = params.T2PrepSpoiler.duration - params.RiseTime;
        dt_spoil = 10e-8;
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
        if ~isempty(pos)
            for p = 1:size(M,2)
                for i = 1:length(G)
                    % Calculate z-rotation due to gradient
                    RG = zrot(2*pi*gamma*pos(p)*G(i)*dt_spoil);
                    M(:,p) = RG*M(:,p);
                    M(:,p) = A*M(:,p) + B;
                end
            end
        end
    else
        % Load adiabatic inversion pulse (180 deg)
        [invMag,invPhs] = ReadRFPulseFile("BrukerRFFiles\sech.inv");

        % Load BIR4 pulse shape for adiabatic excitation (90 deg)
        [birMag,birPhs] = ReadRFPulseFile("BrukerRFFiles\tanhtanBIR4Odd20w.inv");

        % Calculate reference peak B1 for a 1 ms hard 90 pulse
        refB1 = (pi/2)./(2*pi*gamma*1e-3); % Peak B1 in T
        refPeakVoltage = sqrt(params.RefPow * 50);

        % Inversion pulse scaling
        invPeakVoltage = sqrt(params.MRFT2InversionPulse.power * 50);
        invPeakB1 = (refB1./refPeakVoltage) .* invPeakVoltage;
        invRF = invPeakB1 .* invMag./max(invMag) .* exp(1j.*deg2rad(invPhs));
        invRF = InterpolateRFWaveform(invRF,params.MRFT2InversionPulse.duration,params.MRFT2InversionPulse.duration/length(invRF),10e-6);

        % BIR4 pulse scaling
        birPeakVoltage = sqrt(params.MRFT2BIRPulse.power * 50);
        birPeakB1 = (refB1./refPeakVoltage) .* birPeakVoltage;
        birRF = birPeakB1 .* birMag./max(birMag) .* exp(1j.*deg2rad(birPhs));
        birRF = InterpolateRFWaveform(birRF,params.MRFT2BIRPulse.duration,params.MRFT2BIRPulse.duration/length(birRF),10e-6);

        % Tip-up BIR4 pulse phase shifted by 180 deg
        birRFtipUp = birRF .* exp(1j*pi);

        % Apply BIR4 90 tip-down
        M = RFExcitation(M,T1,T2,10e-6,birRF);

        % TE/4 delay
        [A,B] = freeprecess(TE/4,T1,T2);
        M = A*M + B;

        % First adiabatic inversion
        M = RFExcitation(M,T1,T2,10e-6,invRF);

        % TE/2 delay
        [A,B] = freeprecess(TE/2,T1,T2);
        M = A*M + B;

        % Second adiabatic inversion
        M = RFExcitation(M,T1,T2,10e-6,invRF);

        % TE/4 delay
        [A,B] = freeprecess(TE/4,T1,T2);
        M = A*M + B;

        % BIR4 90 tip-up
        M = RFExcitation(M,T1,T2,10e-6,birRFtipUp);

        % Generate spoiler
        amp = ((params.PVM_GradCalConst*params.T2PrepSpoiler.amplitude/100)*1000)/gamma;
        gradDur = params.T2PrepSpoiler.duration - params.RiseTime;
        G = GenSliceSpoiler(amp,gradDur,params.RiseTime,10e-6);

        if ~isempty(pos)
            [A,B] = freeprecess(10e-6,T1,T2);
            for p = 1:size(M,2)
                for i = 1:length(G)
                    RG = zrot(2*pi*gamma*pos(p)*G(i)*10e-6);
                    M(:,p) = RG*M(:,p);
                    M(:,p) = A*M(:,p) + B;
                end
            end
        end
    end
    MNew = M;

end