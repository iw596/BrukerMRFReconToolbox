addpath('MRF\')
T1List = [50:50:800];
T2List = [10:10:300];
FA = ReadFAList("datasets\MRFFAPattern.txt");
TI = 8; %  Inversion Time ms
TR = 13; % Repetition time ms
TE = 5;  % Echo time ms
spoilingCycles = 4; % 4 pi spoiling 
B1 = [0.5:0.1:1.5]; % i.e. no B1 correction
NIso = 200; % Numbe of isochromats used in bloch simulation
[dict,LUT] = GenerateDictionary(FA,TR,TE,TI,T1List,T2List,B1,spoilingCycles,NIso);