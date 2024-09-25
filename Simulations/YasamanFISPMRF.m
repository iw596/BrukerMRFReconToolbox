function Msig=YasamanFISPMRF(flipAngles,T1,T2,TE,TR,df,Nex,Tdelay)

%This is the storage value for the population of 100 spins
Nf=200;
on = ones(1,Nf);
dephase = 2*pi;
phi = ([1:Nf]/Nf-0.5 ) * dephase;

% M = [zeros(2,Nf);-1*ones(1,Nf)]; % initial inversion signal

%Precess the spins over time delay before imaging
% [Atd,Btd] = freeprecess(Tdelay,T1,T2,df);
% M = Atd*M+Btd*on;
% for m = 1:Nex
%     
%     %Get the flip and precession matrices
%     Rflip = yrot(flipAngles(m)*((-1)^m));
%     [Atr,Btr] = freeprecess(TR(m)-TE(m),T1,T2,df);
%     [Ate,Bte] = freeprecess(TE(m),T1,T2,df);
% 
%     %Flip and precess until the echo time
%     A = Ate*Rflip;
%     B = Bte;
%     
%     %Get the magnetization
%     M = A*M+B*on;
%         
%     %Precess through the rest of the imaging experiment
% 	M=Atr*M+Btr*on;
%     
%     for k=1:Nf
%         M(:,k) = zrot(phi(k))*M(:,k);
%     end
%     
% end;
Msig = zeros(1,Nex);

%[Atd,Btd] = freeprecess(9000,T1,T2,df);
%M = Atd*M+Btd*on;

M = [zeros(3,Nf)]; % initial inversion signal
M(3,:) = -1;
%Precess the spins over time delay before imaging
[Atd,Btd] = freeprecess(Tdelay,T1,T2,df);
M = Atd*M+Btd*on;
for m = 1:Nex
    
    %Get the flip and precession matrices
    Rflip = yrot(deg2rad(flipAngles(m))*((-1)^m));
    [Atr,Btr] = freeprecess(TR(m)-TE(m),T1,T2,df);
    [Ate,Bte] = freeprecess(TE(m),T1,T2,df);

    %Flip and precess until the echo time
    A = Ate*Rflip;
    B = Bte;
    
    %Get the magnetization
    M = A*M+B*on;
    
    Msig(m) = mean(squeeze(M(1,:)+1i*M(2,:)))*((-1)^m);
    
    %Precess through the rest of the imaging experiment
	M=Atr*M+Btr*on;
    
    for k=1:Nf
        M(:,k) = zrot(phi(k))*M(:,k);
    end  
end;