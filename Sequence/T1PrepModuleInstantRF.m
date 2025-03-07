function MNew = T1PrepModuleInstantRF(M,TI,NSpoil,T1,T2)
    NSpin = size(M,2);
  %  phi = linspace(-NSpoil/2*pi,NSpoil/2*pi,NSpin);
    % 180 degre (+x)
    R = RotateTheta(pi,0);
    M = R*M;

    % Precess for TI
    [A,B] = freeprecess(TI,T1,T2);
     M = A*M + B;

    % Gradient spoiling
   % for j = 1:NSpin
   %     M(:,j) = zrot(phi(j)) * M(:,j);
   % end
    MNew = M;
end