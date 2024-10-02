%% Function to estimate B1 field using bloch-siegert technqiues
%% functions takes in imgs of dimensions [x,y,z,2] or [x,y,2] which correspond 
%% to images at two different off-set frequencies.
%% params is a struct which contains information about the BS pulse

function [B1Map] = BlochSiegertB1(imgs,pulseShape,params)
    B1Map = 0;
    gamma = 42.6; % Gyromagnetic constant of 1H is MHz/T
    % Calculate pulse B1 required to achieve pi/2 flip
    % for 1 ms block pulse
    refB1 = (pi)./(2*pi*42.6e-3*1e-3);
    % Calculate peak voltage assuming 50 ohm load
    refPeakVolage = sqrt(params.RefPow * 50); 
    
    % Peak B1 of pulse is refB1/refvoltage * pulse peak voltage


%BLOCHSIEGERTB1 Summary of this function goes here
%   Detailed explanation goes here
outputArg1 = inputArg1;
outputArg2 = inputArg2;


end

