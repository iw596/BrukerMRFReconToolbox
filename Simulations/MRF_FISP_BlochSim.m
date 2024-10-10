function MEcho = MRF_FISP_BlochSim(T1,T2,FA,TR,TE,TI,NSpoilCycles,NIso)
    M = zeros([3,NIso]);
    phi = linspace(-NSpoilCycles/2 * pi,NSpoilCycles/2*pi,NIso); 
    MEcho = zeros(size(FA,1),1);
    if (TI > 0)
        M(3,:) = -1; % Assume perfect inversion
        % Propagate over the TI
        [A,B] = freeprecess(TI,T1,T2);
        M = A*M + B;
    else
        M(3,:) = 1.0;
    end
    
    for i = 1:length(FA)
        % Apply RF rotation
        R = xrot(deg2rad(FA(i)));
        M = R*M;
        % Precess until echo time
        [A,B] = freeprecess(TE,T1,T2);
        M = A*M + B;
        % Store signal 
        MEcho(i) = mean(complex(M(1,:),M(2,:)));
        % Precess until next TR
        [A,B] = freeprecess(TR(i) - TE,T1,T2);
        M = A*M + B;
        % Apply spoiling as rotation in z direction
        for j = 1:NIso
            M(:,j) = zrot(phi(j)) * M(:,j);
        end
    end
    
end