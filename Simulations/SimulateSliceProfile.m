function MNew = SimulateSliceProfile(RF,dT,M,pos,T1,T2,G)
    gyro  = 42.47e6;
    % Amount of precesion will always be continous for given T1 and T2 for
    % interval dT
    [A,B] = freeprecess(dT,T1,T2,0);
    for p = 1:size(M,2)
        for i = 1:length(RF)
            rotG = zrot(2*pi*42.58e6 * G(i) * pos(p)*dT);
            % Free precession then rotation under gradient for dT/2
            M(:,p) = A*M(:,p) + B;
            M(:,p) = rotG * M(:,p);
            % Rotation due to RF
            alpha = 2*pi*gyro*RF(i) * dT;
            rotRF = throt(rad2deg(alpha),0);
            M(:,p) = rotRF*M(:,p);
            % Precession under gradient for dT/2
            M(:,p) = A*M(:,p) + B;
            M(:,p) = rotG * M(:,p);
        end
    end
    MNew = M;
end