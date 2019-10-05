function [ROI,marker] = FindROI(image4D,sliceN,frame)
    
    % compute the standard deviation along the time dimension
    std4d = std(double(image4D),[],4);
    std4d = im2int16(mat2gray(std4d));
    % compute the maximum intensity projection along the z axis
    mip = max(std4d,[],3);
    % blur the MIP
    blurredMIP = imgaussfilt(mip,0.5);  % (chosen emprically)
    % apply optimal thresholding
    BW1 = imbinarize(blurredMIP);
    % step 5: perform morphological operations 
    % do the dilation for the 1st time
    nhood = [0,1,0;1,1,1;0,1,0;];
    SE = strel(nhood);
    for i = 1:8
        dialated = imdilate(BW1,SE);
    end
    % finding the connected components
    CC = bwconncomp(dialated,4);
    % keeping only the largets connected component
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [~,idx] = max(numPixels);
    for i = 1: CC.NumObjects
        if (i ~= idx)
            dialated(CC.PixelIdxList{i}) = 0;
        end
    end
    % do the dilation for the 2nd time
    for i = 1:2
        dialated = imdilate(dialated,SE);
    end
    % step 6: compute the 2D convex hull of the binary image
    ROI = bwconvhull(dialated);
    % % check: impose the ROI on a sample slice of the 4D image
    sampleSlice = double(image4D(:,:,5,1));
    % figure,imshow(sampleSlice,[])
    sampleROI = sampleSlice .* ROI;
    % ROI = im2int16(mat2gray(ROI));
    figure,imshow(sampleROI,[])
    title('click a point inside the LV','Color','r')
    [x,y] = ginput(1);
    marker = [x y];
    close;
end