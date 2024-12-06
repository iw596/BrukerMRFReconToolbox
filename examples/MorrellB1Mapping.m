addpath("FileIO\")
addpath("B1Mapping\")
addpath("recon\")



pth = "datasets\PhaseB1\45";
params = LoadBrukerData(pth);
data = reshape(params.data,[params.NCol,2,params.NLin,params.NPar]);
data = permute(data,[1 3 4 2]);
imgs = ifftcn(data,[1 2 3]);


%% Create binary mask from mean of images
se = strel('disk', 20, 0);
mask = mean(imgs,4);
mask = imbinarize(mat2gray(abs(mask)));
mask = imclose(mask, se);
mask = imfill(mask, 'holes');
phaseDiffImg = [];
phaseDiffImg = angle(imgs(:,:,:,1) .* conj(imgs(:,:,:,2)));


alpha = deg2rad([1:0.01:180]);
theta = 2.0 * atan(2.0*cos(alpha)./cos(2*alpha));
LUT = [];
LUT(:,1) = theta(:);
LUT(:,2) = alpha(:);
faMap = [];
for i = 1:size(phaseDiffImg,1)
    for j = 1:size(phaseDiffImg,2)
        for k =1:size(phaseDiffImg,3)
            measuredPhaseDiff = squeeze(phaseDiffImg(i,j,k));
            [val,idx] = min(abs(measuredPhaseDiff-squeeze(LUT(:,1))));
            closestFA = LUT(idx,2);
            faMap(i,j,k) = closestFA;
        end
    end
end

figure; imagesc(abs(squeeze(rad2deg(faMap(:,:,8))./90)),[0.9 1.1]); axis square;



figure(1);
subplot(2,2,1); imshow(abs(imgs(:,:,8,1)),[]);
subplot(2,2,2); imshow(abs(imgs(:,:,8,2)),[]);
subplot(2,2,3); imagesc(rad2deg(faMap(:,:,8))./90,[0.9,1.1]); axis square;