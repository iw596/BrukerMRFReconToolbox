%% Functionn to calculate the normalized mean squared error (NMSE) betwwen observed value
%% x and measured value y. We assume x and y are the same dimensions

function error = NMSE(x,y)
    % Vectorise inputs
    x = x(:);
    y = y(:);
    
    T = length(y);
    ymin = min(y);
    ymax = max(y);

    RMSD = 
        
end