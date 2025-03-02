function MNew = RFExcitation(RF,dT,M,G,pos)
    
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
        for p = 1:size(M,2)
            % Calculate z-rotation due to gradient
            RG = zrot(2*pi*gamma*pos(p)*G*dT/2);
            for i = 1:length(RF)
                M(:,p) = RG*M(:,p);
                M(:,p) = RotateTheta(alpha(i),theta(i)) *M(:,p);
                M(:,p) = RG*M(:,p);
            end
        end
    end
    MNew = M;

end