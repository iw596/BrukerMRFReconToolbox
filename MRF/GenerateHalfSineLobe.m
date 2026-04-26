function y = GenerateHalfSineLobe(NPoints,minFA,maxFA)
    A = maxFA - minFA;
    B = minFA;
    x = linspace(0,pi/2,NPoints);
    y = sin(x);
    y = A*y + B;

end