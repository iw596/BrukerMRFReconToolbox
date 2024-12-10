% Function to implement double angle B1 mapping, it takes two argumnets
% img1 at flip angle a and img2 acquired with flip angle 2a
function b1_map = DAMB1(img1,img2,theta)
    S = abs(img1./img2);
    theta_measured = acos(0.5 * 1./S);
    b1_map = theta_measured./(pi * theta/180);
    

end