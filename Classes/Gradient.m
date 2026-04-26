classdef Gradient
    %UNTITLED10 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        dt % Gradient raster time
        positions % Array of spatial positions x,y,z
        G % Array of gradient amplitudes
    end

    methods
        function obj = untitled10(inputArg1,inputArg2)
            %UNTITLED10 Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end