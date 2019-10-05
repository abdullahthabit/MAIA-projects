function accuracy = FindFace(trainData,testData,train_output,top3FLAG)
    testD = zeros(length(testData.faces),64*64);
    p = length(testData.faces);
    for i = 1:p
        face = testData.faces{i};
        face = face';
        columnFace = face(:)';
        % creating the data matrix
        testD(i,:) = columnFace;
        name = testData.name{i};
        % creating a label matrix
        Ltest{i} = name;
    end
    errorCount = p;
    for q = 1:p
        testF = testD(q,:)*train_output.projecM;
        dist = zeros(size(train_output.features,1),1);
        for i = 1:size(train_output.features,1)
            trainF = train_output.features(i,:);
            dist(i) = sqrt(sum((trainF - testF).^2));
        end
        [sorted,idxmin] = sort(dist);
        top1match = trainData.name{idxmin(1)};
        top2match = trainData.name{idxmin(2)};
        top3match = trainData.name{idxmin(3)};
        confidence = (abs(sorted(1) - sorted(2)))/sorted(1)*100;
        personTrue = Ltest{q};
        matchTrue = top1match(1:3) == personTrue(1:3);
        match2True = top2match(1:3) == personTrue(1:3);
        match3True = top3match(1:3) == personTrue(1:3);
        matchFalse = matchTrue(matchTrue  == 0);
        match2False = match2True(match2True  == 0);
        match3False = match3True(match3True  == 0);
        
        trueFace = cell2mat(testData.faces(q));
        matched1Face = cell2mat(trainData.faces(idxmin(1)));
        matched2Face = cell2mat(trainData.faces(idxmin(2)));
        matched3Face = cell2mat(trainData.faces(idxmin(3)));
        
        if(top3FLAG)
            check = (~isempty(matchFalse)&& ~isempty(match2False) && ~isempty(match3False));
        else
            check = ~isempty(matchFalse);
        end
        if (check)
        errorCount = errorCount - 1;

%         figure,subplot(221),imshow(trueFace,[])
%         title(['true person: ' personTrue])
%         subplot(222),imshow(matched1Face,[])
%         title(['1st match: ' top1match ' - conf = ' num2str(confidence)])
%         subplot(223),imshow(matched2Face,[])
%         title(['2nd match: ' top2match])
%         subplot(224),imshow(matched3Face,[])
%         title(['3nd match: ' top3match])
        end

%         figure,subplot(221),imshow(trueFace,[])
%         title(['true person: ' personTrue])
%         subplot(222),imshow(matched1Face,[])
%         title(['1st match: ' top1match ' - conf = ' num2str(confidence)])
%         subplot(223),imshow(matched2Face,[])
%         title(['2nd match: ' top2match])
%         subplot(224),imshow(matched3Face,[])
%         title(['3nd match: ' top3match])
%         drawnow;
    end
    accuracy = 100 * (errorCount/p) ;
    fprintf(1, 'accuracy = %4.2f %%\n', accuracy);
end



