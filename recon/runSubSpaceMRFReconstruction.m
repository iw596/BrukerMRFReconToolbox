%% This function performs MRF sub-space reconstruction using the ADMM algorithm
%% The
function results = runSubSpaceMRFReconstruction(data,dict,options)


% Compress the dictionary
[~, S ,V] = svd(dict.', 'econ');
svals = diag(S)/S(1);
svals = cumsum(svals.^2./sum(svals.^2));
NPCs  = find(svals > 0.9999, 1, 'first');
dict_phi       = single(V(:,1:NPCs));
dict_svd       = (dict.'*dict_phi).';
dict_comp.phi  = dict_phi;
dict_comp.svd  = dict_svd;
dict_comp.NPCs = NPCs;
clear S V svals;
% Determine if we are handling 2D or 3D data

% Build regularizers

% Run ADMM reconstruction



end