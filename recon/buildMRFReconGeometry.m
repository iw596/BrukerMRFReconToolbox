function geometry = buildMRFReconGeometry(context)
% buildMRFReconGeometry  Create a geometry skeleton for 2D or 3D recon.
%
%   The geometry object is represented as a struct so the solver can remain
%   functional and easy to extend.

geometry = struct();
geometry.Dimensionality = context.Dimensionality;
geometry.Is3D = strcmpi(context.Dimensionality, '3d');
geometry.Is2D = strcmpi(context.Dimensionality, '2d');
geometry.DataSize = context.DataSize;
geometry.Description = '';

if geometry.Is3D
    geometry.Description = '3D volume geometry';
    geometry.ExtractBlocks = @extractBlocks3D; %#ok<NASGU>
    geometry.Reshape = @reshapeVolume3D; %#ok<NASGU>
else
    geometry.Description = '2D slice geometry';
    geometry.ExtractBlocks = @extractBlocks2D; %#ok<NASGU>
    geometry.Reshape = @reshapeImage2D; %#ok<NASGU>
end
end

function blocks = extractBlocks2D(x, blockSize, stride)
% Skeleton block extractor for 2D images.
blocks = struct('Data', x, 'BlockSize', blockSize, 'Stride', stride);
end

function blocks = extractBlocks3D(x, blockSize, stride)
% Skeleton block extractor for 3D volumes.
blocks = struct('Data', x, 'BlockSize', blockSize, 'Stride', stride);
end

function x = reshapeImage2D(x)
% Placeholder reshape helper for 2D.
end

function x = reshapeVolume3D(x)
% Placeholder reshape helper for 3D.
end
