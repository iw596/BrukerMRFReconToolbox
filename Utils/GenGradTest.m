amp = 86822.9 * 11.9976027829831./100;
amp =  (1000 * amp)/42.56e6;
dur = (0.192 -0.128 )/1000
dT = 1e-7;
risePoints =linspace(0,amp,round(0.128e-3/dT));
flatTopPoints = ones([1,round(dur/dT)]).*amp;
fallPoints =linspace(amp,0,round(0.128e-3/dT));
G = cat(2,risePoints,flatTopPoints,fallPoints);

2*pi*sum(G) * dT * 42.57e6*1e-3


amp = 86822.9 * 11.9976027829831./100;
amp =  0.04998;
dur = 0.0003418;
dT = 1e-7;
risePoints =linspace(0,amp,round(0.128e-3/dT));
flatTopPoints = ones([1,round(dur/dT)]).*amp;
fallPoints =linspace(amp,0,round(0.128e-3/dT));
G = cat(2,risePoints,flatTopPoints,fallPoints);

2*pi*sum(G) * dT * 42.57e6*1e-3