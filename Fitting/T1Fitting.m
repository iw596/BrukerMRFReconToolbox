%% Function to fit T1 to (magnitude) images acquired at a variety inversion time TI
function map = T1Fitting(imgs,TI,mask)
    if (nargin < 3)
        mask = ones(size(imgs));
    end

    map = size([imgs]);
    options.Algorithm = 'levenberg-marquardt';
    for ii = 1:size(imgs,1)
        for jj = 1:size(imgs,2)
            if (mask(ii,jj) == 1)
                s = squeeze(imgs(ii,jj,:));
                % First we need to find the minimum point to perform polarity inversion
                [~,idx] = min(s);
                s(1:idx) = -1*s(1:idx);
                % Fit
                fitFunc = @(x)((x(1).*(1 - 2 * exp(-1 * TI./x(2)))) - s);

                [C] = lsqnonlin(fitFunc,[1,500],[],[],options);
                map(ii,jj) = C(2);
            else
                map(ii,jj) = 0.0;
            end
        end
    end
    
    
end
