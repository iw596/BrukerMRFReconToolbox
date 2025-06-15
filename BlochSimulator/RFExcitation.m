function MNew = RFExcitation(M,T1,T2,dt,RF,options)
    arguments
        M double
        T1 double
        T2 double
        dt double
        RF  
        options.gradient_waveform = [];
        options.pos = [];
        options.ignore_decay = false
        options.df = 0;
    end
    
    if (options.ignore_decay == true)
        T1 = Inf;
        T2 = Inf;
    end
    
    timeStep = dt/2;
    gamma = 42.577e6;
    E1 = exp(-timeStep/T1);
    E2 = exp(-timeStep/T2);
    A = diag([E2,E2,E1]);
    B = [0;0;(1-E1)];
    alpha = 2*pi*gamma*abs(RF) * dt;
    theta = angle(RF);
    apply_relax = @(M) A*M + B;
    for i = 1:length(RF)
        if (~isempty(options.gradient_waveform))
            z_pos = options.pos(3,:);
            grad_i = options.gradient_waveform(i);
            gradient_freq = gamma * (z_pos * grad_i) + options.df; % 1 x N
            phi = 2*pi*gradient_freq*timeStep;
            for j = 1:size(M,2)
                Rz = zrot(phi(j));  % Still not ideal, could vectorize zrot
                M(:,j) = Rz * M(:,j);
                M(:,j) = apply_relax(M(:,j));
                M(:,j) = InstantRFExcitation(M(:,j), alpha(i), theta(i));
                M(:,j) = Rz * M(:,j);
                M(:,j) = apply_relax(M(:,j));
            end
        else
            M = apply_relax(M);
            M = InstantRFExcitation(M,alpha(i),theta(i));
            M = apply_relax(M);
        end
    end



    % if ~isempty(options.gradient_waveform)
    %     % Precess for dt/2, excite, precess for another dt/2
    %     % (https://doi.org/10.1016/j.mri.2018.06.018)
    %     for i = 1:length(RF)
    %         for j = 1:size(options.pos,2)
    %             % First precession section
    %             % gradient_freq = CalculateGradientFreq(squeeze(options.gradient_waveform(:,i)),squeeze(options.pos(:,j)));                                gradient_freq = gradient_freq + options.df; % Incorporate off-res
    %             gradient_freq = gamma * (options.pos(3,j) .* options.gradient_waveform(i));
    %             gradient_freq = gradient_freq + options.df; % Incorporate off-res
    %             phi = 2*pi*gradient_freq*timeStep;
    %             Rz = zrot(phi);
    %             M(:,j) = Rz*M(:,j);
    %             M(:,j) = A*M(:,j) + B;
    % 
    %             % RF excitation
    %             M(:,j) = InstantRFExcitation(M(:,j),alpha(i),theta(i));
    % 
    %             % Second precession section
    %             M(:,j) = Rz*M(:,j);
    %             M(:,j) = A*M(:,j) + B;
    %         end
    %     end
    % else
    %     % Same as above but no need for calculating gradient
    %     for i = 1:length(RF)
    %         % First precession section
    %         M= A*M + B;
    % 
    %         % RF excitation
    %         M = InstantRFExcitation(M,alpha(i),theta(i));
    % 
    %         % Second precession section
    %         M = A*M + B;
    %     end
    % end
    % 
    % 
    

    MNew = M;


end

