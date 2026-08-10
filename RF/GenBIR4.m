% Generate an adiabatic bir-4 pulse consisting of N samples (N must be divisble by 4)
% beta (AM waveform parameter), kappa (FM waveform paramter), flip angle
% theta (radians) and dw0 (FM waveform scaling radian/s)
% dt is the rf raster time
% This code is a matlab conversion from https://sigpy.readthedocs.io/en/latest/_modules/sigpy/mri/rf/adiabatic.html#bir4



function [rf] = GenBIR4(beta,kappa,dw0,f1,alpha,dphi,pulse_duration,phase_offset,mod,dt)
    n = round(pulse_duration/dt);
    [signal_am, signal_fm] = bir4_clone(n, beta, kappa, alpha, dw0);
    signal_am = signal_am / max(signal_am) * f1;

    % calculate phase modulation
    signal_phase = cumsum(signal_fm) * dt;

    % calculate complex pulse shape
    if strcmp(mod, 'tipdown')
        signal = signal_am .* exp(1i* (signal_phase + dphi - pi/2 + phase_offset));
    elseif strcmp(mod, 'tipup')
        signal = signal_am .* exp(1i* (signal_phase + dphi + pi/2 + phase_offset));
    else
        error('wrong mode: tipdown or tipup')
    end

    rf = signal;


end

