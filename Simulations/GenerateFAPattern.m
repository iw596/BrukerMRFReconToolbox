function pattern = GenerateFAPattern(minFA,maxFA,N)
    pattern = zeros(N,1);
    pattern(1:N/2) = linspace(minFA,maxFA,N/2);
    pattern(N/2+1:end) = pattern(N/2:-1:1);
end

