
%% This function takes a bruker parameter structure and formats the data into the following styl
%% NRead X NPE1 X NPE2 X NTime X NCha
function [data,samplingmask] = prepareMRFData(MRFParams)
    
    FAIndex = 1:MRFParams.NPointsPerPrep * MRFParams.MRFNPrepModules;
   


    %% Check if undersampled or not
    if (MRFParams.Traj.cartesianUndersamplingYesNo == true)
        disp("MRF Undersampling detected....")
        nRead = MRFParams.NCol;
        nLin = MRFParams.NLin;
        nPar = MRFParams.NPar;
        nFA = MRFParams.NPointsPerPrep * MRFParams.MRFNPrepModules;
        nSamples = size(MRFParams.Traj.CartPE1, 1);
        nextMultiple = 128 * ceil((nRead) / 128);
        repFactor = nSamples / nFA;
        if abs(repFactor - round(repFactor)) > eps(max(repFactor,1))
            error('prepareMRFData:InvalidTrajectoryLength', ...
                'Trajectory length (%d) is not an integer multiple of NFA (%d).', nSamples, nFA);
        end
        repFactor = round(repFactor);
        FAIndex = repmat(FAIndex, 1, repFactor);

        data = zeros(nextMultiple, nLin, nPar, nFA, 'like', MRFParams.data);
        samplingmask = zeros(nRead, nLin, nPar, nFA, 'like', real(MRFParams.data));

        fid = reshape(MRFParams.data, [nRead nSamples]);

        linIdx3D = sub2ind([nLin nPar nFA], ...
            MRFParams.Traj.CartPE1(:), MRFParams.Traj.CartPE2(:), FAIndex(:));
        baseOffset = (linIdx3D - 1) * nRead;
        rowOffset = (0:nRead-1)';
        linearIdx = rowOffset + baseOffset.';

        data(linearIdx) = fid;
        samplingmask(linearIdx) = 1.0;
        clear("fid");
        data = data(1:nRead,:,:,:);

    else
        disp("MRF dataset is fully sampled...")
        nextMultiple = 128 * ceil((MRFParams.NCol) / 128);
        data = MRFParams.data;
        data = reshape(data,[nextMultiple,MRFParams.NPointsPerPrep*MRFParams.MRFNPrepModules MRFParams.NLin MRFParams.NPar]);
        data = data(1:MRFParams.NCol,:,:);
        data = permute(data,[1 3 4 2 ]);
        samplingmask = ones(size(data), 'like', real(data));

    end



    % Data is orginally stored in MRFParams, no longer needed so can free
    % up the memory

end