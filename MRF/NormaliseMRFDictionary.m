function dict_normalized = NormaliseMRFDictionary(dict)
    arguments
        dict = [];
    end
 if (~ismatrix(dict))
    error("Dictionary should have 2 dimensions")
 end

l2_norms = sqrt(sum(dict.^2, 1));   % Compute L2 norm of each column
dict_normalized = dict ./ l2_norms; % Normalize each column

end