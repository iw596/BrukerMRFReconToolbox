function res = ifftcn(x,dims)
    for i = dims
          x = fftshift(ifft(ifftshift(x,i),[],i),i)/sqrt(size(x,i));
    end
    res = x;
end