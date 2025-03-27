function entry = CalcDictionaryEntryWithPos(T1,T2,B1,prepList,FAList,waitTimes,M,pos,params)
     NPrep = size(prepList,1);
     NPointsPerPrep = params.NPointsPerPrep; 
     entry = zeros([NPointsPerPrep*NPrep,1]);
     curEntry = 1;
     TR = params.TR;
     TE = params.TE;
     NSpin = size(M,2);
     dt = 10e-6;
     gamma = 42.57*10^6; % Gyromagnetic constant of 1H is MHz/T
     % Generate spoiler
     G = GenSliceSpoiler(params.MRFSpoiler.amplitude/1000,params.MRFSpoiler.duration/1000,params.RiseTime,dt);

     % Run through prep modules
    for p = 1:NPrep
        if (prepList(p,1) == 0)
            M = SimulateT1PrepSech(params,prepList(p,2)/1000,M,pos,T1,T2,true);
            %M = SimulateInversion(M,T1Tmp,T2Tmp,prepList(p,2));
        elseif (prepList(p,1) == 1)
           % M = T2PrepModuleInstantRF(M,prepList(p,2),T2PrepModSpoilerCycles,T1,T2);
            %M = SimulateT2Prep(M,prepList(p,2),NSpin,2,T1Tmp,T2Tmp);
        end
       % Run through the correct portion of the FA train
        for f = 1:NPointsPerPrep
            R = RotateTheta(deg2rad(FAList(curEntry)).*B1,0);
            %R = throt(FAList(faCounter).*B1Tmp,0);
            M = R*M;
            % Precess to TE
            [A,B] = freeprecess(TE,T1,T2);
            M = A*M + B; 
            % Store signal 
            entry(curEntry) =-1i * mean(complex(M(1,:),M(2,:)));
            % Precess until next TR
            [A,B] = freeprecess(TR - TE,T1,T2);
            M = A*M + B;

            % Apply spoiling as rotation in z direction
            [A,B] = freeprecess(dt,T1,T2);
            for curPos = 1:size(M,2)
                for curG = 1:length(G)
                    RG = zrot(2*pi*gamma*pos(p)*G(curG)*dt);
                    M(:,curPos) = RG*M(:,curPos);
                    M(:,curPos) = A*M(:,curPos) + B;
                end
            end
            curEntry = curEntry + 1;
        end
        
        % Wait for delay time
        [A,B] = freeprecess(waitTimes(p),T1,T2);
        %[A,B] = freeprecess(500,T1Tmp,T2Tmp);
        M = A*M + B;

    end
end