function [outputArg1,outputArg2] = GenEllipticalMask(rx,ry,cx,cy,Nx,Ny)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
ellipse = ((X-X0)/l).^2+((Y-Y0)/w).^2<=1; %Your Binary Mask which you multiply to your image, but make sure you change the size of your mesh-grid

[X,Y] = meshgrid(linspace(0,Nx,Nx),linspace(0,Ny,Ny));

dist_from_center = np.sqrt((X - cx)**2 + (Y-cy)**2)

 mask = dist_from_center <= radius
end