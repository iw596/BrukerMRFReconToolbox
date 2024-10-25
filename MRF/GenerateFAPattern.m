%% Generates a sinusoidally varying FA pattern consisting of NLobes with NPoints per lobe
function FAPattern = GenerateFAPattern(NLobes,NPoints,minFA,maxFA,lobeGap,addRamp,fileName)
    if (nargin < 7)
        savePattern = 0;
    else
        savePattern = 1;
    end

    FAPattern = zeros(NLobes * NPoints,1);
    curPoint = 1;
    gap = zeros(lobeGap,1);
    for i = 1:NLobes
        A = maxFA(i) - minFA;
        B = minFA;
        for j = 1:NPoints
            FAPattern(curPoint) = sin((j * pi)./NPoints).*A + B;
            curPoint = curPoint + 1;
        end
        % Insert gap between lobes
        FAPattern = cat(1,FAPattern,gap);
        curPoint = curPoint + lobeGap;
    end
    % If addRamp = 1 then we add a rapidly ramping train of FA, this
    % helps estimate B1
    
    if (addRamp == 1)
        initialZeros = zeros(10,1);
        ramp = linspace(0,45,15);
        minFAs = zeros(15,1);
        for i = 1:6
            FAPattern = cat(1,FAPattern,ramp.',minFAs);
            curPoint = curPoint + 15 + 15;
        end

    end
    
    if (savePattern == 1)
        % Write to file 
        fID = fopen(fileName,'w+');
        fwrite(fID,sprintf("#%d\n",length(FAPattern)));
        for i = 1:length(FAPattern)
            fprintf(fID,'%f\n',FAPattern(i));
        end
        fclose(fID);
    end
end

