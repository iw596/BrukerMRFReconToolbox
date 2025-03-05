function MNew = InstantRFExcitation(alpha,theta,M)
    for p = 1:size(M,2)
        M(:,p) = RotateTheta(alpha,theta) *M(:,p);
    end
    MNew = M;
end