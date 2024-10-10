%% Function to generate (using Bloch simulation) an MRF dictionary
%% if file path is provided then data will be saved 
function [dict,LUT] = GenerateDictionary(FA,TR,TE,TI,T1List,T2List,B1,spoilingCycles,NIso,pth)
    if (nargin < 10)
        saveDictionary = 0;
    else
        saveDictionary = 1;
    end
    
    % Calculate all T1, T2 and B1 pairs
    T1Length = length(T1List);
    T2Length = length(T2List);
    B1Length = length(B1);
    NDictionaryEntries = 0 ;
    % Prepare look-up table containing all valid pairs
    for ii = 1:T1Length
        for jj = 1:T2Length
            for kk = 1:B1Length
                % Only keep physically feasible pairs (i.e. T1 > T2)
                if (T1List(ii)>=T2List(jj))
                    LUT(NDictionaryEntries+1,[1:3]) = [T1List(ii),T2List(jj),B1(kk)];
                    NDictionaryEntries = NDictionaryEntries + 1;
                end
            end
        end
    end
    
    % Prepare variables for simulation
    if (isscalar(TR))
        TR = repmat(TR,size(FA));
    elseif (length(TR) ~= length(FA))
        error("Lengths of FA and TR are not equal!");
    end
    
    % Run Bloch simulation
    
    parfor i = 1:NDictionaryEntries
        T1 = LUT(i,1);
        T2 = LUT(i,2);
        B1 = LUT(i,3);
        dict(i,:) = MRF_FISP_BlochSim(T1,T2,B1.*FA,TR,TE,TI,spoilingCycles,NIso);
    end
    
    if (saveDictionary == 1)
        pth = pth + '\\dictionary';
        save(pth,'dict','LUT');
    end

    

end

