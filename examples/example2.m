addpath("Simulations\")
addpath("recon\")
addpath("B1Mapping\")
addpath("Fitting\")
addpath("FileIO\")

pth = "datasets\MRF_IWFISP";
params = LoadBrukerData(pth);
FA = ReadMRFList("datasets\MRFPattern.txt");
plot(FA);
rawdata  = params.data;
rawdata = reshape(rawdata, [params.NCol length(FA) params.NLin]);
rawdata = permute(rawdata, [1 3 2]);
rawdata=kspace;

% newlines
 % Poisson Disk Sampling Mask
     % gridSize: [Nx, Ny] size of k-space
    % undersamplingFactor: reduction factor (e.g., 4 for 25% sampling)
    % radius: minimum spacing between sampled points

gridSize= [128, 128];

% Example Usage
undersamplingFactor = 2; % Retain 50% of k-space
radius = 6; % Minimum spacing between points
% Call the function
samplingMask = poissonDiskMask([128, 128], undersamplingFactor, radius);

% Visualize the mask
imagesc(samplingMask); colormap('gray'); axis image;
title('Poisson Disk Sampling Mask with Radius 6');

% step3
% Assuming the fully sampled k-space data is loaded as 'kspace'
% kspace dimensions: 128 x 128 x 1980 (Nx x Ny x Nt)

% Apply the mask to each time frame
undersampled_kspace = kspace .* repmat(samplingMask, [1, 1, size(kspace, 3)]);

% Visualize one frame of the undersampled k-space
frameIndex = 1; % Example: Visualize the first frame
imagesc(log(abs(undersampled_kspace(:,:,frameIndex)) + 1)); colormap('gray'); axis image;
title('Undersampled k-space (Frame 1)');

disp(size(undersampled_kspace)); % Should output: [128, 128, 1980]

% Visualize the original fully sampled k-space for the same frame
figure;
subplot(1, 2, 1);
imagesc(log(abs(kspace(:,:,frameIndex)) + 1)); colormap('gray'); axis image;
title('Fully Sampled k-space (Frame 1)');

% Undersampled k-space
subplot(1, 2, 2);
imagesc(log(abs(undersampled_kspace(:,:,frameIndex)) + 1)); colormap('gray'); axis image;
title('Undersampled k-space (Frame 1)');


% FT for full k-space ( tabdile raw data be image)
imgs = ifftcn(rawdata,[1 2]);

% belafaseleh image ro mitoonim bebinim
figure(2); montage(mat2gray(abs(imgs)));
figure(3); plot(abs(squeeze(imgs(64,64,:))));

% Perform 2D Inverse Fourier Transform on the undersampled k-space data
undersampled_imgs = ifftcn(undersampled_kspace, [1 2]);

% visualise
figure(4); montage(mat2gray(abs(undersampled_imgs)));
figure(5); plot(abs(squeeze(undersampled_imgs(64,64,:))));

% For the full k-space montage
figure(2); 
montage(mat2gray(abs(imgs)));
title('Reconstructed Images (Full k-space)');

% For the full k-space temporal signal plot
figure(3); 
plot(abs(squeeze(imgs(64,64,:))), 'b', 'LineWidth', 1.5);
xlabel('Time Frame');
ylabel('Signal Magnitude');
title('Temporal Signal Evolution at Center Voxel (Full k-space)');

% For the undersampled k-space montage
figure(4); 
montage(mat2gray(abs(undersampled_imgs)));
title('Reconstructed Images (Undersampled k-space)');

% For the undersampled k-space temporal signal plot
figure(5); 
plot(abs(squeeze(undersampled_imgs(64,64,:))), 'r', 'LineWidth', 1.5);
xlabel('Time Frame');
ylabel('Signal Magnitude');
title('Temporal Signal Evolution at Center Voxel (Undersampled k-space)');
% Extract temporal signals for the center voxel
voxel_signal_full = abs(squeeze(imgs(64,64,:))); % Full k-space
voxel_signal_undersampled = abs(squeeze(undersampled_imgs(64,64,:))); % Undersampled k-space

% Plot both signals for comparison
figure(6);
plot(voxel_signal_full, 'b', 'LineWidth', 1.5); hold on;
plot(voxel_signal_undersampled, 'r--', 'LineWidth', 1.5);
legend('Full k-space', 'Undersampled k-space');
xlabel('Time Frame');
ylabel('Signal Magnitude');
title('Comparison of Temporal Signal Evolution at Center Voxel');




% matching process
%% Create binary mask from mean of images
se = strel('disk', 20, 0);
mask = mean(imgs,3);
mask = imbinarize(mat2gray(abs(mask)));
%mask = imclose(mask, se);
%mask = imfill(mask, 'holes');
figure;imshow(mask)

% Normalise Dictionary
normalisedDict = [];

cnt=size(dict,1);
parfor c = 1:cnt  
    scaleFactor = sqrt(sum(dict(c,:).*conj(dict(c,:))));
    normalisedDict(c,:) = dict(c,:) / scaleFactor;
    %normalisedDict(c,:) =  dict(c,:)./norm(squeeze( dict(c,:)));
end
% Iterate through each voxel
parfor i = 1:128
    i
    for j = 1:128
       % for k = 1:size(mrfsignal, 3)
       scaleFactor = sqrt(sum(imgs(i,j,:).*conj(imgs(i,j,:))));
       normalized_mrfsignal = conj(imgs(i,j,:))/scaleFactor;
       %normalized_mrfsignal = (imgs(i,j,:))/scaleFactor;
       %normalized_mrfsignal = squeeze(imgs(i,j,:)./norm(squeeze(imgs(i,j,:))));
       inner_product=abs((normalisedDict)*(squeeze(normalized_mrfsignal)));
       % Find best matching pattern
       [maxValue, max_index] = max(abs(inner_product));
       T1Map(i,j) = LUT(max_index,1);
       T2Map(i,j) = LUT(max_index,2);
       B1Map(i,j) = LUT(max_index,3);
       MRFMask(i,j) = 1;
       dotProductMaximums(i,j) = maxValue;

    end
end