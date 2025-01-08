addpath('MRF\')
addpath('Simulations\')
addpath('FileIO\')
T1List = [10:20:300];
T2List = [1:1:100];
[FA,~] = ReadMRFList("datasets\Yasaman_MRF10122024\MRFPattern.txt");
figure; plot(FA); title("Flip Angle Pattern"); ylabel("Flip Angle [degrees]")
TR = 15;
TI = 20; %  Inversion Time ms
TE = 5;  % Echo time ms
spoilingCycles = 8; % 6 pi spoiling 
B1 = [0.8:0.02:1.15]; % i.e. no B1 correction
%B1 = [1]; % i.e. no B1 correction
% Load slice profile
NIso = 200;
sp = ones(NIso,1);
% sp = load("Dictionaries\Sinc10Profile.mat");
% sp = abs(sp.profile);
% sp = sp.*0 + 1;
% NIso = length(sp); % Numbe of isochromats used in bloch simulation
[dict,LUT] = GenerateDictionary(FA,TR,TE,TI,T1List,T2List,B1,spoilingCycles,sp,NIso);

save("Dictionaries/YasamanDictionary","dict","LUT",'-v7.3');