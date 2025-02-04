%% Function to simulate T2 preparation module following MLEV pulse train
function MNew = SimulateT2Prep(MOrig,TE,NIso,NCycles,T1,T2)
    % Assume angles of isochromats
    phi = linspace(-NCycles/2 * pi,NCycles/2*pi,NIso); 

    M = MOrig;
    % The first part of T2 prep is a 90 degree around x
    R = throt(90,0);
    M = R*M;    
    % precess TE/8 
    [A,B] = freeprecess(TE/8,T1,T2);
    M = A*M + B;
    % First 180 around x
    R = throt(180,0);
    M = R*M;
    % Precess TE/4
    [A,B] = freeprecess(TE/4,T1,T2);
    M = A*M + B;
    % Second 180 around x
    R = throt(180,0);
    M = R*M;
    % Precess TE/4
    [A,B] = freeprecess(TE/4,T1,T2);
    M = A*M + B;
    % Third 180 around -x
    R = throt(180,180);
    M = R*M;
    % Precess TE/4
    [A,B] = freeprecess(TE/4,T1,T2);
    M = A*M + B;
    % Fourth 180 around -x
    R = throt(180,180);
    M = R*M;
    % Precess TE/8
    [A,B] = freeprecess(TE/8,T1,T2);
    M = A*M + B;
    % Final 90 degree tip up pulse around -x
    R = throt(90,180);
    M = R*M;   
    % Gradient spoiling
    for j = 1:NIso
        M(:,j) = zrot(phi(j)) * M(:,j);
    end
    MNew = M;
end

