close all, clear all
%% Load initial data (No need to run these functions)
% data = LoadData;
%% Normalize each raw image to a size of 64x64
% faces = NormalizeFaces(data);
%% Load training and testing datasets
[trainData,testData] = LoadTraining_TestingData;
%% PCA face recognition
train_output = PCArecognition(trainData,97);
%% Test the system: find the best match
Top3matchesFlag = 1;
accuracy = FindFace(trainData,testData,train_output,Top3matchesFlag);


