
classdef SubpaceOp
    %SUBPACEOP This class implements a temporal sub-space operator. It
    % stores an orthogonal basis operator of dimensions [T,K] that can be
    % applied to image im [I1 I2,...,IN.T]. K is the number of basis
    % coefficients and T is the number of frames. 

    properties
        Phi
        adjoint = 0;
        T = []; % Number of frames
        K = []; % Number of sub-space coefficients
    end

    methods
        function obj = SubpaceOp(Phi)
            %SUBPACEOP Constructer

            if (ndims(Phi) ~= 2)
                error("Subspace size has to have two dimensions")
            end
            obj.Phi = Phi;
            [T,K] = size(Phi);
            obj.T = T;
            obj.K = K;
        end

        function x = mtimes(obj,alpha)
             dims = size(alpha);
             L = prod(dims(1:end-1)); % Minus 1 as we dont want last dimension
            if (obj.adjoint == 0)
                % Forward operation back-projects subspace images onto
                % original time dimension
                x = obj.Phi * reshape(alpha,L,obj.K).';
                dims2 = dims;
                dims2(end) = obj.T;
                x = reshape(x.', dims2);
            else
                % Temporal adjoint operation orthogonal projection x =
                % Phi' * im. Compressed images into temporal sub-space
                x = obj.Phi' * reshape(alpha, L, obj.T).';
                dims2 = dims;
                dims2(end) = obj.K;
                x = reshape( x.', dims2);
            end

            end

        function res = ctranspose(obj)
            obj.adjoint = xor(obj.adjoint,1);
            res = obj;
        end
    end
end