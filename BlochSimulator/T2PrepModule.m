function MNew = T2PrepModule(M,TE,T1,T2,options)
    arguments
        M double
        TE double
        T1 double
        T2 double
        options.InstantRF = true
        options.dt double
    end

    if options.InstantRF == true
        d1 = TE/8;
        d2 = TE/4;
        % Initial 90 (+x)
        R = RotateTheta(pi/2,0);
        M = R*M;
        M = ApplyFreePrecession(M,T1,T2,d1);
        
        % Composite 180 (+y)
        R = RotateTheta(pi/2,0)*RotateTheta(pi,pi/2)*RotateTheta(pi/2,0);
        M = R*M;
        
        
        
        
        M = ApplyFreePrecession(M,T1,T2,d2);
        % Composite 180 (+y)
        M = R*M;
        
        M = ApplyFreePrecession(M,T1,T2,d2);
        % Composite 180 (-y)
        R = RotateTheta(pi/2,pi)*RotateTheta(pi,3*pi/2)*RotateTheta(pi/2,pi);
        M = R*M;
        
        M = ApplyFreePrecession(M,T1,T2,d2);
        % Composite 180 (-y)
        M = R*M;
        M = ApplyFreePrecession(M,T1,T2,d1);
        % Tip-up 90 (-x)
        R = RotateTheta(3*pi/2,0);
        M = R*M;
        R = RotateTheta(2*pi,pi);
        M = R*M;
        
        MNew = M;
    else
        % Set-up 90 degree pulse

        % Set-up 180 degree pulse

        % Set-up 270 degree pulse

        % Set-up 360 degree pulse

    end




end

