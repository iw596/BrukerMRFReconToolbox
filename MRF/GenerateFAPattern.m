%% Generates a sinusoidally varying FA pattern consisting of NLobes with NPoints per lobe
function FAPattern = GenerateFAPattern(NLobes,NPoints,minFA,maxFA,addRamp,fileName)
    FAPattern = zeros(NLobes * NPoints,1);
    curPoint = 1;
    for i = 1:NLobes
        A = maxFA(i) - minFA;
        B = minFA;
        for j = 1:NPoints
            FAPattern(curPoint) = sin((j * pi)./NPoints).*A + B;
            curPoint = curPoint + 1;
        end
    end
    % If addRamp = 1 then we add a rapidly alternating train of FA, this
    % helps estimate B1
    
    if (addRamp == 1)
        initialZeros = zeros(10,1);
        peakFAs = ones(15,1) * 90;
        minFAs = zeros(15,1);
        FAPattern = cat(1,FAPattern,initialZeros);
        for i = 1:6
            FAPattern = cat(1,FAPattern,peakFAs,minFAs);
        end

    end
    

    % Write to file 
    fID = fopen(fileName,'w+');
    fwrite(fID,sprintf("#%d\n",length(FAPattern)));
    for i = 1:length(FAPattern)
        fprintf(fID,'%f\n',FAPattern(i));
    end
    fclose(fID);
end

