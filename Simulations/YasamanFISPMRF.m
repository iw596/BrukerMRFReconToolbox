function Msig=YasamanFISPMRF(FA,T1,T2,TE,TR,df,Nex,Tdelay)

%This is the storage value for the population of 100 spins
Nf=1;
on = ones(1,Nf);
dephase = 2*pi;
phi = ([1:Nf]/Nf-0.5 ) * dephase;
Msig = zeros(1,Nex);

% M = [zeros(2,Nf);-1*ones(1,Nf)]; % initial inversion signal
E1a = exp(-(TE(1)/T1));
E2a = exp(-(TE(1)/T2));
E1b = exp(-((TR(1)-TE(1))/T1));
E2b = exp(-((TR(1)-TE(1))/T2));

M = [0,0,1]';
for m = 1:Nex   
    A1 = diag([E2a E2a E1a]) * (xrot(deg2rad(FA(m)*(-1)^(m))));
    B1 = [0;0;1-E1a];
    A2 = diag([E2b E2b E1b]);
    B2 = [0;0;1-E1b];
    M = A1*M + B1;
    Msig(m) = (complex(M(1), M(2)));
    M = A2*M + B2;
end



















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


