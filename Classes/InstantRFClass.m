classdef InstantRFClass
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    properties
        alpha = []; % Flip angle in radians
        theta = []; % Phase of the RF
    end

    methods
        function obj = InstantRFClass(inputArg1,inputArg2)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end

        function outputArg = Excite(obj,M)
            % A
            outputArg = obj.Property1 + inputArg;
        end
    end

    methods (Static)
        function R = RotateTheta(theta,alpha)
        end
    end
end