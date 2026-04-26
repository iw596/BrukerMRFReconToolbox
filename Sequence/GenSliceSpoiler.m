function G = GenSliceSpoiler(amp,dur,riseTime,dt)
    risePoints =linspace(0,amp,round(riseTime/dt));
    flatTopPoints = ones([1,round(dur/dt)]).*amp;
    fallPoints =linspace(amp,0,round(riseTime/dt));
    G = cat(2,risePoints,flatTopPoints,fallPoints);
end