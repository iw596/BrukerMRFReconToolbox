%% runMRFReconstruction is an interface which allows the user to perform direct MRF reconstruction (FFT -> matching) or subspace 
%% reconstruction. The user needs to provide a path to a data (inputSource), a struct containing the MRF dictionary and LUT
%% (dictionaryStruct) and a struct contianing the reconstruction options the user wants to use.
%% The function returns results which contains the fitted T1, T2 and M0 maps

%% Currently this function only handles Cartesian bruker data but will hopefully be expnaded to spiral data....

function [outputArg1,outputArg2] = runMRFReconstruction(inputSource,dictionaryStruct,options)
arguments (Input)
    inputSource % Path to MRF data
    dictionaryStruct % Struct containing LUT and dictionary
    options  % Struct containing user reconstruction options

end

arguments (Output)
    outputArg1
    outputArg2
end

if (isstruct(options) == false)
    error("options must be a valid matlab struct, aborting recon!")
end

%% Validate that the user has passed a valid set of options


%% Attempt to load the data file
MRFParams = LoadBrukerData(inputSource, true);


%% Now we format the data into the following dimensions NRo x NPE1 x NPE2 x NPoints
[data,samplingmask] = prepareMRFData(MRFParams); % Returns zero-filled data and sampling mask


%% Depending on user option we either do direct recon or subspace recon


outputArg1 = inputArg1;
outputArg2 = inputArg2;
end


function options = validateOptions(varargin)

    if isempty(varargin)
        error("No options have been passed into the function!");
    end

    
    % Extract all field names from option struct
    fieldNames = fieldnames(options);
    if isempty(fieldNames)
        error("Options struct is empty, please provide valid options.");
    end


    % Create default arrray of options

    defaults = struct();
    defaults.B1CorrectionMode = "None";
    defaults.B1Map = [];

    options = defaults;


    if (strcmp(options.B1CorrectionMode,"None") == false && isempty(options.B1Map) == true)
        error("B1 correction is desired but no B1 map has been supplied!");
    end


end



