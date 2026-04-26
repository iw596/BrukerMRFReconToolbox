function MNew = BlochSim(M,T1,T2,B1,Gz,pos,dt)

B1real = real(B1);
b1imag = imag(B1)
gamma = 2*pi*42.57e6;
for t = 2:length(B1)
    Uz = (Zgrid * self.rf_pulse.GZ(t-1) + Bgrid*self.B0) * self.rf_pulse.gamma;
    Ux = gamma * B1real(t-1);
    Uy = gamma * B1imag(t-1);

end

end