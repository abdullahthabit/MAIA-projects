% Polar/Rectangular Conversion 
% V0.1 16 Dec 2007 (Created) Prakash Manandhar, pmanandhar@umassd.edu
im = rgb2gray(imread('TestIm.PNG'));
im = double(im)/255.0;
figure(1); imshow(im);
imP = ImToPolar(im, 0, 1, 200, 200);
figure; imshow(imP);

imR = PolarToIm(imP, 0.6, 1, 250, 250);
figure(3); imshow(imR);

rMin = 0.25; rMax = 0.8;

im2 = imread('TestIm2.jpg');
figure(4); imshow(im2);
imR2 = PolarToIm(im2, rMin, rMax, 300, 300);
figure(5); imshow(imR2, [0 255]);