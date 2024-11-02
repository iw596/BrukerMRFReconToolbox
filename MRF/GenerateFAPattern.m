%% Generates a sinusoidally varying FA pattern consisting of NLobes with NPoints per lobe
function FAPattern = GenerateFAPattern(NLobes,NPoints,minFA,maxFA,lobeGap,addRamp,addNoise,fileName)
    if (nargin < 8)
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
    
    if (addNoise == 1)
        r =  (5).* rand(length(FAPattern),1);
        FAPattern = FAPattern + r;
    end

    % If addRamp = 1 then we add a rapidly ramping train of FA, this
    % helps estimate B1
    
    if (addRamp == 1)
        initialZeros = zeros(15,1);
        %ramp = linspace(0,90,15);
        ramp = ones(15,1).*90;
        minFAs = zeros(15,1);
        for i = 1:6
            FAPattern = cat(1,FAPattern,initialZeros,ramp);
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

