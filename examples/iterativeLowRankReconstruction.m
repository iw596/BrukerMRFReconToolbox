% % function coefficientImages = iterativeLowRankReconstruction(undersampled_kspace, rank)
% %     % Parameters
% %     maxIterations = 50; % Maximum iterations for convergence
% %     tolerance = 1e-4; % Convergence threshold
% % 
% %     % Initialize
% %     [nx, ny, nt] = size(undersampled_kspace);
% %     coefficientImages = zeros(nx, ny, rank); % Low-rank coefficients
% %     reconstructedData = zeros(nx, ny, nt); % Reconstructed time-series data
% % 
% %     % Iterative Low-Rank Approximation
% %     for iter = 1:maxIterations
% %         % Step 1: Apply SVD to estimate low-rank components
% %         [U, S, V] = svd(reshape(reconstructedData, [], nt), 'econ');
% % 
% %         % Keep only the largest singular values
% %         U = U(:, 1:rank);
% %         S = S(1:rank, 1:rank);
% %         V = V(:, 1:rank);
% % 
% %         % Update coefficient images
% %         coefficientImages = reshape(U * S, nx, ny, rank);
% % 
% %         % Step 2: Reconstruct data using updated coefficients
% %         reconstructedData = reshape(coefficientImages, nx * ny, rank) * V';
% % 
% %         % Step 3: Enforce consistency with undersampled k-space data
% %         for t = 1:nt
% %             kspaceEstimate = fft2(reconstructedData(:, :, t));
% %             undersampled_kspace(:, :, t) = ...
% %                 undersampled_kspace(:, :, t) + (kspaceEstimate - undersampled_kspace(:, :, t));
% %         end
% % 
% %         % Check convergence
% %         if norm(reconstructedData(:) - coefficientImages(:)) / norm(coefficientImages(:)) < tolerance
% %             disp(['Converged at iteration ', num2str(iter)]);
% %             break;
% %         end
% %     end
% % 
% %     disp('Iterative Low-Rank Reconstruction Completed.');
% % end
% 
% function coefficientImages = iterativeLowRankReconstruction(undersampled_kspace, rank)
%     % Iterative Low-Rank Reconstruction for MRF k-space data
%     % Inputs:
%     %   undersampled_kspace: 3D matrix of undersampled k-space data (Nx x Ny x TimePoints)
%     %   rank: Desired rank for low-rank approximation
%     % Output:
%     %   coefficientImages: Reconstructed coefficient images after low-rank reconstruction
% 
%     [Nx, Ny, TimePoints] = size(undersampled_kspace);
%     coefficientImages = zeros(Nx, Ny, rank); % Initialize the coefficient images
% 
%     % Initialization of k-space estimate
%     kspaceEstimate = undersampled_kspace;
% 
%     % Iterative Low-Rank Reconstruction
%     maxIterations = 20;
%     tolerance = 1e-5;
% 
%     for iter = 1:maxIterations
%         disp(['Iteration ', num2str(iter), ' of ', num2str(maxIterations)]);
% 
%         % Perform SVD across time dimension
%         kspaceReshaped = reshape(kspaceEstimate, [], TimePoints);
%         [U, S, V] = svd(kspaceReshaped, 'econ');
%         S(rank+1:end, :) = 0; % Truncate singular values
%         kspaceReshaped = U * S * V';
% 
%         % Reshape back to original dimensions
%         kspaceEstimate = reshape(kspaceReshaped, Nx, Ny, TimePoints);
% 
%         % Update using undersampled k-space
%         for t = 1:TimePoints
%             % Debugging: Ensure compatibility of dimensions
%             if ~isequal(size(undersampled_kspace(:, :, t)), size(kspaceEstimate(:, :, t)))
%                 error('Dimension mismatch between undersampled_kspace and kspaceEstimate at time point %d', t);
%             end
% 
%             % Incorporate undersampled k-space into the estimate
%             kspaceEstimate(:, :, t) = undersampled_kspace(:, :, t) + ...
%                 (kspaceEstimate(:, :, t) - undersampled_kspace(:, :, t));
%         end
% 
%         % Check for convergence
%         diffNorm = norm(kspaceEstimate(:) - undersampled_kspace(:)) / norm(undersampled_kspace(:));
%         disp(['Iteration ', num2str(iter), ' Relative Change: ', num2str(diffNorm)]);
%         if diffNorm < tolerance
%             disp('Convergence achieved.');
%             break;
%         end
%     end
% 
%     % Compute coefficient images
%     coefficientImages = reshape(kspaceEstimate, Nx, Ny, rank);
% end


function coefficientImages = iterativeLowRankReconstruction(undersampled_kspace, rank)
    % Iterative Low-Rank Reconstruction for MRF k-space data
    % Inputs:
    %   undersampled_kspace: 3D matrix of undersampled k-space data (Nx x Ny x TimePoints)
    %   rank: Desired rank for low-rank approximation
    % Output:
    %   coefficientImages: Reconstructed coefficient images after low-rank reconstruction

    [Nx, Ny, TimePoints] = size(undersampled_kspace);
    coefficientImages = zeros(Nx, Ny, rank); % Initialize the coefficient images

    % Initialization of k-space estimate
    kspaceEstimate = undersampled_kspace;

    % Iterative Low-Rank Reconstruction
    maxIterations = 20;
    tolerance = 1e-5;

    for iter = 1:maxIterations
        disp(['Iteration ', num2str(iter), ' of ', num2str(maxIterations)]);

        % Perform SVD across time dimension
        kspaceReshaped = reshape(kspaceEstimate, [], TimePoints); % Flatten spatial dimensions
        [U, S, V] = svd(kspaceReshaped, 'econ');
        S(rank+1:end, :) = 0; % Truncate singular values
        kspaceReshaped = U * S * V';

        % Reshape back to original dimensions
        kspaceEstimate = reshape(kspaceReshaped, Nx, Ny, TimePoints);

        % Update using undersampled k-space
        for t = 1:TimePoints
            % Debugging: Ensure compatibility of dimensions
            if ~isequal(size(undersampled_kspace(:, :, t)), size(kspaceEstimate(:, :, t)))
                error('Dimension mismatch between undersampled_kspace and kspaceEstimate at time point %d', t);
            end

            % Incorporate undersampled k-space into the estimate
            kspaceEstimate(:, :, t) = undersampled_kspace(:, :, t) + ...
                (kspaceEstimate(:, :, t) - undersampled_kspace(:, :, t));
        end

        % Check for convergence
        diffNorm = norm(kspaceEstimate(:) - undersampled_kspace(:)) / norm(undersampled_kspace(:));
        disp(['Iteration ', num2str(iter), ' Relative Change: ', num2str(diffNorm)]);
        if diffNorm < tolerance
            disp('Convergence achieved.');
            break;
        end
    end

    % Compute coefficient images based on truncated rank
    coefficientImages = reshape(kspaceReshaped(:, 1:rank), Nx, Ny, rank);
end

