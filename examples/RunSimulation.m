addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")

%t1series = [50:10:2000,2020:20:3000,3050:50:5000];
%t2series = [6:5:100,110:10:200,202:2:500];

t1series = [50:5:500];
t2series = [10:5:250];
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
pth = "datasets\68";
params = LoadBrukerData(pth);
%FAList = ReadFAList("datasets\FATest.txt");


%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
rawdata = reshape(rawdata, [128 600 128]);
rawdata = permute(rawdata, [1 3 2]);
imgs = ifftcn(rawdata,[1 2]);
figure(1); montage(mat2gray(abs(imgs)))
figure(2); imshow(abs(imgs(:,:,300)),[])


%% Open B1 mapping dataset
pth = "datasets\70";
params = LoadBrukerData(pth);
rawdata  = params.data;
rawdata = reshape(rawdata, [128 2 64 64]);
rawdata = permute(rawdata, [1 3 4 2]);
B1imgs = fftcn(rawdata,[1 2 3]);
B1imgs = imresize(B1imgs,[128 128]);
% Fit B1 maps
B1Map = AFIB1(B1imgs,60,20,100);
%approx slice 36 I think?
%figure(4); imagesc(B1Map(:,:,45));

%% Set-up sequence parameters
seqParams.TI = 10; % ms
seqParams.TR = 13;  %ms
seqParams.TE = 5;   %ms
seqParams.FA = GenerateFAPattern(45.0,5.0,600);

FA = ReadFAList("examples/FATest.txt");

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
cnt=length(dict);
for c = 1:cnt  
    scaleFactor = sqrt(sum(dict(c,:).*conj(dict(c,:))));
    normalisedDict(c,:) = dict(c,:) / scaleFactor;
end

% Iterate through each voxel
for i = 1:128
    for j = 1:128
       % for k = 1:size(mrfsignal, 3)
       scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
       normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
       inner_product=normalisedDict*squeeze(normalized_mrfsignal);
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       matched_indices(i, j) = max_index;
       if (maxValue < 0.9)
        T1Map(i,j) = 0;
        T2Map(i,j) = 0;
       else
         T1Map(i,j) = r(max_index,1);
         T2Map(i,j) = r(max_index,2);
       end
    end
end



ttt = normalisedDict(max_index,:);
r(max_index,1)
r(max_index,2)

figure(1);
subplot(2,1,1);plot(abs(ttt)); hold on; plot(abs(squeeze(normalized_mrfsignal)));
subplot(2,1,2);plot(angle(ttt)); hold on; plot(angle(squeeze(normalized_mrfsignal)));


%% Gold standard Inversion recovery and MSME T2 mapping
pth = "datasets/64/pdata/1/2dseq";
params = LoadBrukerData("datasets/64");
fid = fopen(pth);
data = fread(fid,"int16");
data = reshape(data,[128 128 31]);
fclose(fid);

%% Generate Mask from first inversion time
se = strel('disk', 10, 0);
BW = imbinarize(mat2gray(data(:,:,1)));
BW = imclose(BW, se);
BW = imfill(BW, 'holes');


T1RefMap = T1Fitting(data,params.InvTimes,BW);

%% Perform T2 fitting on MSME data
pth = "datasets/65/pdata/1/2dseq";
params = LoadBrukerData("datasets/65");
fid = fopen(pth);
data = fread(fid,"int16");
data = reshape(data,[128 128 20]);
fclose(fid);
T2RefMap = T2Fitting(data,params.MSMETimes,BW);


figure(5);
subplot(1,2,1); imagesc(T1RefMap,[0,300]); title("Inversion Recovery T1 Map");
subplot(1,2,2); imagesc(T1Map,[0,300]); title("MRF T1 Map");

figure(6);
subplot(1,2,1); imagesc(T2RefMap,[0,100]); title("MSME T2 Map");
subplot(1,2,2); imagesc(T2Map,[0,100]); title("MRF T2 Map");


figure(7);

