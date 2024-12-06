function B1Map = FitAFIB1(imgs,flip,TR1,TR2)

B1Map = zeros([size(imgs,[1 2 3])]);

S1 = imgs(:,:,:,1);
S2 = imgs(:,:,:,2);
n = TR2/TR1;

r  = abs(S2./S1);
% Filter out where r > 1 (I am assuming this is just noise)
tmp  = (r*n - 1)./(n-r);
tmp = double(tmp).*(r<=1) + ones(size(r)).*(r>1);
B1Map = acos(tmp); % B1Map is in radians
B1Map = B1Map*180/pi;
B1Map = B1Map/flip;

% Smooth image with median filter kernel
%B1Map = medfilt3(B1Map,[3, 3, 1]);

end

