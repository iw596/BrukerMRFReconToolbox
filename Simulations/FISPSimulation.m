function x = FISPSimulation(SeqParams,TissueParams,NIso)
    T1 = TissueParams.T1;
    T2 = TissueParams.T2;
    TI = SeqParams.TI;
    FA = SeqParams.FA;
    TE = SeqParams.TE;
    TR = SeqParams.TR;
    slice_profile = 1;
    alpha = deg2rad(FA);
    %% Bloch Simulation in the complex SO(2) group
    Rot = @(alpha) [cos(alpha) -sin(alpha);
        sin(alpha)  cos(alpha)];


    d = complex(ones(2, length(T1)));
    x = zeros(length(alpha),length(T1),length(slice_profile));
    z = zeros(length(alpha),length(T1),length(slice_profile));
    for is = 1:length(slice_profile)
        M = complex(zeros(2, length(T1)));
        M(2,:) = 1; 
        for ip=1:length(alpha)
            % Apply RF-pulse (that now acts only on the real part)
            Mtmp = Rot(slice_profile(is)*alpha(ip)*round(cos(ip*pi))) * real(M);
            M = Mtmp + 1i*imag(M);
            %Relaxation
            M(1,:) = M(1,:) .* exp(-TE(ip)./T2);
            M(2,:) = ones(1,size(M,2)) + (M(2,:)-ones(1,size(M,2))) .* exp(-TE(ip)./T1);
            % store the signal at the echo time
            x(ip,:,is) = M(1,:)*cos(pi*ip);
            z(ip,:,is) = M(2,:);

            % Relaxation
            M(1,:) = M(1,:) .* exp(-(TR(ip)-TE(ip))./T2);
            M(2,:) = ones(1,size(M,2)) + (M(2,:)-ones(1,size(M,2))) .* exp(-(TR(ip)-TE(ip))./T1);
        end
    end

    % sum over the slice profile
    x = sum(x,3);
    z = sum(z,3);
    % Create spin distribution between -pi and pi
   % phi = linspace(-pi,pi,NIso);
    % Create spoiling phase cycles
    %spoil = linspace(-pi,pi,NIso);
   %  M = zeros([3,NIso]);
   %  Nexp = length(SeqParams.FA);
   %  % Create array to store (absolute) result at each TE
   %  M_Echo = zeros([1,size(SeqParams.FA,2)]);
   %  % Assume our initial magnetization is Mx = 0 My=0 Mz = -1
   %   M(3,:) = 1; % Assuming perfect inversion
   %  % Propagate signal for inversion time TI
   % % [A,B] = freeprecess(TI,T1,T2);
   % % M = A * M + B;
   % 
   %  %% Now run simulation for Nexp
   %  for ii = 1:Nexp
   %      % Rotate magnetization by flip angle
   %    %  Rflip = yrot(deg2rad(FA(ii))*((-1)^ii));
   %      Rflip = yrot(deg2rad(FA(ii))*((-1)^ii-1));
   %      M = Rflip * M;
   %      % Free precession until echo time
   %      [A,B] = freeprecess(TE,T1,T2);
   %      M = A * M + B;
   %      % Store (absolute) signal at the echo time (mean of all isochromats)
   %     % M_Echo(ii) = mean(squeeze(M(1,:)+1i*M(2,:)))*((-1)^ii);
   %      M_Echo(ii) = mean(squeeze(M(1,:)+1i*M(2,:)))*((-1)^ii-1);
   %      % Precess until the next TR
   %      [A,B] = freeprecess(TR - TE,T1,T2);
   %      M = A * M + B;
   %      % Apply spoiling to isochromats
   %   %   for j = 1:NIso
   %   %       M(:,j) = zrot(spoil(j))*M(:,j);
   %   %   end
   % 
   %  end
end