function [train_images,test_images] = LoadTraining_TestingData
%% save croped faces lll
% cd('train_images');
% for i = 1:size(faces,3)
%     name = data.name{i};
%     image = mat2gray(faces(:,:,i));
%     imwrite(image,name);
% end
% cd ..
%% read training images
myFolder = 'train_images';
trainfile = fullfile(myFolder, '*.jpg');
jpgFiles = dir(trainfile);
cd(myFolder);
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
    name = jpgFiles(k).name;
    name = name(1:end-5);
    train_images.name{k} = name;
    train_images.faces{k} = imageArray{k};
end

%% read testing images

myFolder = 'test_images';
trainfile = fullfile(myFolder, '*.jpg');
jpgFiles = dir(trainfile);
cd(myFolder);
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
    name = jpgFiles(k).name;
    name = name(1:end-5);
    test_images.name{k} = name;
    test_images.faces{k} = imageArray{k};
end


