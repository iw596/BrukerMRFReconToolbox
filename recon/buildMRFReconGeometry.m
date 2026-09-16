function geometry = buildMRFReconGeometry(context)
%buildMRFReconGeometry Describe the spatial dimensionality of the input.
%
% LLR owns block extraction. Geometry is deliberately only metadata here;
% keeping empty block and reshape callbacks created the impression that the
% solver was using an abstraction that it did not actually call.

dimensionality = lower(string(context.Dimensionality));
if ~any(dimensionality == ["2d", "3d"])
    error('buildMRFReconGeometry:InvalidDimensionality', ...
        'Dimensionality must be ''2D'' or ''3D''.');
end

geometry = struct();
geometry.Dimensionality = dimensionality;
geometry.Is2D = dimensionality == "2d";
geometry.Is3D = dimensionality == "3d";
geometry.DataSize = context.DataSize;
geometry.Description = sprintf('%s spatial MRF reconstruction', upper(char(dimensionality)));
end
