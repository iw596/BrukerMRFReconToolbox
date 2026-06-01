classdef LLR < Regularizer
    %LLR Locally low rank regularizer.
    %
    %   obj = LLR(blockSize,randshift) creates a locally low rank regularizer.
    %   blockSize controls the spatial patch size used for low-rank
    %   shrinkage. randshift is a boolean that controls if random shifting
    %   of blocks should be used to suppress artefacts
    %   
    %   x = prox(obj, x, tau) applies blockwise nuclear norm soft-thresholding
    %   to each spatial patch in x.
    %
    %   Supports both 3D data (nx, ny, nt) and 4D data (nx, ny, nz, nt).

    properties
        patchSize = [8 8]
        windowSize = [1]
        randshift = true
    end

    methods
        function obj = LLR(patchSize,windowSize,randshift)
            if nargin >= 1 && ~isempty(blockSize)
                obj.BlockSize = blockSize;
            end

            if ~isempty(randshift)
                obj.randshift = randshift;
            end
        end

        function y= mtimes(obj, x)
            % For LR regularization, the "multiplication" operator is just the identity, since the regularizer is defined via its proximal operator.
            y = x
        end
        
        
        function x = prox(obj, x, lambda)
            % Calculates the proximal operator of LLR using thresholding
            if nargin < 3
                error('LLR:prox', 'prox requires x and tau.');
            end
            if isempty(x)
                return;
            end
            
            

            if (ndim(x) == 3)
                % 2D (+ time) pathway
                alpha_thresh = llr_thresh_2d(x,lambda);
            else
                % 3D (+ time) pathway

            end

            % Convert the images into patches

            x = obj.applyBlockwiseNuclearProx(x, lambda);
        end
    end

    methods (Access = private)
        
        function alpha_thresh = llr_thresh_3d(obj)
            Wx = obj.patchSize;
            Wy = obj.patchSize;
        
        end

        function alpha_thresh = llr_thresh_2d(obj,x,lambda)
                Wx = obj.patchSize(1);
                Wx = obj.patchSize(1);
                step = obj.windowSize;
                
                % Reshape data into patches

                if (obj.randshift)
                
                
                end
            
        end


    end
end
