classdef RFModule
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        B1
        dt
    end

    methods
        function obj = RFModule(inputArg1,inputArg2)
            %UNTITLED5 Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end

        function outputArg = Simulate(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end