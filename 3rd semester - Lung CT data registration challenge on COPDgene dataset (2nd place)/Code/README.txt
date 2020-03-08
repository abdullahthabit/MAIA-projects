


To Run the codes for elastix you have to first:
	
	1) run the python file populate_transformation_files.py to generate the transformation files:
		- affine_transform.txt
		- bspline_transform.txt
	
	2) convert your dataset images to nifti format ".nii.gz" before running the main code (we used itk-snap)

	2) Run main.py with the "path_to_data_dir" parameter set to the path of your data folder:
		- for example" path_to_data_dir = "challengeDay/"

	3) the generated registeration output will be saved in a folder called "ealstix_out" inside each sample volume data folder.


To Run the codes for voxelMorph:
	
	1) please click on this link to go to our drive folder: 
		https://drive.google.com/drive/folders/1_F0pTtk9PpdxRVTXw9NLiI7WEOsQ1tlM?usp=sharing

	2) please add the folder shared "MIRA_voxelMorph_Abdullah_Zohaib" to your drive by right clicking on it and choosing "add to my drive"

	3) Navigate to the notebook voxelMorph.ipynp and run it



Please if you have any issues running the codes or you have questions, do not hesitate to contact us.


