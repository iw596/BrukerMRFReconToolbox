function newWaveform = InterpolateRFWaveform(waveform,T,dtOld,dtNew)
    tOld = linspace(0,T,round(T/dtOld)); % orig sample points
    tNew = linspace(0,T,round(T/dtNew)); % orig sample points
    newWaveform = interp1(tOld,waveform,tNew,"spline");
end

