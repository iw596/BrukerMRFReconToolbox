% Simulates an RF waveform (RF) with FA in radians, duration (dur) in ms
% and sampling time dt in ms

function RF = GenerateBlockPulse(FA,dur,dt,phs)
    if(nargin < 4)
        phs = 0;
    end
    gamma = 42.57e6;
    N = round(dur/dt);
    RF = ones([1,N]);
    RF = FA*(RF/sum(RF))/(2*pi*gamma*dt);
    RF = RF* exp(-1j * phs);
end