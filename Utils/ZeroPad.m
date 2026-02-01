%% This function zero pads the signal x such that it has the dimensions newSize. Where newSize is a 3x1 vector containing
%% the desired size of x
function res = ZeroPad(x,newSize)

    if numel(newSize) ~= 3
        error("newSize must be a 3-element vector [Nx Ny Nz]");
    end

    sx = size(x);

    % Make sure size(x) has at least 3 dims
    sx(end+1:3) = 1;

    % Check that x fits in requested size
    if any(sx(1:3) > newSize)
        error("newSize must be >= size(x) in the first three dimensions");
    end

    % Output size: padded first 3 dims, untouched higher dims
    outSize = [newSize, sx(4:end)];

    res = zeros(outSize, 'like', x);

    % Index only first three dims
    idx = cell(1, numel(outSize));
    idx{1} = 1:sx(1);
    idx{2} = 1:sx(2);
    idx{3} = 1:sx(3);

    % Copy everything in higher dimensions as-is
    for k = 4:numel(outSize)
        idx{k} = 1:sx(k);
    end

    res(idx{:}) = x;

end