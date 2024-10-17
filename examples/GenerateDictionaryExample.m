addpath('MRF\')
addpath('Simulations\')
T1List = [50:5:400];
T2List = [10:2:150];
FA = ReadFAList("datasets\MRFFAPattern.txt");
figure; plot(FA); title("Flip Angle Pattern"); ylabel("Flip Angle [degrees]")
TI = 8; %  Inversion Time ms
TR = 13; % Repetition time ms
TE = 5.5;  % Echo time ms
spoilingCycles = 6; % 6 pi spoiling 
B1 = [0.9:0.01:1.2]; % i.e. no B1 correction
NIso = 200; % Numbe of isochromats used in bloch simulation
[dict,LUT] = GenerateDictionary(FA,TR,TE,TI,T1List,T2List,B1,spoilingCycles,NIso);

save("Dictionaries/B1Dict","dict","LUT",'-v7.3');