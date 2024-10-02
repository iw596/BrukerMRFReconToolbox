%% Quick script to test Yasaman data

addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")
%t1series = [50:10:2000,2020:20:3000,3050:50:5000];
%t2series = [6:5:100,110:10:200,202:2:500];

t1series = [600:50:3000];
t2series = [50:10:800];
t1l=length(t1series);
t2l=length(t2series);


% b) Create storage and counting variables
cnt = 0;
count = t1l*t2l;
r = [];


% c)  keeping only valid pairs
for it1 = 1:t1l
    for it2 = 1:t2l
        if (t1series(it1)>=t2series(it2))
            cnt=cnt+1;
            r(cnt,1)=t1series(it1);
            r(cnt,2)=t2series(it2);
        end
    end
end
T1 = r(:,1);
T2 = r(:,2);


%% Open bruker MRF dataset
%pth = "datasets\18";
%params = LoadBrukerData(pth);
%FAList = ReadFAList("datasets\FATest.txt");
fid = fopen("datasets\20240301_sphere_6ml_ddH2O_Exp2_ro64_32x32x4096.bin");
rawdata = fread(fid,['float64']);
rawdata = reshape(rawdata,[64,64,4096]);
fclose(fid);
figure(1); 
subplot(2,1,1);imagesc(mat2gray(abs(rawdata(:,:,1)))); axis square;
subplot(2,1,2);plot(squeeze(rawdata(32,32,:)))


%% Set-up sequence parameters
seqParams.TI = 100; % ms
seqParams.TR = 3;  %ms
seqParams.TE = 1.5;   %ms
%seqParams.FA = GenerateFAPattern(5.0,45.0,100);

seqParams.FA = ReadFAList("datasets/20240301_sphere_6ml_ddH2O_Exp2_flipangle_list.txt");

TE = ones([size(seqParams.FA)]);
TE(:) = seqParams.TE;

TR = ones([size(seqParams.FA)]);
TR(:) = seqParams.TR;
% d) put into the main simulated signal  
tic
dict = [];
for ii = 1:size(T1,1)
    tissueParams.T1 = T1(ii);
    tissueParams.T2 = T2(ii);
  %  Msignal = FISPSimulation(seqParams,tissueParams,250);
    Msignal = YasamanFISPMRF(seqParams.FA,T1(ii),T2(ii),TE,TR,0,length(seqParams.FA),seqParams.TI);
    
    MMsignal= Msignal;
    dict(ii,:)= MMsignal;

end
toc
%     save
dict= single(dict);


% Normalise Dictionary
normalisedDict = [];
cnt=size(dict,1);
for c = 1:cnt  
    scaleFactor = sqrt(sum(dict(c,:).*conj(dict(c,:))));
    normalisedDict(c,:) = dict(c,:) / scaleFactor;
end
T1Map = [];
T2Map  = [];
% Iterate through each voxel
for i = 32:32
    for j = 32:32
       % for k = 1:size(mrfsignal, 3)
       scaleFactor = sqrt(sum(rawdata(i,j,:).*conj(rawdata(i,j,:))));
       normalized_mrfsignal = conj(rawdata(i,j,:))/scaleFactor;
       inner_product=abs(normalisedDict)*squeeze(rawdata(i,j,:));
       % Find best matching pattern
       [maxValue, max_index] = max((inner_product));
       matched_indices(i, j) = max_index;
       T1Map(i,j) = r(max_index,1);
       T2Map(i,j) = r(max_index,2);
       MRFMask(i,j) = 1;
    end
end

figure(3);
subplot(1,2,1); imagesc(T1Map.*MRFMask);
subplot(1,2,2); imagesc(T2Map.*MRFMask,[0 200]);

ttt = normalisedDict(max_index,:);
r(max_index,1)
r(max_index,2)

figure(1);
subplot(2,1,1);plot(abs(ttt)); hold on; plot(abs(squeeze(normalized_mrfsignal))); legend("Dictionary","Measured");
subplot(2,1,2);plot(angle(ttt)); hold on; plot(angle(squeeze(normalized_mrfsignal)));legend("Dictionary","Measured");




figure(5);
subplot(1,3,1); imagesc(T1RefMap.*MRFMask,[0,300]); title("Inversion Recovery T1 Map"); axis square;
subplot(1,3,2); imagesc(T1Map,[0,300]); title("MRF T1 Map"); axis square;
subplot(1,3,3); imagesc(T1DiffMap.*MRFMask,[0 100]); title("Difference Map"); axis square;


figure(6);
subplot(1,3,1); imagesc(T2RefMap.*MRFMask,[0,100]); title("MSME T2 Map"); axis square;
subplot(1,3,2); imagesc(T2Map,[0,100]); title("MRF T2 Map"); axis square;
subplot(1,3,3); imagesc(T2DiffMap.*MRFMask,[0 100]); title("Difference Map"); axis square;

