%% Script to generate Fermi pulse and store in wave file
addpath("B1Mapping\")

dur = 8e-3;
NPoints = 2048;
pulse = GenerateFermiPulse(duration,NPoints);


% Write pulse to wave file
fileID = fopen("B1Mapping\IWFermiPuilse.exc",'w');
fprintf(fileID, '##TITLE= IWFermiPulse.exc\n');
fprintf(fileID, '##JCAMP-DX= 5.00 BRUKER JCAMP library\n');
fprintf(fileID, '##DATA TYPE= Shape Data\n');
fprintf(fileID, '##ORIGIN= University of Leeds\n');
fprintf(fileID, '##OWNER= <xxx>\n');
fprintf(fileID, '##MINX= %f\n',min(abs(pulse)));
fprintf(fileID, '##MAXX= %f\n',max(abs(pulse)));
fprintf(fileID, '##MINY= 0.000000e+00\n');
fprintf(fileID, '##MAXY= 0.000000e+00\n');

fclose(fileID);