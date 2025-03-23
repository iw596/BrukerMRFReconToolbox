res = load("Results\Matlab_InstantRF_B1Est.mat");

T1MRF = res.T1Map*1000;
T1Ref = res.T1FitResults.T1;

T2MRF = res.T2Map*1000;
T2Ref = res.T2FitResults.T2;



figure(3); 
subplot(2,2,1); imagesc(T1MRF,[0,2500]); colormap("turbo"); colorbar; title("MRF T1 Map"); axis square;
subplot(2,2,2); imagesc(T1Ref,[0,2500]); colormap("turbo"); colorbar; title("Ref T1 Map");  axis square;
subplot(2,2,3);imagesc(T2MRF,[0,500]); colormap("turbo"); colorbar; title("MRF T2 Map"); axis square;
subplot(2,2,4);imagesc(T2Ref,[0,500]); colormap("turbo"); colorbar; title("Ref T2 Map"); axis image;



T1_MRF_S1 = mean(T1MRF(19:32,24:32),'all');
T1_Ref_S1 = mean(T1Ref(21:30,48:61),'all')

T1_MRF_S2 = mean(T1MRF(24:34,39:48),'all')
T1_Ref_S2 = mean(T1Ref(24:34,78:91),'all')

T1_MRF_S3 = mean(T1MRF(45:52,49:55),'all')
T1_Ref_S3 = mean(T1Ref(45:52,98:108),'all')

T1_MRF_S4 = mean(T1MRF(76:87,50:55),'all')
T1_Ref_S4 = mean(T1Ref(76:87,100:110),'all')

T1_MRF_S5 = mean(T1MRF(63:73,36:42),'all')
T1_Ref_S5 = mean(T1Ref(63:73,72:84),'all')

T1_MRF_S6 = mean(T1MRF(63:73,36:42),'all')
T1_Ref_S6 = mean(T1Ref(63:73,72:84),'all')

T1_MRF_S6 = mean(T1MRF(96:106,39:43),'all')
T1_Ref_S6 = mean(T1Ref(96:106,78:86),'all')

T1_MRF_S7 = mean(T1MRF(72:79,13:19),'all')
T1_Ref_S7 = mean(T1Ref(72:79,26:38),'all')

T1_MRF_S8 = mean(T1MRF(94:100,23:28),'all')
T1_Ref_S8 = mean(T1Ref(94:100,46:56),'all')


T2_MRF_S1 = mean(T2MRF(19:32,24:32),'all');
T2_Ref_S1 = mean(T2Ref(21:30,48:61),'all')

T2_MRF_S2 = mean(T2MRF(24:34,39:48),'all')
T2_Ref_S2 = mean(T2Ref(24:34,78:91),'all')

T2_MRF_S3 = mean(T2MRF(45:52,49:55),'all')
T2_Ref_S3 = mean(T2Ref(45:52,98:108),'all')

tmp = T2Ref(76:87,100:110)
idx = find(tmp > 0); % Index of values greater than 0
T2_MRF_S4 = mean(T2MRF(76:87,50:55),'all')
T2_Ref_S4 = mean(tmp(idx),'all')

T2_MRF_S5 = mean(T2MRF(63:73,36:42),'all')
T2_Ref_S5 = mean(T2Ref(63:73,72:84),'all')

T2_MRF_S6 = mean(T2MRF(63:73,36:42),'all')
T2_Ref_S6 = mean(T2Ref(63:73,72:84),'all')

T2_MRF_S6 = mean(T2MRF(96:106,39:43),'all')
T2_Ref_S6 = mean(T2Ref(96:106,78:86),'all')

T2_MRF_S7 = mean(T2MRF(72:79,13:19),'all')
T2_Ref_S7 = mean(T2Ref(72:79,26:38),'all')

T2_MRF_S8 = mean(T2MRF(94:100,23:28),'all')
T2_Ref_S8 = mean(T2Ref(94:100,46:56),'all')



MRFT1MeanRes = [T1_MRF_S1,T1_MRF_S2,T1_MRF_S3,T1_MRF_S4,T1_MRF_S5,T1_MRF_S6,T1_MRF_S7,T1_MRF_S8];
RefT1MeanRes = [T1_Ref_S1,T1_Ref_S2,T1_Ref_S3,T1_Ref_S4,T1_Ref_S5,T1_Ref_S6,T1_Ref_S7,T1_Ref_S8];


MRFT2MeanRes = [T2_MRF_S1,T2_MRF_S2,T2_MRF_S3,T2_MRF_S4,T2_MRF_S5,T2_MRF_S6,T2_MRF_S7,T2_MRF_S8];
RefT2MeanRes = [T2_Ref_S1,T2_Ref_S2,T2_Ref_S3,T2_Ref_S4,T2_Ref_S5,T2_Ref_S6,T2_Ref_S7,T2_Ref_S8];



% Evaluate the fitted polynomial p and plot:
degree = 1;
p = polyfit(RefT2MeanRes,MRFT2MeanRes,degree);
f = polyval(p,RefT2MeanRes);
eqn = poly_equation(p); % polynomial equation (string)
Rsquared = my_Rsquared_coeff(MRFT2MeanRes,f); % correlation coefficient




figure(6);
plot(RefT2MeanRes,MRFT2MeanRes,'x',RefT2MeanRes,f,'--',LineWidth=2)
legend('data',eqn)
xlabel("T2 ground truth [ms]","Fontsize",20);
ylabel("T2 MRF [ms]","Fontsize",20)
axis = gca;
axis.FontSize = 20;
title(['Data fit - R squared = ' num2str(Rsquared)]);








% Fit a polynomial p of degree 1 to the data:
degree = 1;
p = polyfit(RefT1MeanRes,MRFT1MeanRes,degree);

% Evaluate the fitted polynomial p and plot:
f = polyval(p,RefT1MeanRes);
eqn = poly_equation(p); % polynomial equation (string)
Rsquared = my_Rsquared_coeff(MRFT1MeanRes,f); % correlation coefficient




figure(7);
% Add error bars for standard deviation
plot(RefT1MeanRes,MRFT1MeanRes,'x',RefT1MeanRes,f,'--',LineWidth=2)
legend('data',eqn,"Fontsize",20)
xlabel("T1 ground truth [ms]","Fontsize",20);
ylabel("T1 MRF [ms]","Fontsize",20)
axis = gca;
axis.FontSize = 12;
title(['Data fit - R squared = ' num2str(Rsquared)]);

figure(8);
bar([1:8],[MRFT1MeanRes;RefT1MeanRes]);
xlabel("Sample Number","FontSize",20);
ylabel("T1 [ms]","FontSize",20);
legend("MRF T1","Ref T1","FontSize",20);
axis = gca;
axis.FontSize = 20;
title("T1 Comparison")


figure(9);
bar([1:8],[MRFT2MeanRes;RefT2MeanRes]);
xlabel("Sample Number","FontSize",20);
ylabel("T2 [ms]","FontSize",20);
legend("MRF T2","Ref T2","FontSize",20);
axis = gca;
axis.FontSize = 20;
title("T2 Comparison")

