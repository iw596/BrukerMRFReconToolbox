% Generate an adiabatic bir-4 pulse consisting of N samples (N must be divisble by 4)
% beta (AM waveform parameter), kappa (FM waveform paramter), flip angle
% theta (radians) and dw0 (FM waveform scaling radian/s)

% This code is a matlab conversion from https://sigpy.readthedocs.io/en/latest/_modules/sigpy/mri/rf/adiabatic.html#bir4
function [a,om] = GenBIR4(n,beta,kappa,theta,dw0)

dphi = pi + theta / 2;

t = (0:n-1) / n;

% Amplitude envelope
a1 = tanh(beta * (1 - 4 * t(1 : floor(n/4))));
a2 = tanh(beta * (4 * t(floor(n/4)+1 : floor(n/2)) - 1));
a3 = tanh(beta * (3 - 4 * t(floor(n/2)+1 : floor(3*n/4))));
a4 = tanh(beta * (4 * t(floor(3*n/4)+1 : end) - 3));

a = [a1, a2, a3, a4];
a = complex(a);  % convert to complex type

% Apply complex phase shift to middle half
a(floor(n/4)+1 : floor(3*n/4)) = ...
    a(floor(n/4)+1 : floor(3*n/4)) .* exp(1i * dphi);

% Frequency modulation
om1 = dw0 * tan(kappa * 4 * t(1 : floor(n/4))) / tan(kappa);
om2 = dw0 * tan(kappa * (4 * t(floor(n/4)+1 : floor(n/2)) - 2)) / tan(kappa);
om3 = dw0 * tan(kappa * (4 * t(floor(n/2)+1 : floor(3*n/4)) - 2)) / tan(kappa);
om4 = dw0 * tan(kappa * (4 * t(floor(3*n/4)+1 : end) - 4)) / tan(kappa);

om = [om1, om2, om3, om4];

end

