% Function to implement double angle B1 mapping, it takes two argumnets
% img1 at flip angle a and img2 acquired with flip angle 2a
function B1 = DAMB1(img1,img2)
    S = abs(img2)./abs(2.*img1);
    theta = acos(S);
    B1 = medfilt3(abs(theta),[5,5,1]);

end