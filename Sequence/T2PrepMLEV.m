classdef T2PrepMLEV 
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        TE = []
        tau = []
        dt = [];
    end

    methods
        function obj = T2PrepMLEV(params,TE,tau,dt)
            obj.TE = TE;
            obj.tau = tau;
            obj.dt = dt;
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end

        function GenerateModule(obj)
            FA = pi/2;
            gamma = 42.57e6;
            B1 = [];
            % Generate the initial 90 (+x) degree pulse
            RF90 = one
            
            % Create first wait period (TE/8)
            d1 = obj.TE/8;

            % Generate first composite pulse
            
        

            
        end

    end

    
end