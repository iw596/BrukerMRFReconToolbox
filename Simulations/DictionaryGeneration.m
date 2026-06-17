classdef DictionaryGeneration
    %DICTIONARYGENERATION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FA
        TR
        TE
        InversionPulse
        dt
    end
    
    methods
        function obj = DictionaryGeneration(params)
            %DICTIONARYGENERATION Construct an instance of this class
            %   Detailed explanation goes here
            obj.TR = TR;
            obj.TE = TE;
            obj.FA = FA;
        end
        
        function outputArg = RunSimulation(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

