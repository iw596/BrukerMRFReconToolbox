classdef PrepModule
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        module = []
    end

    methods
        function obj = PrepModule(name,params,dt,time)
            if (streq(name,"T2Prep") == 1)
                
            end
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end