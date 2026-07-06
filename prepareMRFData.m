
%% This function takes a bruker parameter structure and formats the data into the following styl
%% NRead X NPE1 X NPE2 X NTime X NCha
function [data,samplingmask] = prepareMRFData(MRFParams)
    
    FAIndex = 1:MRFParams.NPointsPerPrep * MRFParams.MRFNPrepModules;
   


    %% Check if undersampled or not
    if (MRFParams.Traj.cartesianUndersamplingYesNo == true)
        FAIndex = repmat(FAIndex,1,size(MRFParams.Traj.CartPE1,1)./MRFParams.NPointsPerPrep * MRFParams.MRFNPrepModules);
        fid = params.data;
        fid = reshape(fid,[params.NCol size(params.Traj.CartPE1,1)]);

        for j = 1:size(MRFParams.Traj.CartPE1,1)
            j
            cLin = MRFParams.Traj.CartPE1(j);
            cPar = MRFParams.Traj.CartPE2(j);
            cFA = FAIndex(j);
            data(:,cLin,cPar,cFA) = fid(:,j);
            samplingmask(:,cLin,cPar,cFA) = 1.0;
        end
        clear("fid");

    else
        nextMultiple = 128 * ceil((MRFParams.NCol) / 128);
        padding = nextMultiple - MRFParams.NCol;
        data = MRFParams.data;
        data = reshape(data,[nextMultiple,MRFParams.NPointsPerPrep*MRFParams.MRFNPrepModules MRFParams.NLin MRFParams.NPar]);
        data = data(1:MRFParams.NCol,:,:);
        data = permute(data,[1 3 4 2 ]);

    end



    % Data is orginally stored in MRFParams, no longer needed so can free
    % up the memory

end