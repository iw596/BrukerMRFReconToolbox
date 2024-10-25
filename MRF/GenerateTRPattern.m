function noise = GenerateTRPattern(length, persistence, octaves,TRMin,TRMax)
    % Generate 1D Perlin noise
    % length: number of points in the noise
    % persistence: controls the amplitude of each octave
    % octaves: number of layers of noise

    % Preallocate the noise array
    noise = zeros(1, length);
    
    % Generate random gradient vectors
    grad = rand(1, length) * 2 - 1; % Random gradients in range [-1, 1]

    maxAmplitude = 0;
    amplitude = 1;
    frequency = 1;

    % Loop through octaves
    for o = 1:octaves
        freq = frequency;

        % Loop through each sample point
        for x = 1:length
            % Find the grid points
            x0 = floor((x - 1) / freq);
            x1 = mod(x0 + 1, length);

            % Calculate the interpolation weight
            t = (x - 1) / freq - x0;
            t = fade(t); % Fade function for smooth interpolation

            % Dot products
            n0 = grad(mod(x0, length) + 1) * ((x - 1) - x0 * freq);
            n1 = grad(mod(x1, length) + 1) * ((x - 1) - x1 * freq);

            % Interpolate between the two
            noise(x) = noise(x) + lerp(n0, n1, t) * amplitude;
        end

        maxAmplitude = maxAmplitude + amplitude;
        amplitude = amplitude * persistence;
        frequency = frequency * 2;
    end

    % Normalize the noise
    noise = noise / maxAmplitude;
    noise = mapToRange(noise, TRMin, TRMax); % Perform mapping outside

end

function y = fade(t)
    % Fade function for smooth interpolation
    y = t^3 * (t * (t * 6 - 15) + 10);
end

function y = lerp(a, b, t)
    % Linear interpolation
    y = a + t * (b - a);
end

