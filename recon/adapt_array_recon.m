function recon = adapt_array_recon(imgs,psi)
    
    [nx,ny,nz,nc] = size(imgs);

    % Block-sizes for x,y and z
    bs1 = 1;
    bs2 = 1;
    bs3 = 1;
    st=1;   %increase to set interpolation step size
    % Find coil with max intensity (for phase correction)
    [mm,maxcoil]=max(sum(sum(sum(abs(imgs)))));   
    % Pemute imgs into coil-x-y-z order
    imgs = permute(imgs,[4 1 2 3]);

    % Matrices to store low res imgs
    wsmall=zeros(nc,round(nx./st),ny./st,nz./st);
    cmapsmall=zeros(nc,round(nx./st),ny./st,nz./st);

    for x = st:st:nx
        for y = st:st:ny
            for z = st:st:nz
                %Collect block for calculation of blockwise values
                ymin1=max([y-bs1./2 1]);                   
                xmin1=max([x-bs2./2 1]);
                zmin1 = max([z-bs3./2 1]);
                % Cropping edges
                ymax1=min([y+bs1./2 ny]);                 
                xmax1=min([x+bs2./2 nx]);                  
                zmax1=min([z+bs3./2 nz]);  

                ly1=length(ymin1:ymax1);
                lx1=length(xmin1:xmax1);
                lz1=length(zmin1:zmax1);

                m1=reshape(imgs(:,xmin1:xmax1,ymin1:ymax1,zmin1:zmax1),nc,lx1*ly1*lz1);
                m=m1*m1'; %signal covariance
                % eignevector with max eigenvalue for optimal combination
                [e,v]=eig(inv(psi)*m);  

                v=diag(v);
                [mv,ind]=max(v);

                mf=e(:,ind);
                mf=mf/(mf'*inv(psi)*mf);
                normmf=e(:,ind);

                % Phase correction based on coil with max intensity
                mf=mf.*exp(-j*angle(mf(maxcoil)));
                normmf=normmf.*exp(-j*angle(normmf(maxcoil)));

                wsmall(:,x./st,y./st,z./st)=mf;
                cmapsmall(:,x./st,y./st,z./st)=normmf;
            end
        end
    end
    recon=zeros(nx,ny,nz);
    recon=squeeze(sum(wsmall.*imgs));   %Combine coil signals. 
end