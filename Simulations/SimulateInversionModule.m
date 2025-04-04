function MNew = SimulateInversionModule(TI,Magnetization,pos,params,dt,instantExcRFFlag,instantInversionRFFlag,inversionRF)
M = Magnetization.M;
T1 = Magnetization.T1;
T2 = Magnetization.T2;
if (nargin < 8)
    instantInversionRFFlag = true;
    inversionRF = [];
end

% Generate spoiler
amp = ((params.PVM_GradCalConst*params.T1PrepSpoiler.amplitude/100)*1000)/gamma;
gradDur = params.T1PrepSpoiler.duration - params.RiseTime;
G = GenSliceSpoiler(amp,gradDur,params.RiseTime,dt);

% Set-up spoiler
GSpoil = GradientSpoiler(G,dt);


% Calculate the TI delay based off flags
if (instantExcRFFlag == false && instantInversionRFFlag == false)
    % Full simulation
    delay = TI - params.MRFInversionPulse.duration/2-gradDur - 3*params.RiseTime -params.EncGradDur/2;

elseif (instantExcRFFlag == false && instantInversionRFFlag == true )
    delay = TI -gradDur - 3*params.RiseTime -params.EncGradDur/2;

else
    % Instant excitation and inversion
    delay = TI -gradDur - 2*params.RiseTime;
end

%% Apply excitation
if instantInversionRFFlag == true
    R = RotateTheta(pi,0);
    M = R*M;
else
    M = RFExcitation(inversionRF,dt,M,pos,T1,T2);
end

%% Apply gradient
M = GSpoil.ApplyGradient(M,pos,T1,T2,0);

[A,B] = freeprecess(delay,T1,T2);
MNew = A*M + B;
end