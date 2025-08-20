function res = MRFDictMatching(imgs,dict,LUT,options)
    arguments
        imgs = [];
        dict = [];
        LUT = [];
        options.EstimateB1Map = false;
        options.B1Map = [];
        options.parallelFlag = false;
    end
    
    
    %% Extract spatial dimensions
    [NRO,NPE,NSLI,~] = size(imgs);

    %% Handle B1 map
    if (isempty(options.B1Map))
        B1Map = ones([NRO,NPE,NSLI]); % Assume perfect B1 field
    else
        B1Map = options.B1Map;
    end

    %% Normalise the dictioanry
    dictNorm = NormaliseMRFDictionary(dict);
    
    %% Begin matching
  
    if (options.EstimateB1Map == false)
    if (options.parallelFlag == false)
        for i = 1:NRO
            i
            for j = 1:NPE
                for k = 1:NSLI       
                    % Scale pixel intensity by L2 norm
                    scaleFactor = sqrt(sum(imgs(i,j,k,:).*conj(imgs(i,j,k,:))));
                    normalized_mrfsignal = conj(imgs(i,j,k,:))/scaleFactor;
    
                    % Extract B1 at current pixel position
                    B1Tmp = squeeze(B1Map(i,j,k));
                    % Find closest B1 val in LUT and extract a sub-LUT
                    [~,idx] = min(abs(B1Tmp-squeeze(LUT(:,3))));
                    closestB1 = LUT(idx,3);
                    idx=find(LUT(:,3) == closestB1);
                    subDict = dictNorm(:,idx);
                    subLUT = LUT(idx,:);
                    % Take inner product of MRF signal and sub dictionary to
                    % calculate best match
                    inner_product=abs(squeeze(normalized_mrfsignal)'* (subDict));
                    [~, max_index] = max(abs(inner_product));
                    % Save parameters
                    matched_indices(i, j,k) = max_index;
                    T1Map(i,j,k) = subLUT(max_index,1);
                    T2Map(i,j,k) = subLUT(max_index,2);
                    MRFMask(i,j,k) = 1;
                    indexMap(i,j,k) = max_index;
                end
            end
        end
    else
        parfor i = 1:NRO
            for j = 1:NPE
                for k = 1:NSLI
                    % Scale pixel intensity by L2 norm
                    scaleFactor = sqrt(sum(imgs(i,j,k,:).*conj(imgs(i,j,k,:))));
                    normalized_mrfsignal = conj(imgs(i,j,k,:))/scaleFactor;

                    % Extract B1 at current pixel position
                    B1Tmp = squeeze(B1Map(i,j,k));
                    % Find closest B1 val in LUT and extract a sub-LUT
                    [~,idx] = min(abs(B1Tmp-squeeze(LUT(:,3))));
                    closestB1 = LUT(idx,3);
                    idx=find(LUT(:,3) == closestB1);
                    subDict = dictNorm(:,idx);
                    subLUT = LUT(idx,:);
                    % Take inner product of MRF signal and sub dictionary to
                    % calculate best match
                    inner_product=abs(squeeze(normalized_mrfsignal)'* (subDict));
                    [~, max_index] = max(abs(inner_product));
                    % Save parameters
                    matched_indices(i, j,k) = max_index;
                    T1Map(i,j,k) = subLUT(max_index,1);
                    T2Map(i,j,k) = subLUT(max_index,2);
                    MRFMask(i,j,k) = 1;
                    indexMap(i,j,k) = max_index;
                end
            end
        end
    end
    else
        if (options.parallelFlag == false)
          for i = 1:NRO
            for j = 1:NPE
                for k = 1:NSLI
                    % Scale pixel intensity by L2 norm
                    scaleFactor = sqrt(sum(imgs(i,j,k,:).*conj(imgs(i,j,k,:))));
                    normalized_mrfsignal = conj(imgs(i,j,k,:))/scaleFactor;
                    % Take inner product of MRF signal and sub dictionary to
                    % calculate best match
                    inner_product=abs(squeeze(normalized_mrfsignal)'* (dictNorm));
                    [~, max_index] = max(abs(inner_product));
                    % Save parameters
                    matched_indices(i, j,k) = max_index;
                    T1Map(i,j,k) = LUT(max_index,1);
                    T2Map(i,j,k) = LUT(max_index,2);
                    MRFMask(i,j,k) = 1;
                    indexMap(i,j,k) = max_index;
                    MRFB1Map(i,j,k) = LUT(max_index,3);
                end
            end
          end
        else
          parfor i = 1:NRO
            for j = 1:NPE
                for k = 1:NSLI
                    % Scale pixel intensity by L2 norm
                    scaleFactor = sqrt(sum(imgs(i,j,k,:).*conj(imgs(i,j,k,:))));
                    normalized_mrfsignal = conj(imgs(i,j,k,:))/scaleFactor;
                    % Take inner product of MRF signal and sub dictionary to
                    % calculate best match
                    inner_product=abs(squeeze(normalized_mrfsignal)'* (dictNorm));
                    [~, max_index] = max(abs(inner_product));
                    % Save parameters
                    matched_indices(i, j,k) = max_index;
                    T1Map(i,j,k) = LUT(max_index,1);
                    T2Map(i,j,k) = LUT(max_index,2);
                    MRFMask(i,j,k) = 1;
                    indexMap(i,j,k) = max_index;
                    MRFB1Map(i,j,k) = LUT(max_index,3);
                end
            end
          end
        end
    end
    res.MRFT1Map = T1Map;
    res.MRFT2Map = T2Map;
    res.indexMap = indexMap;
    if (options.EstimateB1Map == true)
        res.MRFB1Map = MRFB1Map;
    end
   
end