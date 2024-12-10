% Function to implement double angle B1 mapping, it takes two argumnets
% img1 at flip angle a and img2 acquired with flip angle 2a
function B1 = DAMB1(img1,img2)
    S = (img2./(2.*img1));
    theta = acosd(S);
    B1 = abs(theta);

end