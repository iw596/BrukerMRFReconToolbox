addpath("MRF\")
addpath("Utils\")

%% Example script to generate FA pattern
NLobes = 7;
NPoints = 100;

% Ramp up max peaks
maxFA = round(linspace(20,70,5));
maxFA(end+1:end+length(maxFA)-1) = maxFA(end-1:-1:1) - 5;
lobeGap  = 20 ;

faFilePath = "C:\Users\kpqv532\OneDrive - University of Leeds\MRF_FA_Patterns\MRFFAPattern.txt";
FAPattern = GenerateFAPattern(NLobes,NPoints,minFA,maxFA,lobeGap,1,1);


%% Now generate TR Pattern
persistence = 0.6; % Moderate persistence for smoother output
octaves = 70;      % Number of octaves
TRMin = 12e-3;      % Desired minimum value
TRMax = 20e-3;       % Desired maximum value
TRPattern = GenerateTRPattern(length(FAPattern),persistence, octaves,TRMin,TRMax);
figure(10); 
subplot(2,1,1); plot(FAPattern); ylabel("Flip angle"); xlabel("Time point");
subplot(2,1,2); plot(TRPattern); ylabel("TR (s)"); xlabel("Time point");


fileName = "C:\Users\kpqv532\OneDrive - University of Leeds\MRF_FA_Patterns\MRFPattern.txt";

Y = round(FAPattern,1);
Z = round(TRPattern*1000,1);
% Write to file
fID = fopen(fileName,'w+');
fwrite(fID,sprintf("#%d\n",length(FAPattern)));
for i = 1:length(FAPattern)
    fprintf(fID,'%f,%f\n',Y(i),Z(i));
end
fclose(fID);