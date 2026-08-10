%% Matlabclone of the python based SIGPY bir4 function
function [a, om] = bir4_clone(n,beta,kappa,theta,dw0)
% Design a BIR-4 adiabatic pulse.
%
% BIR-4 is equivalent to two BIR-1 pulses back-to-back.
%
% Args:
%     n (int): number of samples (should be a multiple of 4).
%     beta (float): AM waveform parameter.
%     kappa (float): FM waveform parameter.
%     theta (float): flip angle in radians.
%     dw0: FM waveform scaling (radians/s).
%
% Returns:
%     2-element tuple containing
%      - a (array): AM waveform.
%      - om (array): FM waveform (radians/s).
%
% References:
%     Staewen, R.S. et al. (1990). '3-D FLASH Imaging using a single surface
%     coil and a new adiabatic pulse, BIR-4'.
%     Invest. Radiology, 25:559-567.


dphi = pi+theta/2;
dphi = pi + theta / 2;
t = (0:n-1).' / n;

q = n/4;
a1 = tanh(beta * (1 - 4 * t(1:q)));
a2 = tanh(beta * (4 * t(q+1:2*q) - 1));
a3 = tanh(beta * (3 - 4 * t(2*q+1:3*q)));
a4 = tanh(beta * (4 * t(3*q+1:n) - 3));

a = [a1; a2; a3; a4];
a = complex(a, 0);
a(q+1:3*q) = a(q+1:3*q) .* exp(1i * dphi);

om1 = dw0 * tan(kappa * 4 * t(1:q)) / tan(kappa);
om2 = dw0 * tan(kappa * (4 * t(q+1:2*q) - 2)) / tan(kappa);
om3 = dw0 * tan(kappa * (4 * t(2*q+1:3*q) - 2)) / tan(kappa);
om4 = dw0 * tan(kappa * (4 * t(3*q+1:n) - 4)) / tan(kappa);

om = [om1; om2; om3; om4];


end

