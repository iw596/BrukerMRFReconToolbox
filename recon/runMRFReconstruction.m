function result = runMRFReconstruction(MRFParams,settings)
% runMRFReconstruction  Skeleton entry point for 2D/3D MRF reconstruction.
%
%   This function wires the reconstruction pipeline together:
%   - build a reconstruction context
%   - build the geometry abstraction (2D or 3D)
%   - build the selected regularizer
%   - run the ADMM skeleton solver
%
%   The implementation is intentionally modular so new data models and
%   regularizers can be added without changing the GUI.

context = buildMRFReconContext(settings);
geometry = buildMRFReconGeometry(context);
regularizer = buildMRFReconRegularizer(context);

disp("Preparing MRF data for reconstruction....")
data = prepareMRFData(MRFParams);

disp("Starting reconstruction...")


if strcmp(settings.MRFReconMode, 'Direct')
    %% Direct recon pathway
    disp("Direct reconstruction of MRF data pathway")
    result = runDirectMRFReconstruction(data,context, geometry);
else
    %% Sub-space recon pathway
    result = runADMMReconstruction(context, geometry, regularizer);
end
if isempty(result) || ~isstruct(result)
    result = struct();
end
if ~isfield(result, 'Status') || isempty(result.Status)
    result.Status = 'Completed';
end
if ~isfield(result, 'Log') || isempty(result.Log)
    result.Log = {'Reconstruction completed.'};
end
disp("Reconstruction finished...")


%% Perform dictionary matching
disp("Starting dictionary matching....")


disp("Dictionary matching finished...")


end
