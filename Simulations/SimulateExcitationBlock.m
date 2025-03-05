function MNew = SimulateExcitationBlock(RF,G,dt,M,pos,T1,T2)


gamma = 42.57e6;
% Convert waveform into flip angle and theta array
alpha = 2*pi*gamma*abs(RF)*dt;
theta = angle(RF);
[A,B] = freeprecess(dt/2,T1,T2);
for p = 1:size(M,2)
    for i = 1:length(RF)
        % Calculate z-rotation due to gradient
        RG = zrot(2*pi*gamma*pos(p)*G(i)*dt/2);
        M(:,p) = RG*M(:,p);
        M(:,p) = A*M(:,p) + B;
        M(:,p) = RotateTheta(alpha(i),theta(i)) *M(:,p);
        M(:,p) = RG*M(:,p);
        M(:,p) = A*M(:,p) + B;
    end
end

MNew = M;


end 