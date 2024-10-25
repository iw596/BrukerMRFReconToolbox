addpath('MRF\')
addpath('Simulations\')
<<<<<<< Updated upstream

T1List = [50:5:350];
T2List = [10:5:320];
[FA,TR] = ReadMR("datasets\MRFFAPattern.txt");
figure; 
subplot(1,2,1);plot(FA); title("Flip Angle Pattern"); ylabel("Flip Angle [degrees]")
subplot(1,2,2);
TI = 20; %  Inversion Time ms
TE = 5.5;  % Echo time ms
spoilingCycles = 4; % 6 pi spoiling 
B1 = [0.9:0.01:1.10]; % i.e. no B1 correction
=======
addpath('FileIO\')
T1List = [50:10:700];
T2List = [10:5:500];
[FA,TR] = ReadMRFList("datasets\MRFPattern.txt");
figure; plot(FA); title("Flip Angle Pattern"); ylabel("Flip Angle [degrees]")
TI = 8; %  Inversion Time ms
TE = 6;  % Echo time ms
spoilingCycles = 4; % 6 pi spoiling 
B1 = [1]; % i.e. no B1 correction
>>>>>>> Stashed changes
%B1 = [1]; % i.e. no B1 correction
% Load slice profile
NIso = 200; % Numbe of isochromats used in bloch simulations
sp = ones(NIso,1);
[dict,LUT] = GenerateDictionary(FA,TR,TE,TI,T1List,T2List,B1,spoilingCycles,sp,NIso);

save("Dictionaries/LargeB1Dict","dict","LUT",'-v7.3');