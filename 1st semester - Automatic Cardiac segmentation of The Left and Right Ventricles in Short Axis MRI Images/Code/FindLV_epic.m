function epiFull = FindLV_epic(image4D,LV,SLICE_NUM,FRAME,W_LENGTH)

    slice = double(image4D(:,:,SLICE_NUM,FRAME));
    if (max(max(LV)) == 0)
        epiFull = zeros(size(slice));
    else
        % construct a smaller window for the slice and the LV mask
        dm = (W_LENGTH-1)/2;
        LVcentroid = regionprops(LV,'Centroid');
        LVcentroid = round(cat(1,LVcentroid.Centroid));
        square = [LVcentroid(1)-dm,LVcentroid(2)-dm,dm*2,dm*2];
        rect = imcrop(slice,square);
        rectMask = imcrop(LV,square);
        % dilate the LV mask
        nhood = [1,1,1;1,1,1;1,1,1];
        SE = strel(nhood);
        rectMaskfil = imfill(rectMask,'holes');
        rectMaskfil = imdilate(rectMaskfil,SE);
        % convert the slice and the mask to the polar coordinates
        rectPol = ImToPolar(rect, 0, 1, size(rect,1), size(rect,2));
        rectMaskPol = ImToPolar(rectMaskfil, 0, 1, size(rectMaskfil,1), size(rectMaskfil,2));
        % invert the mask to subtract it
        rectMaskPol = imcomplement(rectMaskPol);
        % find the slice edges
        epiEdge = edge(rectPol,'canny');
        % apply the mask
        epiIm = epiEdge .* rectMaskPol;
        % eliminate small objects 
        epiIm = (epiIm >= 1) ;
        st = strel('rectangle',[1 2]);
        epiii = imopen(epiIm,st);
        epiIm = epiii;
        % find the epicardial line as the first on pixel in each column
        for j = 1: size(epiIm,2)
            flag = 1;
            for i = 1:size(epiIm,2)
                if (flag == 1)
                    if (epiIm(i,j) == 1)
                        epiIm(i,j) = 1;
                        flag = 0;
                    else
                        epiIm(i,j) = 0;
                    end
                else
                    epiIm(i,j) = 0;
                end
            end
        end
        % eliminate outlier pixels
        [r , c ] = find (epiIm == 1);
        r_avg = floor(sum(r)/size(r,1));
        if ~isnan(r_avg)
            margin = 10;
            epiIm(1:r_avg-margin,:) = 0;
            epiIm(r_avg+margin:end,:) = 0;
        end
        % convert the epicardial line back to the cartesian coordinates
        epiCont = PolarToIm (epiIm, 0, 1, size(epiIm,1), size(epiIm,2));
        % eliminate outliers in the contour
        epiCont = bwareaopen(epiCont,5);
        % find the contour's and mask's convexhull
        epiConv = bwconvhull(epiCont);
        convLV = bwconvhull(rectMask);
        nr = 1; nc = 1;
        epiFull = zeros(size(slice));
        for j = round(square(1)):(round(square(1))+square(3))
            for i = round(square(2)):(round(square(2))+square(4))
                epiFull(i,j) = epiConv(nr,nc);
                nr = nr + 1;
            end
            nr = 1;
            nc = nc + 1;
        end
    end
end