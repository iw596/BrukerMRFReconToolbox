classdef T2PrepMLEVModule
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        RFDur
        dt
        spoilerGrad
    end

    methods
        function obj = T2PrepMLEVModule(inputArg1,inputArg2)
                %UNTITLED4 Construct an instance of this class
                %   Detailed explanation goes here
                obj.RFDur = inputArg1 + inputArg2;
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end