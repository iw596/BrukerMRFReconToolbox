function  map = T2Fitting(imgs,TE,mask)
    % Drop first echo
    imgs = imgs(:,:,2:end);
    options.Algorithm = 'levenberg-marquardt';

    TE = TE(2:end);
    for ii = 1:size(imgs,1)
        for jj = 1:size(imgs,2)
            if (mask(ii,jj) == 1)
                s = squeeze(imgs(ii,jj,:));
                fitFunc = @(x)((x(1).* exp(-TE./x(2))) - s);

                [C] = lsqnonlin(fitFunc,[1,50],[],[],options);
                map(ii,jj) = C(2);
            else
                map(ii,jj) = 0.0;
            end
        end
    end
end

