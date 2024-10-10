addpath("MRF\")
%% Example script to generate FA pattern
NLobes = 7;
NPoints = 150;
minFA = 5;
maxFA = [20,35,65,45,25,15,50];
lobeGap  =20;

filePath = "C:\Users\kpqv532\OneDrive - University of Leeds\MRF_FA_Patterns\MRFFAPattern.txt";

FAPattern = GenerateFAPattern(NLobes,NPoints,minFA,maxFA,lobeGap,1,filePath);
figure(10); plot(FAPattern);