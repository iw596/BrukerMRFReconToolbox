%% Functionn to calculate the normalized root-mean squared error betwwen observed value
%% x and measured value y. We assume x and y are the same dimensions

function error = NRMSE(x,y)
    % Vectorise inputs
    x = x(:);
    y = y(:);
    
    T = length(y);
    ymin = min(y);
    ymax = max(y);

    RMSD = 
        
end