function dictEntry = simulateSingleLUTEntryFISP(i, LUT, prepList, nPointsPerPrep, ...
    instantInversionFlag, inversionB1, gInvSpoiler, gSliSpoiler, ...
    dt, df, dp, dv, faList, TR, TE, riseT, sliceSpoilerDuration, waitTimes, nSpin)
% simulateSingleLUTEntryFISP Simulate one LUT entry for FISP-MRF dictionary generation.

dictEntry = zeros(size(prepList,1) * nPointsPerPrep, 1);
T1Tmp = LUT(i,1);
T2Tmp = LUT(i,2);
B1Tmp = LUT(i,3);

M = zeros([3, nSpin]);
M(3,:) = 1;
curEntry = 1;
faCounter = 1;

for p = 1:size(prepList,1)
    if prepList(p,1) == 0
        if instantInversionFlag
            M = InstantRFExcitation(M, pi, 0);
        else
            [mx, my, mz] = bloch_Hz(inversionB1, zeros(length(inversionB1),1), dt, T1Tmp, T2Tmp, df, dp, dv, 0, M(1,:), M(2,:), M(3,:));
            M = [mx(:)'; my(:)'; mz(:)'];
        end

        [mx, my, mz] = bloch_Hz(0, gInvSpoiler, dt, T1Tmp, T2Tmp, df, dp, dv, 0, M(1,:), M(2,:), M(3,:));
        M = [mx(:)'; my(:)'; mz(:)'];

        [A, B] = freeprecess(prepList(p,2) / 1000, T1Tmp, T2Tmp);
        M = A * M + B;

    elseif prepList(p,1) == 1
        t2PrepTE = prepList(p,2) / 1000;

        M = InstantRFExcitation(M, pi/2, 0);
        [A, B] = freeprecess(t2PrepTE/4, T1Tmp, T2Tmp);
        M = A * M + B;

        M = InstantRFExcitation(M, pi, pi/2);
        [A, B] = freeprecess(t2PrepTE/2, T1Tmp, T2Tmp);
        M = A * M + B;

        M = InstantRFExcitation(M, pi, pi/2);
        [A, B] = freeprecess(t2PrepTE/4, T1Tmp, T2Tmp);
        M = A * M + B;

        M = InstantRFExcitation(M, pi/2, pi);
        [mx, my, mz] = bloch_Hz(0, gInvSpoiler, dt, T1Tmp, T2Tmp, df, dp, dv, 0, M(1,:), M(2,:), M(3,:));
        M = [mx(:)'; my(:)'; mz(:)'];
    end

    for f = 1:nPointsPerPrep
        R = RotateTheta(faList(faCounter) * B1Tmp, 0);
        M = R * M;

        [A, B] = freeprecess(TE, T1Tmp, T2Tmp);
        M = A * M + B;
        dictEntry(curEntry) = mean(complex(M(1,:), M(2,:)));

        [A, B] = freeprecess(TR - TE - riseT - sliceSpoilerDuration, T1Tmp, T2Tmp);
        M = A * M + B;

        [mx, my, mz] = bloch_Hz(zeros(length(gSliSpoiler),1), gSliSpoiler, dt, T1Tmp, T2Tmp, df, dp, dv, 0, M(1,:), M(2,:), M(3,:));
        M = [mx(:)'; my(:)'; mz(:)'];

        faCounter = faCounter + 1;
        curEntry = curEntry + 1;
    end

    [A, B] = freeprecess(waitTimes(p), T1Tmp, T2Tmp);
    M = A * M + B;
end
end
