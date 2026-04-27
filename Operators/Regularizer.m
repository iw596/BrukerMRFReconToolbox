classdef (Abstract) Regularizer
    %REGULARIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = Regularizer()
        end
    end

    methods (Abstract)
        % Proximal operator
        x = prox(obj,x,tau)
    end
end

