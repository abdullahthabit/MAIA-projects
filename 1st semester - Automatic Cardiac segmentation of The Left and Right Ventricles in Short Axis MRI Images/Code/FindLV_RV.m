function [LV,RV] = FindLV_RV(image4D,ROI,marker,SLICE_NUM,FRAME)
    
    slice = double(image4D(:,:,SLICE_NUM,FRAME));
%      figure,imshow(sampleSlice,[])
    sliceROI = slice .* ROI;
    % ROI = im2int16(mat2gray(ROI));
    % apply power-law transformation to enhance the contrast
    k = 1; gama = 1.3;
    I = round(k .* (sliceROI .^gama));
    % thresholding the transfomred image
    I = im2int16(mat2gray(I));
    BW = imbinarize(I);
    % apply errosing and dilation to elimination some of the small objects
    nhood = [0,1,0;1,1,1;0,1,0];
    SE = strel(nhood);
    err = imerode(BW,SE);
    err = imerode(err,SE);
    dil = imdilate(err,SE);
    dil = imdilate(dil,SE);
    % finding the connected components and keep only the biggest 5
    C = bwconncomp(dil,4);
    numPixelsC = cellfun(@numel,C.PixelIdxList);
    [numPixelsC,id] = sort(numPixelsC,'descend');
    if(length(id) > 4)
        dil = zeros(size(dil));
        for i = 1: 5
            ii = id(i);
            dil(C.PixelIdxList{ii}) = 1;
        end
    end
    % label the remaining objects
    [L,n] = bwlabel(dil);
    if n > 1
        centroids = regionprops(L,'Centroid');
        centroids = cat(1, centroids.Centroid);
        for i = 1: n
            distx = centroids(i,1) - marker(1);
            disty = centroids(i,2) - marker(2);
            dist(i) = sqrt((distx.^2) + (disty.^2));
        end
        [~,idxmin] = min(dist);
        LVcentroid = centroids(idxmin,:);
        % calculate min distance from LV centroid to locate the RV
        for i = 1: n
            distx = centroids(i,1) - LVcentroid(1);
            disty = centroids(i,2) - LVcentroid(2);
            dist(i) = sqrt((distx.^2) + (disty.^2));
        end
        [~,idxmin] = sort(dist);
        RVcentroid = centroids(idxmin(2),:);
        lvLabel = round(LVcentroid);
        LvLabel = L(lvLabel(2),lvLabel(1));
        [lvr,lvc] = find(L==LvLabel);
        LV = zeros(size(L));
        for i = 1: length(lvr)
            LV(lvr(i),lvc(i)) = 1;
        end
        LV = bwconvhull(LV);
        rvLabel = round(RVcentroid);
        RvLabel = L(rvLabel(2),rvLabel(1));
        [rvr,rvc] = find(L==RvLabel);
        RV = zeros(size(L));
        for i = 1: length(rvr)
            RV(rvr(i),rvc(i)) = 1;
        end
        RV = imfill(RV);
        RVcontour = edge(RV);
    else
        LV = zeros(size(slice));
        RV = zeros(size(slice));
    end
end