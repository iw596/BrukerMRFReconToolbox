function  map = T2Fitting(imgs,TE,mask)

    if (nargin < 3)
        mask = ones(size(imgs(:,:,1)));
    end
    % Drop first echo
    %imgs = imgs(:,:,2:end);
    options.Algorithm = 'levenberg-marquardt';

   % TE = TE(2:end);
    for ii = 1:size(imgs,1)
        for jj = 1:size(imgs,2)
            if (mask(ii,jj) == 1)
                s = squeeze(imgs(ii,jj,:));
                yDat = abs(s);
                yDat = yDat./max(s);
                fT2 = @(a)(a(1)*exp(-TE/a(2)) + a(3)  - yDat);
                t2Init_dif = TE(1) - TE(end-1);
                t2Init = t2Init_dif/log(yDat(end-1)/yDat(1));
                
                if t2Init<=0 || isnan(t2Init),
                    t2Init=30;
                end
                pdInit = max(yDat(:))*1.5;

      
                [C] = lsqnonlin(fT2,[pdInit t2Init 0],[],[],options);
                map(ii,jj) = C(2);
            else
                map(ii,jj) = 0.0;
            end
        end
    end
end

