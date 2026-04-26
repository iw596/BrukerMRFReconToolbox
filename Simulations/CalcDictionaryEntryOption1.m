%% This function calcualtes a dictionary entry assuming instant excitation RF and instant preparation modules
function entry = CalcDictionaryEntryOption1(Magnetization,TR,TE,NPointsPerPrep,FATrain,prepModules,waitTimes,pos,spoiler,dt)
    NPrep = length(prepModules);
    M = Magnetization.M;
    T1 = Magnetization.T1;
    T2 = Magnetization.T2;
    B1 = Magnetization;
    totalPoints = NPrep * NPointsPerPrep;
    entry = zeros(totalPoints,1);
    curEntry = 1;
    for p = 1:NPrep
        if (prepList(p,1) == 0)
            %M = SimulateInversion(M,T1Tmp,T2Tmp,prepList(p,2));
        elseif (prepList(p,1) == 1)
            % M = T2PrepModuleInstantRF(M,prepList(p,2),T2PrepModSpoilerCycles,T1,T2);
            %M = SimulateT2Prep(M,prepList(p,2),NSpin,2,T1Tmp,T2Tmp);
        end
        for f = 1:NPointsPerPrep
            R = RotateTheta(deg2rad(FAList(curEntry)).*B1,0);
            M = R*M;
            % Gradient spoiling
            curEntry = curEntry + 1;
        end
        % Wait times
        [A,B] = freeprecess(waitTimes(p),T1,T2,0);
        M = A*M + B;
    end


end
