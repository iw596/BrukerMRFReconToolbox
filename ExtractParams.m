% This function takes the twix structure and extracts some useful
% header information. All of this information is already present in Siemens
% twix but is scattered everywhere....
function params = ExtractParams(twix)
    params.System = "Siemens";
    params.NCol = twix.image.NCol;
    if (twix.image.flagRemoveOS== true)
        params.NCol = params.NCol/2;
    end
    params.NLin = twix.image.NLin;
    params.NRep = twix.image.NRep;
    params.NSli = twix.image.NSli;
    params.NCha = twix.image.NCha;
    params.NSeg = twix.image.NSeg;
    if (twix.hdr.MeasYaps.sKSpace.ucTrajectory ==2)
        params.Traj = "Radial";
    else
        params.Traj = "Cartesian";
    end 
    if (isfield(twix.hdr.MeasYaps,"sWipMemBlock"))
        % Extract WIP parameters, in my use case these are being used to
        % control radial angle mode and Multiband parameters
        params.WIPParameters = (twix.hdr.MeasYaps.sWipMemBlock.alFree);
    end
    % If reference data is present then extract it as well
    if (isfield(twix,"refscan"))
        params.isRefScanPresent = 1;
        params.RefNCol = twix.refscan.NCol;
        params.RefNLin = twix.refscan.NLin;
        params.RefNSli = twix.refscan.NSli;
        params.RefNCha = twix.refscan.NCha;
    else
        params.isRefScanPresent = 0;
    end
end