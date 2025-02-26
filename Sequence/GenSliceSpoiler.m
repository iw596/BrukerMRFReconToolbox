function G = GenSliceSpoiler(amp,dur,riseTime,dT)
    risePoints =linspace(0,amp,round(riseTime/dT));
    flatTopPoints = ones([1,round(dur/dT)]).*amp;
    fallPoints =linspace(amp,0,round(riseTime/dT));
    G = cat(2,risePoints,flatTopPoints,fallPoints);
end