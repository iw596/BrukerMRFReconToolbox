function M_Echo = FISPSimulation(SeqParams,TissueParams,NIso)
    T1 = TissueParams.T1;
    T2 = TissueParams.T2;
    TI = SeqParams.TI;
    FA = SeqParams.FA;
    TE = SeqParams.TE;
    TR = SeqParams.TR;
    % Create spin distribution between -pi and pi
   % phi = linspace(-pi,pi,NIso);
    % Create spoiling phase cycles
    spoil = linspace(-pi,pi,NIso);
    M = zeros([3,NIso]);
    Nexp = length(SeqParams.FA);
    % Create array to store (absolute) result at each TE
    M_Echo = zeros([1,size(SeqParams.FA,2)]);
    % Assume our initial magnetization is Mx = 0 My=0 Mz = -1
    M(3,:) = -1; % Assuming perfect inversion
    % Propagate signal for inversion time TI
    [A,B] = freeprecess(TI,T1,T2);
    M = A * M + B;

    %% Now run simulation for Nexp
    for ii = 1:Nexp
        % Rotate magnetization by flip angle
        Rflip = yrot(deg2rad(FA(ii))*((-1)^ii));
        M = Rflip * M;
        % Free precession until echo time
        [A,B] = freeprecess(TE,T1,T2);
        M = A * M + B;
        % Store (absolute) signal at the echo time (mean of all isochromats)
        M_Echo(ii) = mean(squeeze(M(1,:)+1i*M(2,:)))*((-1)^ii);
        % Precess until the next TR
        [A,B] = freeprecess(TR - TE,T1,T2);
        M = A * M + B;
        % Apply spoiling to isochromats
        for j = 1:NIso
             M(:,j) = zrot(spoil(j))*M(:,j);
        end

    end
end