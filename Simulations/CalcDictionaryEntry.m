function entry = CalcDictionaryEntry(T1,T2,B1,prepList,FAList,waitTimes,M,phi,params)
     NPrep = size(prepList,1);
     NPointsPerPrep = params.NPointsPerPrep; 
     entry = zeros([NPointsPerPrep*NPrep,1]);
     curEntry = 1;
     TR = params.TR;
     TE = params.TE;
     NSpin = size(M,2);
     InversionModSpoilerCycles = params.T1PrepSpoiler.NCycles*2;
     T2PrepModSpoilerCycles = params.T2PrepSpoiler.NCycles*2;
     % Run through prep modules
    for p = 1:NPrep
        if (prepList(p,1) == 0)
             M = T1PrepModuleInstantRF(M,prepList(p,2)/1000,InversionModSpoilerCycles,T1,T2);
            %M = SimulateInversion(M,T1Tmp,T2Tmp,prepList(p,2));
        elseif (prepList(p,1) == 1)
            M = T2PrepModuleInstantRF(M,prepList(p,2),T2PrepModSpoilerCycles,T1,T2);
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
            for j = 1:NSpin
                M(:,j) = zrot(phi(j)) * M(:,j);
                %M(:,j) = rotmat([0 0 phi(j)]) * M(:,j);
            end
            curEntry = curEntry + 1;
        end
        
        % Wait for delay time
        [A,B] = freeprecess(waitTimes(p),T1,T2);
        %[A,B] = freeprecess(500,T1Tmp,T2Tmp);
        M = A*M + B;

    end
end

