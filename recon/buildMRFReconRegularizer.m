function regularizer = buildMRFReconRegularizer(context)
% buildMRFReconRegularizer  Create a regularizer skeleton for ADMM.
%
%   The returned struct stores regularizer-specific parameters and a prox
%   function handle. The prox operators are intentionally placeholders.

mode = lower(strtrim(context.RegularizationMode));
regularizer = struct();
regularizer.Mode = context.RegularizationMode;
regularizer.Lambda = context.Lambda;
regularizer.Prox = [];
regularizer.Evaluate = [];
regularizer.Description = '';

switch mode
    case 'locally-low rank'
        regularizer.Description = 'Locally low-rank regularizer';
        regularizer.BlockSize = context.BlockSize;
        regularizer.Stride = context.Stride;
        regularizer.Prox = @(x, rho) x;  % TODO: singular-value thresholding on patches
        regularizer.Evaluate = @(x) 0;

    case 'wavelet'
        regularizer.Description = 'Wavelet sparsity regularizer';
        regularizer.Prox = @(x, rho) x;  % TODO: wavelet soft-thresholding
        regularizer.Evaluate = @(x) 0;

    case 'total variation'
        regularizer.Description = 'Total variation regularizer';
        regularizer.Prox = @(x, rho) x;  % TODO: TV proximal operator
        regularizer.Evaluate = @(x) 0;

    otherwise
        error('buildMRFReconRegularizer:UnknownMode', ...
            'Unknown regularizer mode: %s', context.RegularizationMode);
end
end
