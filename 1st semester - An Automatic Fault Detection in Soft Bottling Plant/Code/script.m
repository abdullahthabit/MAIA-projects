%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMAGE PROCESSING PROJECT SCRIPT
% AUTOMATED VISUAL INSPECTION FOR SOFT DRINK BOTTLING PLANT
% CREATED BY:
%   ABDULLAH THABIT
%   TEWODROS W. AREGA
%   ZOHAIB SALAHUDDIN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc

% PLEASE EDIT THIS LINE TO TEST THE IMAGE. THIS IS THE IMAGE NAME.
str_inst = 'nolabel-image052.jpg';
img = imread(str_inst);
  
% DISPLAYING THE ORIGINAL IMAGE
figure;
imshow(img, [])
hold on

% CONVERTING TO GRAYSCALE AND TAKING THE RED CHANNEL OF THE IMAGE
img_grayscale = rgb2gray(img);
img_grayscale_red = img(:,:,1);
img_grayscale_red = imadjust(img_grayscale_red);

% DETECTING THE MIDDLE OF THE CENTER BOTTLE 
img_grayscale_m = rgb2gray(img(:,:,:));
img_grayscale_extracted_m = img_grayscale_m(5:65,120:240);
img_thresh_m = ~(img_grayscale_extracted_m>180);
    
se_m = strel ('rectangle' , [10,2]);
img_thresh_m = imclose (img_thresh_m,se_m);
[r , c] = find( img_thresh_m == 1);
c_avg =0;

if ( size(c,1) > 0)
    c_avg = sum (c)/size(c,1); 
end

c_avg = floor(c_avg);
% c_avg is the x_cordinate of the Center Bottle        
    

% CONSTANTS FOR DISPLAYING THE OVERLAYED RECTANGLE
% RECTANGLE FOR UNDERFILLED
uf_x = 120+c_avg - 60;
uf_y = 140;
uf_l = 120;
uf_w = 20;

% RECTANGLE FOR OVERFILLED
ov_x = 120+c_avg - 60;
ov_y = 100;
ov_l = 120;
ov_w = 40;

% RECTANGLE FOR NO LABEL
nl_x = 120+c_avg - 60;
nl_y = 180;
nl_l = 120;
nl_w = 100;

% RECTANGLE FOR NO LABEL PRINT
nlp_x = 120+c_avg - 60;
nlp_y = 180;
nlp_l = 120;
nlp_w = 100;

% RECTANGLE FOR DEFORMED LEFT
d1_x =120+c_avg +40 ;
d1_y = 180;
d1_l = 26;
d1_w = 91;

% RECTANGLE FOR DEFORMED RIGHT
d2_x =120+c_avg - 60-5;
d2_y = 180;
d2_l = 26;
d2_w =91 ;

%RECTANGLE FOR LABEL NOT STRAIGHT
lns_x = 120+c_avg - 60;
lns_y = 170;
lns_l = 120;
lns_w = 30;

%RECTANGLE FOR CAP MISSING
cm_x =120+c_avg -40 ;
cm_y = 10;
cm_l = 80;
cm_w = 40;

% RECTANGLE FOR DEFORMED MIDDLE
dm_x =120+c_avg -50;
dm_y = 150;
dm_l = 100;
dm_w = 100;


% THESE ARE WINDOWS FOR FEATURE EXTRACTION FOR EACH OF THE FAULTS
% FOR OVERFILLED
img_grayscale_extracted = img_grayscale(135:155,120:240);
% FOR UNDERFILLED
img_grayscale_extracted2 = img_grayscale(115:135,120:240);
% FOR LABEL MISSING
img_grayscale_extracted3 = img_grayscale(180:280,120:240);
% FOR NO LABEL PRINT
img_grayscale_extracted4 = img_grayscale(180:280,120:240); 
% FOR CAP MISSING
img_grayscale_extracted5 = img_grayscale(10:45,150:200);
% FOR MIDDLE BOTTLE MISSING
img_grayscale_extracted6 = img_grayscale(1:280,130:220); 
%FOR LABEL NOT STRAIGHT
img_grayscale_extracted7 = img_grayscale(170:190,115:234);
%FOR DEFORMED RIGHT
img_grayscale_extracted8 = (img_grayscale_red(180:270,((120+c_avg+60-20):(120+c_avg+60))));
%FOR DEFORMED LEFT
img_grayscale_extracted_b = (img_grayscale_red(180:270,((120+c_avg-60):(120+c_avg-60+20))));
%FOR LABEL NOT STRAIGHT
img_grayscale_extracted9 = img_grayscale_red(190:260,110:230);
%FOR DEFORMED FRONT
img_grayscale_extracted11 = rgb2gray(img(80:170,(120+c_avg-40):(120+c_avg+40),:));



% OVERFILLED THRESHOLD
img_thresh = ~(img_grayscale_extracted>150);
% UNDERFILLED THRESHOLD
img_thresh2 = ~(img_grayscale_extracted2>150);
% LABEL NOT PRESENT THRESHOLD
img_thresh3 = ~(img_grayscale_extracted3>70);
% LABEL NOT PRINTED THRESHOLD
img_thresh4 = ~(img_grayscale_extracted4>150);
% CAP MISSING THRESHOLD
img_thresh5 = ~(img_grayscale_extracted5>150);
% MIDDLE BOTTLE MISSING THRESHOLD
img_thresh6 = ~(img_grayscale_extracted6>150 & img_grayscale_extracted6<230);
% DEFORMATION RIGHT THRESHOLD
img_thresh7 = ~(img_grayscale_extracted8>180);
% CLEANING UP RIGHT DEFORMATION BY OPENING
se = strel('rectangle',[50 3]);
img_thresh7 = imopen(img_thresh7,se);
% DEFORMATION LEFT THRESHOLD
img_thres_b = ~(img_grayscale_extracted_b>180);
% CLEANING UP LEFT DEFORMATION BY OPENING
img_thres_b = imopen(img_thres_b,se);
% LABEL NOT STRAIGHT THRESHOLD
img_thresh8 = (img_grayscale_extracted9>100);
% DEFORMED FRONT THRESHOLD
img_thresh11 = ~(img_grayscale_extracted11 > 100);


% OVERFILLED       
dimension = 20 * 120;
% UNDERFILLED 
dimension2 = 20 * 120;
% LABEL NOT PRESENT
dimension3 = 100 * 120;
% LABEL NOT PRINTED
dimension4 = 100 * 120;
% CAP MISSING
dimension5 = 45 * 50;
% MIDDLE BOTTLE MISSING
dimension6 = 280 * 90;
% LEFT AND RIGHT DEFORMATION
dimension7 = 71*26;
% DEFORMED FRONT 
dimension11 = 81 * 91;


% OVERFILLED
no_of_white_pixels = sum(img_thresh(:));
% UNDERFILLED
no_of_white_pixels2 = sum(img_thresh2(:));
% LABEL NOT PRESENT
no_of_white_pixels3 = sum(img_thresh3(:));
% LABEL NOT PRINTED
no_of_white_pixels4 = sum(img_thresh4(:));
% CAP MISSING
no_of_white_pixels5 = sum(img_thresh5(:));
% MIDDLE BOTTLE MISSING
no_of_white_pixels6 = sum(img_thresh6(:));
% DEFORMED RIGHT
no_of_white_pixels7 = sum(img_thresh7(:));
% DEFORMED LEFT
no_of_white_pixels_b = sum(img_thres_b(:));


%OVER FILLED
percentage = no_of_white_pixels/dimension *100;
% UNDERFILLED
percentage2 = no_of_white_pixels2/dimension2 *100;
% LABEL NOT PRESENT
percentage3 = no_of_white_pixels3/dimension3 *100;
% LABEL NOT PRINTED
percentage4 = no_of_white_pixels4/dimension4 *100;
% CAP MISSING
percentage5 = no_of_white_pixels5/dimension5 *100;
% MIDDLE BOTTLE MISSING
percentage6 = no_of_white_pixels6/dimension6 *100;
% DEFORMED RIGHT
percentage7 = (no_of_white_pixels7/dimension7) * 100 ;
% DEFORMED LEFT
percentage_b = (no_of_white_pixels_b/dimension7) * 100 ;
% LABEL NOT STRAIGHT THRESHOLD
percentage8 = (sum(img_thresh8(:))/(71*121))*100;
% DEFORMED FRONT
percentage11 = (sum(img_thresh11(:))/dimension11)*100;



% FRONT DEFORMATION DETECTION
img_edge1 = edge (img_grayscale_extracted11,'canny');    
se = strel('rectangle',[2 1]);
img_edge1 = imopen(img_edge1,se);
img_edge1 = bwareaopen(img_edge1,15);
val_cmp = sum (img_edge1(:)); % THIS VALUE IS USED FOR FRONT DEFORMATION

% LABEL NOT STRAIGHT CONVOLUTION DETECTION
img_edge = edge (img_grayscale_extracted7,'canny',0.5);
se = strel ('rectangle',[1 1]);
img_edge= imclose (img_edge,se);
mirror_ref = double(img_edge(:,1:60));
mirror1 = double(img_edge (:, 61:end));
mirror1 = flip(mirror1,2);
a = (conv2(mirror1,mirror_ref));
ssimval = max(abs(a(:)));  % THIS VALUE IS USED
   

% HOUGH TRANSFORM FOR LABEL NOT STRAIGHT DETECTION
[H,T,R] = hough(img_edge);
P  = houghpeaks(H);
lines = houghlines(img_edge,T,R,P);
max_len = 0;
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    len = norm(lines(k).point1 - lines(k).point2);
    if ( len > max_len)
        max_len = len; % THIS VALUE IS USED
        xy_long = xy;
    end
end
 

% FLAG TO KEEP TRACK OF MULTIPLE FAULTS
flag = 0;
flag_under =0;
       
% DETECTING IF THE MIDDLE BOTTLE IS PRESENT
if ( percentage6 < 5)


else
% UNDERFILLED FAULT DETECTION AND DISPLAY
     if ( percentage < 20)
     disp('UNDERFILLED FAULT');
     flag_under = 1;
     flag =1;
     rectangle('Position', [uf_x,uf_y,uf_l,uf_w],'EdgeColor','b')
     end
% OVER FILLED FAULT DETECTION AND DISPLAY
     if ( percentage2 > 20)
     disp('OverFILLED FAULT');
     flag =1;
     rectangle('Position', [ov_x,ov_y,ov_l,ov_w],'EdgeColor','b')         
     end
% CAP MISSING FAULT DETECTION AND DISPLAY
    if ( percentage5 < 30)
        disp('No Cap Found')
        flag =1;
        rectangle('Position', [cm_x,cm_y,cm_l,cm_w],'EdgeColor','b')         
    end


% LABEL NOT FOUND FAULT DETECTION AND DISPLAY
    if( percentage3 > 50)
        disp('No Label Found');
        rectangle('Position', [nl_x,nl_y,nl_l,nl_w],'EdgeColor','b')         
        flag =1;

% NO LABEL PRINT FOUND FAULT DETECTION AND DISPLAY
    else
        if ( percentage4 < 30)
        disp('No Label Print Found')
        rectangle('Position', [nlp_x,nlp_y,nlp_l,nlp_w],'EdgeColor','b')         
        flag =1;
        
% LABEL NOT STRAIGHT FAULT DETECTION AND DISPLAY
        elseif ((max_len < 47 || percentage8 < 86) && ssimval < 27 )
            disp('Label Not Straight')
            rectangle('Position', [lns_x,lns_y,lns_l,lns_w],'EdgeColor','b')         
            flag =1;
        elseif ((ssimval < 12 && max_len <60)||(ssimval < 30 && max_len >80) )
            disp('Label Not Straight')
            rectangle('Position', [lns_x,lns_y,lns_l,lns_w],'EdgeColor','b')         
            flag =1;


% BOTTLE IS DEFORMED DETECTION AND DISPLAY
        elseif (((percentage7 >31 | percentage_b >35))& flag_under ~= 1)
            disp('Bottle is deformed');
            if (percentage7 >31)
                rectangle('Position', [d1_x,d1_y,d1_l,d1_w],'EdgeColor','b')
            end
            if (percentage_b>35)             
               rectangle('Position', [d2_x,d2_y,d2_l,d2_w],'EdgeColor','b')         
            end
            flag =1;
        elseif (val_cmp > 350 & flag_under ~= 1 & percentage11<80 & percentage7<5 & percentage_b < 5)
            disp('Bottle is deformed');
            rectangle('Position', [dm_x,dm_y,dm_l,dm_w],'EdgeColor','b')
            flag = 1;
        end
    end
end

% IF NO FAULT IS DETECTED OR MIDDLE BOTTLE IS MISSING DISPLAY NORMAL
if (flag == 0)
    disp('Normal Case');
end

    





