function sampling_masks = generate_poisson_masks(kspace_size, num_timepoints, acceleration_factor, central_fraction)
    

    [Nx, Ny] = deal(kspace_size(1), kspace_size(2));
    sampling_masks = zeros(Nx, Ny, num_timepoints);

    % Central fully sampled region
    center_radius_x = round(central_fraction * Nx / 2);
    center_radius_y = round(central_fraction * Ny / 2);

    for t = 1:num_timepoints
        % Generate a sparse random mask
        mask = poisson_disk_sampling(Nx, Ny, acceleration_factor);

        % Add fully sampled central region
        center_mask = zeros(Nx, Ny);
        center_mask(Nx/2-center_radius_x+1:Nx/2+center_radius_x, ...
                    Ny/2-center_radius_y+1:Ny/2+center_radius_y) = 1;

        % Combine sparse mask with central region
        sampling_masks(:, :, t) = max(mask, center_mask);
    end
end

function mask = poisson_disk_sampling(Nx, Ny, acceleration_factor)
    % Create a binary Poisson Disk Sampling mask
    density = 1 / acceleration_factor; % Sparsity level
    num_points = round(density * Nx * Ny); % Total points to sample
    mask = zeros(Nx, Ny);

    % Generate random points
    coords = randperm(Nx * Ny, num_points);
    mask(coords) = 1;
end
