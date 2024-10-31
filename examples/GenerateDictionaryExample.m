addpath('MRF\')
addpath('Simulations\')

T1List = [50:1:250];
T2List = [10:1:80];
FA = ReadFAList("datasets\MRFFAPattern.txt");
figure; plot(FA); title("Flip Angle Pattern"); ylabel("Flip Angle [degrees]")
TI = 8; %  Inversion Time ms
TR = 13; % Repetition time ms
TE = 5.5;  % Echo time ms
spoilingCycles = 4; % 6 pi spoiling 
%B1 = [0.9:0.01:1.10]; % i.e. no B1 correction
B1 = [1]; % i.e. no B1 correction
% Load slice profile
sp = load("Dictionaries\Sinc10Profile.mat");
sp = abs(sp.profile);
sp = sp.*0 + 1;
NIso = length(sp); % Numbe of isochromats used in bloch simulation
[dict,LUT] = GenerateDictionary(FA,TR,TE,TI,T1List,T2List,B1,spoilingCycles,sp,NIso);

save("Dictionaries/Large_NoB1Dict","dict","LUT",'-v7.3');