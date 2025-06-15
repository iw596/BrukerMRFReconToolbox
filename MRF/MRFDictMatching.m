function res = MRFDictMatching(imgs,dict,LUT,options)
    arguments
        imgs = [];
        dict = [];
        LUT = [];
        options.B1Map = [];
        options.parallelFlag = false;
    end
    
    
    
    if (isempty(options.B1Map))
        B1Map = zeros(size(data));
    else
        B1Map = options.B1Map;
    end
    
    %% Normalise the dictioanry

    res.MRFT1Map = [];
    res.MRFT2Map = [];
   

end