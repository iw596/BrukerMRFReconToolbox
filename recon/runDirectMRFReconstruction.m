
%% This function performs direct reconstruction of MRF k-space data (stored in variable data). The results struct contains image data and the reconstruction time
function results = runDirectMRFReconstruction(data,context, geometry)
    tic
    images = ifftcn(data,[1 2 3]);
    reconTime = toc;

    results.images = images;
    results.reconTime = reconTime;
end