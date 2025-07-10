function MNew = InstantRFExcitation(M,alpha,theta)
    % ca = cos(alpha);	% cosine of tip alpha
    % sa = sin(alpha);	% sine of tip
    % cp = cos(theta  ); % cosine of phi
    % sp = sin(theta  ); % sine of phi
    % R = [cp*cp+sp*sp*ca cp*sp*(1-ca) -sp*sa;
    %      cp*sp-sp*cp*ca sp*sp+cp*cp*ca cp*sa;
    %      sa*sp -sa*cp ca];
    R = RotateTheta(alpha,theta);
    MNew = R * M;
end

