classdef T2PrepMLEV < PrepModule
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        TE = []
        rectPulseDuration = []
    end

    methods
        function obj = T2PrepMLEV(params,TE,dt)
            obj.TE = TE;
            obj.rectPulseDuration = params.MRFT2RectPulse.duration;
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end

        function GenerateModule(obj)
            FA = pi/2;
            gamma = 42.57e6;
            % Generate 90 degree pulse
            RF90 = one

            
        end

    end

    
end