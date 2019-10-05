function segImage = ShowContours(image4D,LV,RV,LV_epic,sliceN,frame,W_LENGTH)
    
    slice = double(image4D(:,:,sliceN,frame));
    % show the slice with the contours
    figure('units','normalized','outerposition',[0 0 1 1])
    subplot(121),imshow(slice,[])
    hold on
    contour(LV_epic,'r');
    contour(LV,'g');
    contour(RV,'w');
    hold off
    
    % show the segmented image
    labelLV = 1 * LV;
%     figure,imshow(labelLV,[])
    labelLV_epic = 2 * (LV_epic - LV);
%     figure,imshow(labelLV_epic,[])
    labelRV = 3 * RV;
%     figure,imshow(labelRV,[])
    segImage = labelLV + labelLV_epic + labelRV;
    for j = 1:size(segImage,2)
        for i = 1:size(segImage,1)
            if segImage(i,j) == 5
                segImage(i,j) = 3;
            end
        end
    end
%     subplot(222),imshow(segImage,[])
    % create a smaller window
    if (max(max(LV)) == 0)
      subplot(122),imshow(slice,[])  
%     subplot(223),imshow(slice,[])
%     subplot(224),imshow(slice,[])
    else
        dm = W_LENGTH/2;
        LVcentroid = regionprops(LV,'Centroid');
        LVcentroid = cat(1,LVcentroid.Centroid); 
        rectSlice = slice(LVcentroid(2)-dm:LVcentroid(2)+dm,LVcentroid(1)-dm:LVcentroid(1)+dm);
        rectLV = LV(LVcentroid(2)-dm:LVcentroid(2)+dm,LVcentroid(1)-dm:LVcentroid(1)+dm);
        rectRV = RV(LVcentroid(2)-dm:LVcentroid(2)+dm,LVcentroid(1)-dm:LVcentroid(1)+dm);
        rectMyo = LV_epic(LVcentroid(2)-dm:LVcentroid(2)+dm,LVcentroid(1)-dm:LVcentroid(1)+dm);
        % show the smaller window with the contours 
        subplot(122),imshow(rectSlice,[])
        hold on
        contour(rectMyo,'r');
        contour(rectLV,'g');
        contour(rectRV,'w');
        hold off
        
        % show the segmented image
        labelLV = 1 * rectLV;
%         figure,imshow(labelLV,[])
        labelLV_epic = 2 * (rectMyo - rectLV);
%         figure,imshow(labelLV_epic,[])
        labelRV = 3 * rectRV;
%         figure,imshow(labelRV,[])
        segRect = labelLV + labelLV_epic + labelRV;
        for j = 1:size(segRect,2)
            for i = 1:size(segRect,1)
                if segRect(i,j) == 5
                    segRect(i,j) = 3;
                end
            end
        end
%         subplot(224),imshow(segRect,[])
    end

end