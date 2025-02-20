


% Set-up gradient
amp =  0.04998;
dur = 0.0003418;
dT = 10e-6;
risePoints =linspace(0,amp,round(0.128e-3/dT));
flatTopPoints = ones([1,round(dur/dT)]).*amp;
fallPoints =linspace(amp,0,round(0.128e-3/dT));
G = cat(2,risePoints,flatTopPoints,fallPoints);

2*pi*sum(G) * dT * 42.57e6*1e-3



% Set-up slice positions and Magnetization vector
NSpin = 200;
pos = linspace(-0.5e-3,0.5e-3,NSpin);
% Set-up starting magnetization
M = zeros([3,NSpin]);
M(3,:) = 1;


TR = params.TR * 1000;
TE = 1.42;

curEntry = 1;
% Run through the FA train
for f = 1:length(FA)
    R = throt(FA(f).*B1Tmp,0);
    M = R*M;
    % Precess to TE
    [A,B] = freeprecess(TE,T1Tmp,T2Tmp);
    M = A*M + B;
    % Store signal
    dict(curEntry,i) = mean(complex(M(1,:),M(2,:)));
    % Precess until next TR
    [A,B] = freeprecess(TR - TE,T1Tmp,T2Tmp);
    M = A*M + B;

    % Apply spoiling as rotation in z direction
    for t = 1:length(G)
        for j = 1:NSpin
            Rgrad = zrot((2*pi*42.58e6*pos(j)*G(t))*dT);	% zrot(a) = rotation matrix.
            M(:,j) = Rgrad * M(:,j);
        end
    end
    curEntry = curEntry + 1;
end
