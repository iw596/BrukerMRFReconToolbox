function MNew = RFExcitation(RF,dT,M,G,pos,T1,T2)
    
    gamma = 42.57e6;
    % Convert waveform into flip angle and theta array
    alpha = 2*pi*gamma*abs(RF)*dT;
    theta = angle(RF);
    % Rotate without the prescense of a gradient
    if (nargin < 4)
        for p = 1:size(M,3)
            for i = 1:length(RF)
                M(:,p) = RotateTheta(alpha(i),theta(i));
            end
        end
    else
        % Relaxation matrices will not change
        [A,B] = freeprecess(dT/2,T1,T2);
        for p = 1:size(M,2)
            % Calculate z-rotation due to gradient
            RG = zrot(2*pi*gamma*pos(p)*G*dT/2);
            for i = 1:length(RF)
                M(:,p) = RG*M(:,p);
                M(:,p) = A*M(:,p) + B;
                M(:,p) = RotateTheta(alpha(i),theta(i)) *M(:,p);
                M(:,p) = A*M(:,p) + B;
                M(:,p) = RG*M(:,p);
            end
        end
    end
    MNew = M;

end