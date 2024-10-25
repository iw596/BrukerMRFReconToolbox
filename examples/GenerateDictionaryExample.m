addpath('MRF\')
addpath('Simulations\')

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
%B1 = [1]; % i.e. no B1 correction
% Load slice profile
sp = load("Dictionaries\Sinc10Profile.mat");
sp = sp.profile;
sp = sp .* 0 + 1;
NIso = length(sp); % Numbe of isochromats used in bloch simulation
[dict,LUT] = GenerateDictionary(FA,TR,TE,TI,T1List,T2List,B1,spoilingCycles,sp,NIso);

save("Dictionaries/LargeB1Dict","dict","LUT",'-v7.3');