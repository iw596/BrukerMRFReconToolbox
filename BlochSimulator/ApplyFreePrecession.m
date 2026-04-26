%% This function modles the free precession of a spin system  with or without a gradient
%% key parameters are M (3xNSpin), T1 and T2 relaxation times (in seconds),
%% time step dt (seconds) and variable arguement: gradient waveform (3xNSteps) and 
%% positions (3xNSpin).
function MNew = ApplyFreePrecession(M,T1,T2,dt,options)
    arguments
        M double
        T1 double
        T2 double
        dt double
        options.waveform  = []
        options.pos = []
        options.df = 0;
    end


    % Create relaxation matrices
    E1 = exp(-dt/T1);
    E2 = exp(-dt/T2);
    A = diag([E2,E2,E1]);
    B = [0;0;(1-E1)];
   % If we have gradients then we need to incoportate these
   if ~isempty(options.waveform)
        for i = 1:size(options.waveform,2)
            for j = 1:size(options.pos,2)
                % Compute off-res frequency in Hz given by b0 grad at
                % indexed position
                gradient_freq = CalculateGradientFreq(squeeze(options.waveform(:,i)),squeeze(options.pos(:,j)));
                gradient_freq = gradient_freq + options.df; % Incorporate off-res
                phi = 2*pi*gradient_freq*dt;
                Rz = zrot(phi);
                M(:,j) = Rz*M(:,j);
                M(:,j) = A*M(:,j) + B;
 
            end
        end
        MNew = M;
   else
       phi = 2*pi*options.df*dt;
       Rz = zrot(phi);
       A = A*Rz;
       MNew = A*M + B;
   end
end

