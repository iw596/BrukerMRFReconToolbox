addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")


%% Open bruker MRF dataset
%pth = "datasets\MRF_ISMRM_Dataset\17";
pth = "datasets\MRFSpoilingTests\20";
params = LoadBrukerData(pth);



%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
%[FA,TR] = ReadMRFList("datasets\MRFPattern.txt");
[FA,~] = ReadMRFList("datasets\MRFSpoilingTests\MRFPattern.txt");
rawdata = reshape(rawdata, [params.NCol length(FA)*6 params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
imgs = ifftcn(rawdata,[1 2]);
%imgs = fftshift(fft2((rawdata)));
figure; imagesc(abs(mean(imgs,3)));



%% Create binary mask from mean of images
se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)));


% Normalise Dictionary
normalisedDict = [];

cnt=size(dict,2);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(:,c).*conj(dict(:,c))));
    normalisedDict(:,c) = dict(:,c) / scaleFactor;
    %normalisedDict(c,:) =  dict(c,:)./norm(squeeze( dict(c,:)));
end

% Iterate through each voxel
for i = 1:params.NCol
    i
    for j = 1:params.NLin
       scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
       normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
       inner_product=abs((squeeze(normalized_mrfsignal))'*(normalisedDict));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       T1Map(i,j) = LUT(max_index,1);
       T2Map(i,j) = LUT(max_index,2);
       MRFMask(i,j) = 1;
       dotProductMaximums(i,j) = maxValue;

    end
end




%% Resize results and mask to same size as 
maskResized = imresize(mask,[128 128]);
T1MapResized = imresize(T1Map,[128 128]);
T2MapResized = imresize(T2Map,[128 128]);

%% Load T1 FAIR RARE
pth = "datasets\MRFSpoilingTests\64";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[params.NCol params.NLin params.NInv]);
fclose(fid);
T1RefMap = T1Fitting(data,params.InvTimes);
T1RefMask = imbinarize(mat2gray(mean(data(:,:,1:end),3)),0.1);

%% Load T2 MSME
pth = "datasets\MRFSpoilingTests\66";
params = LoadBrukerData(pth);
fid = fopen(pth + '\pdata\1\2dseq');
data = fread(fid,"int16");
data = reshape(data,[128 params.NLin params.NEcho]);
fclose(fid);
T2RefMap = T2Fitting(data,params.MSMETimes);
T2RefMap(abs(T2RefMap) > 5000) = 0; 
T2RefMask = imbinarize(mat2gray(data(:,:,1)),0.02);
figure; imshow(T2RefMask)


figure(1);
subplot(1,2,1); imagesc(1000*T1MapResized.*maskResized,[0,400]); colormap("turbo"); title("MRF T1 Map"); colorbar;
axis square;
subplot(1,2,2); imagesc(T1RefMap.*T1RefMask,[0,400]); colormap("turbo");  title("Reference T1 Map"); colorbar;
axis square;

figure(2);
subplot(1,2,1); imagesc(1000*T2MapResized.*maskResized,[0,200]);colormap("turbo"); title("MRF T2 Map"); colorbar;
axis square;
subplot(1,2,2); imagesc(T2RefMap.*T1RefMask,[0,200]); colormap("turbo");title("Reference T2 Map"); colorbar;
axis square;



mrfROI1X = [107:120];
mrfROI1Y = [50:65];
refROI1X = [101:112];
refROI1Y = [55:65];
T1RefROI1 = mean(T1RefMap(refROI1X,refROI1Y),'all');
T1MRFROI1 = mean(T1MapResized(mrfROI1X,mrfROI1Y),'all')* 1000;
T1MRFROI1Std = std(T1MapResized(mrfROI1X,mrfROI1Y),1,[1 2],'omitmissing')* 1000;
T2RefROI1 = mean(T2RefMap(refROI1X,refROI1Y),'all');
T2MRFROI1 = mean(T2MapResized(mrfROI1X,mrfROI1Y),'all')* 1000;


mrfROI2X = [101:111];
mrfROI2Y = [92:103];
refROI2X = [95:104];
refROI2Y = [90:100];
T1RefROI2 = mean(T1RefMap(refROI2X,refROI2Y),'all');
T1MRFROI2 = mean(T1MapResized(mrfROI2X,mrfROI2Y),'all')* 1000;
T2RefROI2 = mean(T2RefMap(refROI2X,refROI2Y),'all');
T2MRFROI2 = mean(T2MapResized(mrfROI2X,mrfROI2Y),'all')* 1000;


mrfROI3X = [67:78];
mrfROI3Y = [109:120];
refROI3X = [67:77];
refROI3Y = [102:112];
T1RefROI3 = mean(T1RefMap(refROI3X,refROI3Y),'all');
T1MRFROI3 = mean(T1MapResized(mrfROI3X,mrfROI3Y),'all')* 1000;
T2RefROI3 = mean(T2RefMap(refROI3X,refROI3Y),'all');
T2MRFROI3 = mean(T2MapResized(mrfROI3X,mrfROI3Y),'all')* 1000;


mrfROI4X = [33:43];
mrfROI4Y = [101:111];
refROI4X = [36:46];
refROI4Y = [95:105];
T1RefROI4 = mean(T1RefMap(refROI4X,refROI4Y),'all');
T1MRFROI4 = mean(T1MapResized(mrfROI4X,mrfROI4Y),'all') * 1000;
T2RefROI4 = mean(T2RefMap(refROI4X,refROI4Y),'all');
T2MRFROI4 = mean(T2MapResized(mrfROI4X,mrfROI4Y),'all') * 1000;

mrfROI5X = [13:23];
mrfROI5Y = [70:80];
refROI5X = [18:27];
refROI5Y = [67:80];
T1RefROI5 = mean(T1RefMap(refROI5X,refROI5Y),'all');
T1MRFROI5 = mean(T1MapResized(mrfROI5X,mrfROI5Y),'all')* 1000;
T2RefROI5 = mean(T2RefMap(refROI5X,refROI5Y),'all');
T2MRFROI5 = mean(T2MapResized(mrfROI5X,mrfROI5Y),'all')* 1000;

mrfROI6X = [18:28];
mrfROI6Y = [32:42];
refROI6X = [24:34];
refROI6Y = [35:45];
T1RefROI6 = mean(T1RefMap(refROI6X,refROI6Y),'all');
T1MRFROI6 = mean(T1MapResized(mrfROI6X,mrfROI6Y),'all')* 1000;
T2RefROI6 = mean(T2RefMap(refROI6X,refROI6Y),'all');
T2MRFROI6 = mean(T2MapResized(mrfROI6X,mrfROI6Y),'all')* 1000;


figure(3);
T1BarY = [T1MRFROI1 T1RefROI1; T1MRFROI2 T1RefROI2;T1MRFROI3 T1RefROI3;T1MRFROI4 T1RefROI4;T1MRFROI5 T1RefROI5;T1MRFROI6 T1RefROI6];
bar(T1BarY)
xlabel("Sample Number", "FontSize",25,"FontName","Times New Roman");
ylabel("T1(ms)", "FontSize",25,"FontName","Times New Roman")
legend("MRF","Ground Truth","FontSize",25,"FontName","Times New Roman");


figure(4);
T2BarY = [T2MRFROI1 T2RefROI1; T2MRFROI2 T2RefROI2;T2MRFROI3 T2RefROI3;T2MRFROI4 T2RefROI4;T2MRFROI5 T2RefROI5;T2MRFROI6 T2RefROI6];
bar(T2BarY)
xlabel("Sample Number", "FontSize",25,"FontName","Times New Roman");
ylabel("T2(ms)", "FontSize",25,"FontName","Times New Roman")
legend("MRF","Ground Truth","FontSize",25,"FontName","Times New Roman");


refT1Data = [T1RefROI1,T1RefROI2,T1RefROI3,T1RefROI4,T1RefROI5,T1RefROI6];
mrfT1Data = [T1MRFROI1,T1MRFROI2,T1MRFROI3,T1MRFROI4,T1MRFROI5,T1MRFROI6];
b1 = refT1Data'\mrfT1Data';
yCalc1 = b1*refT1Data;
figure(5);
scatter(refT1Data,mrfT1Data);
xlabel("Ground Truth T1(ms)", "FontSize",25,"FontName","Times New Roman")
ylabel("MRF T1(ms)", "FontSize",25,"FontName","Times New Roman")
hold on
plot(refT1Data,yCalc1)