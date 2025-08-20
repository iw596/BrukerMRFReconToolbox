%% This function generates a sine lobes using the equation
%% y = A*sin(pi*n/(T*N)) + B, where A is and B scale the flip angle pattern
%% N is the total number of point, T adjusts how far along the sine wave if generate (i.e. T = 1 full sine, T = 2 half sine)

function y = GenerateSineLobe(N,T,A,B)
    if (T < 1)
        error("T must be greater or equal to 1");
    end

    if (N < 1)
        error("Number of points must be greater than 0")
    end

    if (A < 0)
        error("Scaling factor A must be greater than 0")
    end
    
    if (B < 0 )
        error ("Scaling factor B must be greater than 0")
    end

    n = linspace(0,N,N);    
    y= A*sin(pi*n/(T*N)) + B;
end