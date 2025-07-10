function R = RotateTheta(alpha,theta)
    % R = zeros([3,3]);
    % 
    % sin_alpha = sin(alpha);
    % cos_alpha = cos(alpha);
    % sin_theta = sin(theta);
    % cos_theta = cos(theta);
    % 
    % R(1,1) = sin_theta.^2 + cos_alpha*cos_theta^2;
    % R(2,1) = sin_theta * cos_theta - cos_alpha * sin_theta * cos_theta;
    % R(3,1) = -sin_alpha * cos_theta;
    % 
    % R(1,2) = sin_theta * cos_theta - cos_alpha * sin_theta * cos_theta;
    % R(2,2) = cos_theta^2 + cos_alpha * sin_theta^2;
    % R(3,2) = sin_alpha*sin_theta;
    % 
    % R(1,3) = sin_alpha * cos_theta;
    % R(2,3) = -sin_alpha*sin_theta;
    % R(3,3) = cos_alpha;


    % Rotation axis u in x-y plane
    u = [cos(theta); sin(theta); 0];

    % Rodrigues' rotation formula: R = I*cos(alpha) + sin(alpha)*K + (1-cos(alpha))*u*u'
    K = [  0     -u(3)   u(2);
          u(3)   0     -u(1);
         -u(2)  u(1)    0 ];

    I = eye(3);

    R = I * cos(alpha) + sin(alpha) * K + (1 - cos(alpha)) * (u * u');
end