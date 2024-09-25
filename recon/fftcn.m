function res = fftcn(x,dims)
    for i = dims
          x = fftshift(fft(ifftshift(x,i),[],i),i)*sqrt(size(x,i));
    end
    res = x;
end