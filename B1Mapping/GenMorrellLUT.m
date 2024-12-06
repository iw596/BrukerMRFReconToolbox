%% Function to generate look-up table for Morrell B1 mapping

function LUT = GenMorrellLUT(alpha, omega)
    [alphaMesh omegaMesh] = meshgrid(alpha,omega);

    beta = sqrt(alphaMesh.^2 + omegaMesh.^2) + eps;

    MxPlus = ((alphaMesh.*omegaMesh)./beta.^2).*(4.*sin(beta).^2 .*cos(beta));
    MxPlus = MxPlus - ((alphaMesh.*sin(beta))./beta.^3).*(alphaMesh.^2.*cos(2.*beta) + omegaMesh.^2);
    
    MyPlus = ((2.*alphaMesh.*sin(beta))./beta.^3).*(omegaMesh.^2.*cos(2.*beta) + alpha.^2.*cos(beta));
    MyPlus = MyPlus + ((alphaMesh.*omegaMesh)./beta.^4).*(1-cos(beta)).*(alphaMesh.^2.*cos(2.*beta) + omegaMesh.^2);

    MxNeg = -1* ((alphaMesh.*omegaMesh)./beta.^2).*(4.*sin(beta).^2 .*cos(beta));
    MxNeg = MxNeg - ((alphaMesh.*sin(beta))./beta.^3).*(alphaMesh.^2.*cos(2.*beta) + omegaMesh.^2);

    MyNeg =  -1 .* ((2.*alphaMesh.*sin(beta))./beta.^3).*(omegaMesh.^2.*cos(2.*beta) + alpha.^2.*cos(beta));
    MyNeg = MyNeg +  ((alphaMesh.*omegaMesh)./beta.^4).*(1-cos(beta)).*(alphaMesh.^2.*cos(2.*beta) + omegaMesh.^2);

    
    MxyPos = MxPlus + 1i.*MyPlus;
    MxyNeg = MxNeg + 1i.*MyNeg;
    phaseDiff = angle(MxyNeg) - angle(MxyPos);
    LUT  = [alphaMesh(:),omegaMesh(:),phaseDiff(:)];
    figure(5);
    plot((phaseDiff))
    %phaseDiff = atan2(imag(MxyPos./MxyNeg),real(MxyPos./MxyNeg));
 %   figure(5);
%    surf(rad2deg(alphaMesh),rad2deg(omegaMesh),phaseDiff);
  %  ylabel("Off Resonance Angle");
  %  xlabel("Flip Angle");
    

end