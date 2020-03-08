'''
    FILENAME: register_lung_cases.py
    This file is used to apply registration between the two cases
    inhale and exhale and calculate the TRE after the registration
    between the two cases. The tre for each case is stored in a notepad file.

    CREATED ON: 31st December 2019
    AUTHORS: Zohaib Salahuddin
             Abdullah Thabit
             Manju Kumar Basavaraj
'''

import os
import xlsxwriter
import sh
import pandas as pd
import time
from utils import *

# work book initializations
workbook = xlsxwriter.Workbook('./TRE_results.xlsx')
worksheet = workbook.add_worksheet()
row = 0
column = 0

# Set this path to the file containing all the images
path_to_data_dir = "challengeDay/"

numImage = []
meanTRE_before = []
meanTRE_after = []
stdTRE_before = []
stdTRE_after = []

testing = True

for i in range(5, 7):
    row = row + 1

    # Set this number to the case you want to evaluate (Available Options - 1 to 4)
    case_number = i
    path_to_data_dir = "challengeDay/copd{}/".format(i)
    # Setting up the input parameters
    param = {}

    # Input Images
    param['exhale'] = path_to_data_dir + 'copd' + str(case_number) + '_eBHCT.nii.gz'
    param['inhale'] = path_to_data_dir + 'copd' + str(case_number) + '_iBHCT.nii.gz'

    # Segmented exhale and inhale Images
    exhale_seg = segment3DLungs(param['exhale'])
    param['seg_exhale'] = "{}/seg_copd{}_eBHCT.nii.gz".format(path_to_data_dir, case_number)
    nib.save(exhale_seg, param['seg_exhale'])

    inhale_seg = segment3DLungs(param['inhale'])
    param['seg_inhale'] = "{}/seg_copd{}_iBHCT.nii.gz".format(path_to_data_dir, case_number)
    nib.save(inhale_seg, param['seg_inhale'])

    # Landmark Images Inhale and Exhale
    param['landmarks_inhale'] = path_to_data_dir + 'copd' + str(case_number) + '_300_iBH_xyz_r1.txt'

    if not testing:
        param['landmarks_exhale'] = path_to_data_dir + 'copd' + str(case_number) + '_300_eBH_xyz_r1.txt'

    param['landmarks_inhale_elastix'] = path_to_data_dir + 'copd' + str(case_number) + '_300_iBH_xyz_r2.txt'

    if not testing:
        param['landmarks_exhale_elastix'] = path_to_data_dir + 'copd' + str(case_number) + '_300_eBH_xyz_r2.txt'

    outputFilePath = param['landmarks_inhale_elastix']
    indexer = sh.Command("touch")
    indexer(outputFilePath.split(" "))
    inputFilePath = param['landmarks_inhale']
    input_paramFile = open(inputFilePath)
    output_paramFile = open(outputFilePath, 'w')
    output_paramFile.write(input_paramFile.read())
    input_paramFile.close()
    output_paramFile.close()
    line_prepender(outputFilePath, '300')

    if not testing:
        outputFilePath = param['landmarks_exhale_elastix']
        indexer = sh.Command("touch")
        indexer(outputFilePath.split(" "))
        inputFilePath = param['landmarks_exhale']
        input_paramFile = open(inputFilePath)
        output_paramFile = open(outputFilePath, 'w')
        output_paramFile.write(input_paramFile.read())
        input_paramFile.close()
        output_paramFile.close()
        line_prepender(outputFilePath, '300')


    # Loading the inhale and exhale landmarks
    landmarks_fixed = np.loadtxt(param['landmarks_inhale'])
    if not testing:
        landmarks_moving = np.loadtxt(param['landmarks_exhale'])

    # Getting the voxel spacing in the image
    voxel_spacing = nib.load(param['inhale']).header.get_zooms()
    print("voxel spacing: ", voxel_spacing)

    if not testing:
        # Calculating the TRE before registration
        mean_tre , std_tre = calculateTRE(landmarks_fixed, landmarks_moving, voxel_spacing)
        print('mean and std of tre before doing registration is: ', mean_tre ," ", std_tre )

        # store TRE results in a list
        meanTRE_before.append(mean_tre)
        stdTRE_before.append(std_tre)

    print("Starting Registration:")

    # Path to transformation parameters
    affine = "./affine_transform.txt"
    bspline = "./bspline_transform.txt"

    # Path to the result directory
    result_dir = path_to_data_dir + "elastix_out"

    # Creating the Registration Result Directory
    command = result_dir
    if not (os.path.exists(command)):
        indexer = sh.Command("mkdir")
        indexer(command.split(" "))

    command = result_dir + "/" + "registered_moving"
    if not (os.path.exists(command)):
        indexer = sh.Command("mkdir")
        indexer(command.split(" "))

    command = result_dir + "/" + "registered_landmarks"
    if not (os.path.exists(command)):
        indexer = sh.Command("mkdir")
        indexer(command.split(" "))

    # Registration Parameters
    # Fixed
    fixed = param['inhale']
    fixed_mask = param['seg_inhale']

    # Moving
    moving = param['exhale']
    moving_mask = param['seg_exhale']

    # Store Dir
    store_dir = result_dir

    # First Phase of registration (no masks)
    print("Applying Elastix...")
    since = time.time()
    # Running Elastix
    command = "-f " + fixed + " -fMask " + fixed_mask + " -m " + moving + " -mMask " + moving_mask \
              + " -p " + affine + " -p " + bspline + " -out " + store_dir

    indexer = sh.Command("elastix")
    indexer(command.split(" "))

    # calculate time elaspsed
    time_elapsed = time.time() - since
    print('Elastix 1st time took {:.0f}m {:.0f}s'.format(time_elapsed // 60, time_elapsed % 60))

    print("Applying Transformix..")
    # Running Transformix on Segmentation and Moving Images
    command = "-in " + moving + " -out " + result_dir + "/registered_moving" + " -tp " \
              + "{}/TransformParameters.1.txt".format(store_dir)
    # os.system(command)
    indexer = sh.Command("transformix")
    indexer(command.split(" "))

    command = "-def " + param['landmarks_inhale_elastix'] + " -out " + result_dir + "/registered_landmarks" + " -tp " \
              + "{}/TransformParameters.1.txt".format(store_dir)
    # os.system(command)
    indexer = sh.Command("transformix")
    indexer(command.split(" "))

    # Transformed Fixed Landmark points
    param['transformed_landmarks'] = result_dir + "/registered_landmarks" + "/outputpoints.txt"
    # Running Transformix to transform landmarks from fixed space to moving space.
    transformed_landmarks = get_landmarks_from_elastix_file(param['transformed_landmarks'])

    np.savetxt("{}/registered_landmarks/transformed_points.txt".format(result_dir), transformed_landmarks)

    if not testing:
        print("##### AFTER TRANSFORMATION ############")
        mean_tre, std_tre = calculateTRE(transformed_landmarks, landmarks_moving, voxel_spacing)

        print('mean and std of tre after doing registration is: ', mean_tre, " ", std_tre)

        meanTRE_after.append(mean_tre)
        stdTRE_after.append(std_tre)

        imageName = 'copd{}'.format(case_number)
        numImage.append(imageName)

        column = 3
        worksheet.write(row, column, str(mean_tre))
        column = 4
        worksheet.write(row, column, str(std_tre))
    print("---------------------------------------------------------------")

# we use PANDAS to describe data :)
if not testing:
    metrics_df = {'ImageName': numImage, 'meanTRE_before': meanTRE_before, 'meanTRE_after': meanTRE_after, 'stdTRE_before': stdTRE_before, 'stdTRE_after': stdTRE_after}
    m = pd.DataFrame(metrics_df, columns=['ImageName', 'meanTRE_before', 'meanTRE_after', 'stdTRE_before', 'stdTRE_after'])

    result_tre_path = 'TRE_results.csv'
    m.to_csv(result_tre_path)

    print(m)
print("DONE!!")

