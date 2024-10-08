function pulse = GenerateFermiPulse(duration,NPoints)
    % Fermi pulse calculated using equations from handbook of MRI pulse
    % sequenes

    t = linspace(-duration/2,duration/2,NPoints);
    a = duration./33.81;
    t0 = 12.*a;
    pulse = 1./(1 + exp((abs(t) - t0)./a));


end

