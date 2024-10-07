%% Script to try and calculate kbs from ABS mat file pulse
%% Pulse from https://onlinelibrary.wiley.com/doi/10.1002/mrm.24507
%% Duration is 6ms, offset is 4khz, excpected kbs approx 0.044 rad/uT^2
%
load("ABS.mat");
% freqOffset = 4000;
% deltaOmega = 2*pi*freqOffset;
% gamma = 2*pi*42.58e6;           %rad/s/T
% gamma*gamma * trapz(linspace(0,6e-3,1000),abs(H).^2)/(2*2*pi*4000)
% 
% 
% gamma = 2*pi*4258; % Rad/Gauss
% pulseShape = ones(1000,1);
% pulseLength = 8e-3;
% offset = 2*pi*4000;
% dT = pulseLength/1000;
% 
% 
% gamma * gamma * trapz((abs(pulseShape).^2)./(2*offset))*dT % rads/Gauss^2
% %Kbs = sum( abs(H).^2) * gamma^2 * 6.0000e-06 / (deltaOmega)



load("ABS.mat");
gamma = 2*pi*4258; % Rad/Gauss
pulseShape = H;
pulseLength = 6e-3;
offset = 2*pi*4000;
dT = pulseLength/1000;
gamma * gamma * trapz((abs(pulseShape).^2)./(2*offset))*dT % rads/Gauss^2

