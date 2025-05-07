%% Calculates the offset frequency df (in HZ) caused by applying a gradient (3x1, Gx, Gy, Gz) to a
%% spin position pos (3x1, x,y,z)
function df = CalculateGradientFreq(g,pos)
    gamma = 42.577e6;
    df = gamma * (pos(1) .* g(1) + pos(2) .* g(2) + pos(3) .* g(3));
end