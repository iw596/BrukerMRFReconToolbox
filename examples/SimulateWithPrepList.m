%% First we need to generate our look-up table of T1 and T2 values
T1Range = [10:50:500];
T2Range = [10:5:500];

% Exclude T2 > T1



% Load FA train

% Read preplist and preptimes
prepList = ReadMRFPrepList("datasets\MRFNiCl2_ArraySpoilingTest\PrepList.txt");



NSpin = 200;
spoilingCycles = linspace(-pi,pi,NSpin);

% Set-up starting magnetization


% Run through prep modules
for p = 1:size(prepList,1)
    if (prepList(p,1) == 0)
        M = SimulateInversion(M,T1,T2,prepList(p,2));
    elseif (prepList(p,1) == 1)
    end
    
    % Run through the FA train
    
end