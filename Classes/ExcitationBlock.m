classdef ExcitationBlock
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        dt
        B1
    end

    methods
        function obj = untitled5(inputArg1,inputArg2)
            %UNTITLED5 Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
    
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end

        function M = RunRFSimulation(obj,M,FA)
            % Scale RF pulse to desired FA
        end
    end
end