function MNew = T2PrepModuleInstantRF(M,TE,NSpoil,T1,T2)
    NSpin = size(M,2);
    phi = linspace(-NSpoil/2*pi,NSpoil/2*pi,NSpin);

    % 90 degre (+x)
    R = RotateTheta(pi/2,0);
    M = R*M;

    % TE/8 delay
    [A,B] = freeprecess(TE/8,T1,T2);
    M = A*M + B;
    
    % 180 (+y)
    R = RotateTheta(pi,pi/2);
    M = R*M;

    % TE/4 delay
    [A,B] = freeprecess(TE/4,T1,T2);
    M = A*M + B;

    % 180 (+y)
    R = RotateTheta(pi,pi/2);
    M = R*M;

    % TE/4 delay
    M = A*M + B;

    % 180 (-y)
    R = RotateTheta(pi,3*pi/2);
    M = R*M;
    
    % TE/4 delay
    M = A*M + B;

    % 180 (-y)
    R = RotateTheta(pi,3*pi/2);
    M = R*M;

    % TE/8 delay
    [A,B] = freeprecess(TE/8,T1,T2);
    M = A*M + B;

    % 90 degre (-x)
    R = RotateTheta(pi/2,pi);
    M = R*M;

    % Gradient spoiling
    for j = 1:NSpin
        M(:,j) = zrot(phi(j)) * M(:,j);
    end

    MNew = M;

end