% Generate an adiabatic bir-4 pulse consisting of N samples (N must be divisble by 4)
% beta (AM waveform parameter), kappa (FM waveform paramter), flip angle
% theta (radians) and dw0 (FM waveform scaling radian/s)

% This code is a matlab conversion from https://sigpy.readthedocs.io/en/latest/_modules/sigpy/mri/rf/adiabatic.html#bir4



function [a,om] = GenBIR4_RFPulse(beta,kappa,dw0,f1,alpha,dphi,pulse_duration,pulse_offset,mod,dt)
    n = round(pulse_duration/dt)
end

