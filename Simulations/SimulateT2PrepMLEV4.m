function MNew = SimulateT2PrepMLEV4(params,TE,dt,M,pos,T1,T2)
    
    FA = pi/2;
    dur = params.MRFT2RectPulse.duration;
    gamma = 42.57e6;
    % Generate spoiler
    amp = ((params.PVM_GradCalConst*params.T2PrepSpoiler.amplitude/100)*1000)/gamma;
    gradDur = params.T2PrepSpoiler.duration - params.RiseTime;
    G = GenSliceSpoiler(amp,gradDur,params.RiseTime,dt);



    % Generate tip-down 90 degree waveform 
    RFTipDown= GenerateBlockPulse(FA,dur,dt,0);

    % Generate 180 degree waveform (+y) by extending 90 degree pulse
    RF180yPlus = GenerateBlockPulse(FA*2,dur*2,dt,pi/2);

    % Generate 180 degree waveform (-y)
    RF180yNeg = GenerateBlockPulse(FA*2,dur*2,dt,3*pi/2);

    % Generate 90 degree waveform (-x)
    RF90xNeg = GenerateBlockPulse(FA,dur,dt,pi);

    % Generate 270 degree waveform (-x)
    RF270xPos = GenerateBlockPulse(FA*3,dur*3,dt,0);

    % Generate 360 degree waveform (+x)
    RF360xNeg = GenerateBlockPulse(FA*4,dur*4,dt,pi);

    MLEVBlockDur = dur + 5e-3 + 2*dur + 5e-3 + dur;
    TipUpBlockDur = dur*3 + 5e-3 + dur*4;

    % Delay for TE/8
    d1 = TE/8 - dur/2 - MLEVBlockDur/2; % 5e-3 is 5 microsecond gap required for phase change

    % TE/4 delay
    d2 = TE/4 - MLEVBlockDur;

    % TE/8 delay between final MLEV block and tip-up block
    d3 = TE/8 - MLEVBlockDur/2 - TipUpBlockDur/2;


    % Apply initial RF excitation
    M = RFExcitation(RFTipDown,dt,M,pos,T1,T2);
    
    % Free-precession
    [A,B] = freeprecess(d1,T1,T2);
    M = A*M + B;

    % First MLEV Block
    M = RFExcitation(RFTipDown,dt,M,pos,T1,T2);
    [A,B] = freeprecess(5e-3,T1,T2);
    M = A*M + B;
    M = RFExcitation(RF180yPlus,dt,M,pos,T1,T2);
    [A,B] = freeprecess(5e-3,T1,T2);
    M = A*M + B;
    M = RFExcitation(RFTipDown,dt,M,pos,T1,T2);

    % Free-precession (TE/4)
    [A,B] = freeprecess(d2,T1,T2);
    M = A*M + B;


    % Second MLEV Block
    M = RFExcitation(RFTipDown,dt,M,pos,T1,T2);
    [A,B] = freeprecess(5e-3,T1,T2);
    M = A*M + B;
    M = RFExcitation(RF180yPlus,dt,M,pos,T1,T2);
    [A,B] = freeprecess(5e-3,T1,T2);
    M = A*M + B;
    M = RFExcitation(RFTipDown,dt,M,pos,T1,T2);


    % Free-precession (TE/4)
    [A,B] = freeprecess(d2,T1,T2);
    M = A*M + B;


    % Third MLEV Block
    M = RFExcitation(RF90xNeg,dt,M,pos,T1,T2);
    [A,B] = freeprecess(5e-3,T1,T2);
    M = A*M + B;
    M = RFExcitation(RF180yNeg,dt,M,pos,T1,T2);
    [A,B] = freeprecess(5e-3,T1,T2);
    M = A*M + B;
    M = RFExcitation(RF90xNeg,dt,M,pos,T1,T2);

    % Free-precession (TE/4)
    [A,B] = freeprecess(d2,T1,T2);
    M = A*M + B;

    % Fourth MLEV Block
    M = RFExcitation(RF90xNeg,dt,M,pos,T1,T2);
    [A,B] = freeprecess(5e-3,T1,T2);
    M = A*M + B;
    M = RFExcitation(RF180yNeg,dt,M,pos,T1,T2);
    [A,B] = freeprecess(5e-3,T1,T2);
    M = A*M + B;
    M = RFExcitation(RF90xNeg,dt,M,pos,T1,T2);

    % Free-precession (TE/8)
    [A,B] = freeprecess(d3,T1,T2);
    M = A*M + B;
    
    % Tip-up pulse 
    M = RFExcitation(RF270xPos,dt,M,pos,T1,T2);
    [A,B] = freeprecess(5e-3,T1,T2);
    M = A*M + B;
    M = RFExcitation(RF360xNeg,dt,M,pos,T1,T2);


    % Spoiling gradient
    [A,B] = freeprecess(dt,T1,T2);
    for p = 1:size(M,2)
        for i = 1:length(G)
           % Calculate z-rotation due to gradient
           RG = zrot(2*pi*gamma*pos(p)*G(i)*dt);
           M(:,p) = RG*M(:,p);
           M(:,p) = A*M(:,p) + B;
        end
    end
    MNew = M;
end