close all,clear
%%
% change the patient number in: 'patient0XX_4d.nii.gz'
ImageName = 'patient005_4d.nii.gz';
% keep this, it is only for the ROI
SLICE_NUM = 5;
% change the frame number to go from ED to ES
FRAMEs = [1];

W_LENGTH = 100;
% load data
data4D = load_nii(ImageName);
image4D = data4D.img;
[y,x,z,t] = size(image4D);
%% Find ROI
[ROI,marker] = FindROI(image4D,SLICE_NUM,FRAMEs(1));
%% loop through each slice and frame
for tf = 1:length(FRAMEs)
    FRAME = FRAMEs(tf);
    for j = 1:z
        %% Find LV and RV endocardial contours
        [LV,RV] = FindLV_RV(image4D,ROI,marker,j,FRAME);
        LV4D(:,:,j,tf) = LV;
        RV4D(:,:,j,tf) = RV;
        %% Find LV epicardial contour
        LV_epic = FindLV_epic(image4D,LV,j,FRAME,W_LENGTH);
        LV_epic4D(:,:,j,tf) = LV_epic;
        %% show the contours together
        segImage = ShowContours(image4D,LV,RV,LV_epic,j,FRAME,W_LENGTH);
        segImage4D(:,:,j,tf) = segImage;
    end
end
%% To generate Binary images for the segmenation 
% seg4D = make_nii(segImage4D);
% save_nii(seg4D,['seg_' ImageName]);
% seg = load_nii(['seg_' ImageName]);
% view_nii(seg);

