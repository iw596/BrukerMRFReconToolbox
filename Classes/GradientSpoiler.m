classdef GradientSpoiler
   % This class implements a spoiler gradient. The gradient waveform is
   % stored in the waveform property (units T/m) with the raster time (in seconds)
   % stored in dt
    
    properties
        waveform = [];
        dt = [];
    end
    
    methods
        function obj = GradientSpoiler(waveform,dt)
            obj.waveform = waveform;
            obj.dt = dt;
        end
        
        function MNew = ApplyGradient(obj,M,pos,T1,T2,df)
              if (nargin < 6)
                df = 0;
              end
              NSpin = size(pos,2);
              NG = length(obj.waveform);
              gamma = 42.56e6;
              [A,B] = freeprecess(obj.dt,T1,T2,df);
              for p = 1:NSpin
                  for g = 1:NG
                    RG = zrot(-2*pi*gamma*pos(p)*obj.waveform(g)*obj.dt);
                    M(:,p) = RG*M(:,p);
                    M(:,p) = A*M(:,p) + B;
                  end
              end
              MNew = M;
        end
    end
end

