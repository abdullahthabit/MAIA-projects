function data = LoadData
    FeatureFolder = 'all_features'; % Determine where folder is
    if ~isdir(FeatureFolder)
        errorMessage = sprintf('Error: The following folder does not exist:\n%s', FeatureFolder);
        uiwait(warndlg(errorMessage));
        return;
    end
    featurePattern = fullfile(FeatureFolder, '*.txt');
    txtFiles = dir(featurePattern);
    cd ('all_features')
    for k = 1:length(txtFiles)
        baseFileNameFeature = txtFiles(k).name;
        fullFileNameFeature = fullfile(FeatureFolder, baseFileNameFeature);
        fprintf(1, 'Now reading %s\n', fullFileNameFeature);
        facef = load(fullFileNameFeature);
        dif1 = abs(facef(2,1) - facef(1,1));
        dif2 = abs(facef(2,2) - facef(1,2));
        if dif2 > dif1
            fixedFacef = [facef(:,2),facef(:,1)];
        else
            fixedFacef = facef;
        end
        featuresArray{k} = fixedFacef;
        
    end
    cd ..

    myFolder = 'all_faces'; % Determine where demo folder is (works with all versions).
    if ~isdir(myFolder)
        errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
        uiwait(warndlg(errorMessage));
        return;
    end
    facePattern = fullfile(myFolder, '*.jpg');
    jpgFiles = dir(facePattern);
    cd ('all_faces')
    for k = 1:length(jpgFiles)
        baseFileNameFaces = jpgFiles(k).name;
        fullFileNameFaces = fullfile(myFolder, baseFileNameFaces);
        fprintf(1, 'Now reading %s\n', fullFileNameFaces);
        imageArray{k} = imread(fullFileNameFaces);
        imshow(imageArray{k});  % Display image.
        drawnow; % Force display to update immediately.
    end
    cd ..
    for k = 1:length(jpgFiles)

        data.name{k} = jpgFiles(k).name;
        data.features{k} = featuresArray{k};
        data.faces{k} = imageArray{k};
    end
end