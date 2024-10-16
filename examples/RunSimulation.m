addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")
%t1series = [50:10:2000,2020:20:3000,3050:50:5000];
%t2series = [6:5:100,110:10:200,202:2:500];

t1series = [50:10:5000];
t2series = [10:5:500];
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
pth = "datasets\48";
params = LoadBrukerData(pth);
FAList = ReadFAList("datasets\MRFFAPattern.txt");


%% Reconstruct data (assuming 128 points,64 lines and 600 FA)
rawdata  = params.data;
rawdata = reshape(rawdata, [128 length(FAList) 64]);
rawdata = permute(rawdata, [1 3 2]);
imgs = ifftcn(rawdata,[1 2]);
figure(1); montage(mat2gray(abs(imgs)));
figure(2);plot(abs(squeeze(imgs(64,32,:))));
%figure(2); imshow(abs(imgs(:,:,300)),[])


%% Open B1 mapping dataset


%% Set-up sequence parameters
seqParams.TI = 8; % ms
seqParams.TR = 13;  %ms
seqParams.TE = 5;   %ms
seqParams.InversionApplied = 1;
seqParams.FA = FAList;


TE = ones([size(seqParams.FA)]);
TE(:) = seqParams.TE;
seqParams.TE = TE;
TR = ones([size(seqParams.FA)]);
TR(:) = seqParams.TR;
seqParams.TR = TR;

% d) put into the main simulated signal  
tic
dict = [];
for ii = 1:size(T1,1)
    tissueParams.T1 = T1(ii);
    tissueParams.T2 = T2(ii);
  %  Msignal = FISPSimulation(seqParams,tissueParams,250);
    Msignal = FISPSimulation(seqParams,tissueParams,300);
    
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
    for j = 1:64
       % for k = 1:size(mrfsignal, 3)
       scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
       normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
       inner_product=abs(normalisedDict*squeeze(normalized_mrfsignal));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       matched_indices(i, j) = max_index;
       if (maxValue < 0.9)
        T1Map(i,j) = 0;
        T2Map(i,j) = 0;
        MRFMask(i,j) = 0;

       else
         T1Map(i,j) = r(max_index,1);
         T2Map(i,j) = r(max_index,2);
         MRFMask(i,j) = 1;
       end
    end
end


figure(4);
subplot(1,2,1);imagesc(T1Map);title("T1 Map");
subplot(1,2,2);imagesc(T2Map);title("T2 Map");





ttt = normalisedDict(max_index,:);
r(max_index,1)
r(max_index,2)

figure(1);
subplot(2,1,1);plot(abs(ttt)); hold on; plot(abs(squeeze(normalized_mrfsignal)));
subplot(2,1,2);plot(angle(ttt)); hold on; plot(angle(squeeze(imgs(i,j,:))));


%% Gold standard Inversion recovery and MSME T2 mapping
pth = "datasets/40/pdata/1/2dseq";
params = LoadBrukerData("datasets/40");
fid = fopen(pth);
data = fread(fid,"int16");
data = reshape(data,[128 128 61]);
fclose(fid);

%% Generate Mask from first inversion time
se = strel('disk', 10, 0);
BW = imbinarize(mat2gray(data(:,:,1)));
BW = imclose(BW, se);
BW = imfill(BW, 'holes');
T1RefMap = T1Fitting(data,params.InvTimes,BW);
T1DiffMap = (T1RefMap - T1Map)./T1Map * 100;

%% Perform T2 fitting on MSME data
pth = "datasets/41/pdata/1/2dseq";
params = LoadBrukerData("datasets/41");
fid = fopen(pth);
data = fread(fid,"int16");
data = reshape(data,[128 128 41]);
fclose(fid);
T2RefMap = T2Fitting(data,params.MSMETimes,BW);
T2DiffMap = (T2RefMap - T2Map)./T2Map * 100;


figure(5);
subplot(1,3,1); imagesc(T1RefMap); title("Inversion Recovery T1 Map"); axis square;
subplot(1,3,2); imagesc(T1Map); title("MRF T1 Map"); axis square;
subplot(1,3,3); imagesc(T1DiffMap.*MRFMask,[0 100]); title("Difference Map"); axis square;


figure(6);
subplot(1,3,1); imagesc(T2RefMap); title("MSME T2 Map"); axis square;
subplot(1,3,2); imagesc(T2Map,[0,100]); title("MRF T2 Map"); axis square;
subplot(1,3,3); imagesc(T2DiffMap.*MRFMask,[0 100]); title("Difference Map"); axis square;


figure(7);

