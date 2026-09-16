function regularizer = buildMRFReconRegularizer(context)
%buildMRFReconRegularizer Create the LLR regularizer used by iterative MRF.
%
% The iterative reconstruction solves
%
%   min_x 0.5 || A*x - d ||_2^2 + lambda R_LLR(x).
%
% Only one regularizer is supported intentionally. The LLR class owns the
% block geometry and proximal operator, leaving this function as a small
% dependency-injection point for the reconstruction pipeline.

mode = string(context.RegularizationMode);
if ~strcmpi(strtrim(mode), 'locally-low rank')
    error('buildMRFReconRegularizer:UnsupportedMode', ...
        'Only ''Locally-low rank'' is currently supported, received ''%s''.', mode);
end

regularizer = LLR(context.BlockSize, context.Stride, context.Lambda);
end
