%% Matlabclone of the python based SIGPY bir4 function
function [outputArg1,outputArg2] = bir4_clone(n,beta,kappa,theta,dw0)
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

outputArg1 = inputArg1;
outputArg2 = inputArg2;


end

