%% This function is used to generate MRF undersampling masks
%% user passes in dimensions (dim) and opts which is a matlab struct containing
%% options relevant to generating sampling mask
%% Fields in opts
%% plotMask - boolean if yes then a frame of the mask and the cummulatie distribution will be shown
%% autoCalibSize - auto-calibration region size. Central region of fully sampled k-space data
%% ellipticalMask - boolean which determines if an ellipitcal mask should be applied to the data
%% sigma - determines the rate of roll-off for the elliptical mask
function results = runGenerateSamplingMaskCLI(dims,R,opts)

arguments (Input)
    dims % Data input dimensions, typically Ny X Nz X NFA
    R % Desired acceleration factor
    opts
end

arguments (Output)
    results
end
    
    opts = ValidateOptions(opts);
    results = GenerateSamplingMask(dims,R,opts);
end


function options = ValidateOptions(varargin)
    
    if isempty(varargin)
        error("No options have been passed into the function!");
    end
    userOptions = varargin{1};
    % Extract all field names from option struct
    fieldNames = fieldnames(options);
    if isempty(fieldNames)
        error("Options struct is empty, please provide valid options.");
    end



    % Create default arrray of options
    defaults = struct();
    defaults.plotMask = false;
    defaults.ellipticalMask = false;
    defaults.sigma = 80;
    defaults.autoCalibSize = [6,6];
    options = defaults;
    
    for fieldIndex = 1:numel(fieldNames)
        fieldName = fieldNames{fieldIndex};
        if isfield(defaults, fieldName)
            options.(fieldName) = userOptions.(fieldName);
        end
    end



end