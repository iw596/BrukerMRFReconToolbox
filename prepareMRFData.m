
%% This function takes a bruker parameter structure and formats the data into the following styl
%% NRead X NPE1 X NPE2 X NTime X NCha
function data = prepareMRFData(MRFParams)
    
    % Data is orginally stored in MRFParams, no longer needed so can free
    % up the memory

    nextMultiple = 128 * ceil((MRFParams.NCol) / 128);
    padding = nextMultiple - MRFParams.NCol;
    data = MRFParams.data;
    data = reshape(data,[nextMultiple,params.NPointsPerPrep*params.MRFNPrepModules MRFParams.NLin MRFParams.NPar]);
    data = data(1:params.NCol,:,:);
    data = permute(data,[1 3 2 ]);
end