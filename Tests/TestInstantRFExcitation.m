%% Short script to test instant RF excitation simulation
addpath(genpath("../BrukerMRFReconToolbox"))
M = zeros([3,200]);
M(3,:) = 1.0;
alpha = pi/2;
theta = 0;
MNew = InstantRFExcitation(alpha,theta,M);


