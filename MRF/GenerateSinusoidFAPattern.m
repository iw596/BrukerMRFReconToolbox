function FAPattern = GenerateSinusoidFAPattern(peakFA,minFA,NLobes,NPoints)
    FAPattern = zeros([1,NLobes*NPoints]);
    % Generate random number between minFA+1 to peakFA
    curPoint = 1;
    for i = 1:NLobes
        lobePeak = randi([round(minFA)+1,peakFA]);
        A = lobePeak - minFA;
        B = minFA;
        for j = 1:NPoints
            FAPattern(curPoint) = sin((j * pi)./NPoints).*A + B;
            curPoint = curPoint + 1;
        end
    
    end

end