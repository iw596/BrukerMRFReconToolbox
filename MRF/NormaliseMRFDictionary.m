function dict_normalized = NormaliseMRFDictionary(dict)
    arguments
        dict = [];
    end
 if (~ismatrix(dict))
    error("Dictionary should have 2 dimensions")
 end

l2_norms = sqrt(sum(abs(dict).^2, 1));   % Compute L2 norm of each column (complex-safe)
zeroCols = (l2_norms <= eps(class(l2_norms)));
l2_norms(zeroCols) = 1;
dict_normalized = dict ./ l2_norms; % Normalize each column
if any(zeroCols)
    dict_normalized(:, zeroCols) = 0;
end

end