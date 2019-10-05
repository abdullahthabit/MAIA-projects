function [m1face,m2face,m3face] = FindMatchedFace(testFace,nameFace,trainData,train_output)
    
    Face = testFace';
    columnFace = Face(:)';
    columnFace = double(columnFace);
    testF = columnFace * train_output.projecM;
    dist = zeros(size(train_output.features,1),1);
    for i = 1:size(train_output.features,1)
         trainF = train_output.features(i,:);
         dist(i) = sqrt(sum((trainF - testF).^2));
    end
    [sorted,idxmin] = sort(dist);
    top1match = trainData.name{idxmin(1)};
    top2match = trainData.name{idxmin(2)};
    top3match = trainData.name{idxmin(3)};
    totalDistance = sorted(1) + sorted(2) + sorted(3);
    top1fraction = 50*(1 - (sorted(1)/totalDistance));
    top2fraction = 50*(1 - (sorted(2)/totalDistance));
    top3fraction = 50*(1 - (sorted(3)/totalDistance));
    matchTrue = top1match(1:3) == nameFace(1:3);
    
    matched1Face = cell2mat(trainData.faces(idxmin(1)));
    matched2Face = cell2mat(trainData.faces(idxmin(2)));
    matched3Face = cell2mat(trainData.faces(idxmin(3)));
    
    m1face.name = top1match;
    m1face.image = matched1Face;
    m1face.percentage = top1fraction;
    
    m2face.name = top2match;
    m2face.image = matched2Face;
    m2face.percentage = top2fraction;
    
    m3face.name = top3match;
    m3face.image = matched3Face;
    m3face.percentage = top3fraction;
% %     figure,
%     subplot(221),imshow(testFace,[])
%     title(['true person: ' nameFace(1:end-6)])
% %     axes(handles.axes2);
%     subplot(222),
%     imshow(matched1Face,[])
%     title(['1st match: ' top1match ' - conf = ' num2str(confidence)])
% %     axes(handles.axes3);
%     subplot(223),
%     imshow(matched2Face,[])
%     title(['2nd match: ' top2match])
% %     axes(handles.axes2);
%     subplot(224),
%     imshow(matched3Face,[])
%     title(['3nd match: ' top3match])
    


end