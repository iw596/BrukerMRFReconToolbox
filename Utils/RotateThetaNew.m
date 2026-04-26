function R = RotateThetaNew(alpha,theta)
    R = zeros([3,3]);

    sin_alpha = sin(alpha);
    cos_alpha = cos(alpha);
    sin_theta = sin(theta);
    cos_theta = cos(theta);

    R(1,1) = cos_theta.^2 + cos_alpha*sin_theta^2;
    R(2,1) = (cos_alpha-1)*cos_theta*sin_theta;
    R(3,1) = sin_alpha * cos_theta;

    R(1,2) = (cos_alpha-1)*cos_theta*sin_theta;
    R(2,2) = sin_theta^2 + cos_alpha * cos_theta^2;
    R(3,2) = sin_alpha*cos_theta;

    R(1,3) = -sin_alpha * sin_theta;
    R(2,3) = -sin_alpha*cos_theta;
    R(3,3) = cos_alpha;
end