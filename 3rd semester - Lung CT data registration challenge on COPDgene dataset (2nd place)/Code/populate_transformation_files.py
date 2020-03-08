'''
    FILENAME: populate_transformation_files.py
    This file is used to populate the transformation files : Affine and BSpline
    which will be used to register the lung 3D CT Scans Inhale and Exhale.

    CREATED ON: 31st December 2019
    AUTHORS: Zohaib Salahuddin
             Abdullah Thabit
             Manju Kumar Basavaraj
'''

path_to_data_dir = "./"


def is_float(string):
  try:
    return float(string) and '.' in string  # True if string is a number contains a dot
  except ValueError:  # String is not a number
    return False


'''
    FUNCTION NAME : function_generate_transformation
    Function to Generate the Transformation File for Registration
    Inputs:
        filename: the affine transformation filename
        imageTypes: Dictionary containing information about image type parameters
        sampler: Dictionary containing information about optimizer type parameters
        interpolator_resampler: Dictionary containing informationa about interpolator
                                and resampler configuration
        imageComponents: Dictionary containing information about general image components
        configurations: Dictionary containing information about result configuration parameters
'''

def function_generate_transformation(filename,imageTypes,imageComponents,sampler,optimizer,interpolator_resampler,configurations):

    f = open(filename, "w")

    comment = "// ### AUTO-GENERATED FILE THROUGH PYTHON ### \n \n"
    f.write(comment)
    comment = " \n \n //  # Configuring the Input Image Parameters #  \n \n"
    f.write(comment)

    for key,values in imageTypes.items():
        if (str(values.split()[0]).isdigit() == True or is_float(str(values.split()[0]))):
            temp = ("(%s  %s) \n" % (key, values))
        else:
            temp = ("(%s  \"%s\") \n" % (key, values))
        f.write(temp)

    comment = " \n \n //  # Configuring the Registration Componenets Parameters #  \n \n"
    f.write(comment)

    for key,values in imageComponents.items():
        if (str(values.split()[0]).isdigit() == True or is_float(str(values.split()[0]))):
            temp = ("(%s  %s) \n" % (key, values))
        else:
            temp = ("(%s  \"%s\") \n" % (key, values))
        f.write(temp)

    comment = " \n \n //  # Configuring the Sampler Parameters #  \n \n"
    f.write(comment)

    for key,values in sampler.items():
        if (str(values.split()[0]).isdigit() == True or is_float(str(values.split()[0]))):
            temp = ("(%s  %s) \n" % (key, values))
        else:
            temp = ("(%s  \"%s\") \n" % (key, values))
        f.write(temp)

    comment = " \n \n //  # Configuring the Optimizer Parameters #  \n \n"
    f.write(comment)

    for key,values in optimizer.items():
        if (str(values.split()[0]).isdigit() == True or is_float(str(values.split()[0]))):
            temp = ("(%s  %s) \n" % (key, values))
        else:
            temp = ("(%s  \"%s\") \n" % (key, values))
        f.write(temp)

    comment = "  \n \n  //  # Configuring the Interpolator ReSampler Parameters #  \n \n"
    f.write(comment)

    for key, values in interpolator_resampler.items():
        if (str(values.split()[0]).isdigit() == True or is_float(str(values.split()[0]))):
            temp = ("(%s  %s) \n" % (key, values))
        else:
            temp = ("(%s  \"%s\") \n" % (key, values))
        f.write(temp)

    comment = " \n \n //  # Configuring the Result Configurations Parameters # \n \n"
    f.write(comment)

    for key,values in configurations.items():
        if (str(values.split()[0]).isdigit() == True or is_float(str(values.split()[0]))):
            temp = ("(%s  %s) \n" % (key, values))
        else:
            temp = ("(%s  \"%s\") \n" % (key, values))
        f.write(temp)

    f.close()
    print("Finished Writing Transformation File : ", filename)


############################# WRITING AFFINE TRANSFORMATION FILE ####################################
################ STEP 1: SET UP THE CONFIGURATION PARAMETERS            #############################
################ STEP 2: CALL THE "function_generate_transformation" FUNCTION #######################
affine_filename = path_to_data_dir + "affine_transform.txt"
# Filling up a dictionary with the Elastix File Parameter Options.

# options for Input Types
imageTypes ={}
imageTypes['FixedInternalImagePixelType'] = 'float'
imageTypes['FixedImageDimension'] = '3'
imageTypes['MovingInternalImagePixelType'] = 'float'
imageTypes['MovingImageDimension'] = '3'


# options for Registration Components
imageComponents = {}
imageComponents['Registration'] = 'MultiResolutionRegistration'
imageComponents['FixedImagePyramid'] = 'FixedRecursiveImagePyramid'
imageComponents['MovingImagePyramid'] = 'MovingRecursiveImagePyramid'
imageComponents['Interpolator'] = 'BSplineInterpolator'
imageComponents['Metric'] = 'AdvancedMattesMutualInformation'
imageComponents['Optimizer'] = 'AdaptiveStochasticGradientDescent'
imageComponents['ResampleInterpolator'] = 'FinalBSplineInterpolator'
imageComponents['Resampler'] = 'DefaultResampler'
imageComponents['Transform'] = 'AffineTransform'

# options for Pyramid
imageComponents['NumberOfResolutions'] = "6"
imageComponents['ImagePyramidSchedule'] = "16 16 16 8 8 8 4 4 4 2 2 2 1 1 1"

# options for Transform
imageComponents['AutomaticScalesEstimation'] = "true"
imageComponents['AutomaticTransformInitialization'] = "true"
imageComponents['HowToCombineTransforms'] = "Compose"

# options for ImageSampler
sampler= {}
sampler['ImageSampler'] = "RandomCoordinate"
sampler['NumberOfSpatialSamples'] = "5000"
sampler['NewSamplesEveryIteration'] = "true"
sampler['UseRandomSampleRegion'] = "false"
sampler['MaximumNumberOfSamplingAttempts'] = "5"

# options for Optimizer
optimizer = {}
optimizer['MaximumNumberOfIterations'] = "2000"
optimizer['AutomaticParameterEstimation'] = "true"
optimizer['UseAdaptiveStepSizes'] = "true"

# options for interpolator and resampler
interpolator_resampler={}
interpolator_resampler['BSplineInterpolationOrder'] = "1"
interpolator_resampler['FinalBSplineInterpolationOrder'] = "3"
interpolator_resampler['DefaultPixelValue'] = "0"



# options for saving the result
configurations ={}
configurations['WriteTransformParametersEachIteration'] = "false"
configurations['WriteTransformParametersEachResolution'] = "true"
configurations['WriteResultImageAfterEachResolution'] = "false"
configurations['WriteResultImage'] = "false"
configurations['ResultImageFormat'] = "nii.gz"
configurations['ShowExactMetricValue'] = "false"
configurations['ErodeMask'] = "false"
configurations['UseDirectionCosines'] = "true"


function_generate_transformation(affine_filename,imageTypes,imageComponents,sampler,optimizer,interpolator_resampler,configurations)


############################# WRITING BSPLINE TRANSFORMATION FILE ####################################
################ STEP 1: SET UP THE CONFIGURATION PARAMETERS            #############################
################ STEP 2: CALL THE "function_generate_transformation" FUNCTION #######################

bspline_filename = path_to_data_dir + "bspline_transform.txt"

# Filling up a dictionary with the Elastix File Parameter Options.

# options for Input Types
imageTypes = {}
imageTypes['FixedInternalImagePixelType'] = 'float'
imageTypes['FixedImageDimension'] = '3'
imageTypes['MovingInternalImagePixelType'] = 'float'
imageTypes['MovingImageDimension'] = '3'

# options for Registration Components
imageComponents = {}
imageComponents['Registration'] = 'MultiResolutionRegistration'
imageComponents['FixedImagePyramid'] = 'FixedRecursiveImagePyramid'
imageComponents['MovingImagePyramid'] = 'MovingRecursiveImagePyramid'
imageComponents['Interpolator'] = 'BSplineInterpolator'
imageComponents['Metric'] = 'AdvancedMattesMutualInformation'
imageComponents['Optimizer'] = 'AdaptiveStochasticGradientDescent'
imageComponents['ResampleInterpolator'] = 'FinalBSplineInterpolator'
imageComponents['Resampler'] = 'DefaultResampler'
imageComponents['Transform'] = 'BSplineTransform'

# options for Pyramid
imageComponents['NumberOfResolutions'] = "6"
imageComponents['ImagePyramidSchedule'] = "16 16 16 8 8 8 4 4 4 2 2 2 1 1 1"

# options for Transform
imageComponents['FinalGridSpacingInPhysicalUnits'] = "20.0 20.0 20.0"
imageComponents['GridSpacingSchedule'] = "16.0 8.0 8.0 4.0 2.0 1.0"
imageComponents['HowToCombineTransforms'] = "Compose"

# options for ImageSampler
sampler = {}
sampler['ImageSampler'] = "RandomCoordinate"
sampler['NumberOfSpatialSamples'] = "5000"
sampler['NewSamplesEveryIteration'] = "true"
sampler['UseRandomSampleRegion'] = "false"
sampler['SampleRegionSize'] = "50.0 50.0 50.0"
sampler['MaximumNumberOfSamplingAttempts'] = "50"

# options for Optimizer
optimizer = {}
optimizer['MaximumNumberOfIterations'] = "2000"
optimizer['AutomaticParameterEstimation'] = "true"
optimizer['UseAdaptiveStepSizes'] = "true"

# options for interpolator and resampler
interpolator_resampler = {}
interpolator_resampler['BSplineInterpolationOrder'] = "1"
interpolator_resampler['FinalBSplineInterpolationOrder'] = "3"
interpolator_resampler['DefaultPixelValue'] = "0"

# options for saving the result
configurations = {}
configurations['WriteTransformParametersEachIteration'] = "false"
configurations['WriteTransformParametersEachResolution'] = "true"
configurations['WriteResultImageAfterEachResolution'] = "false"
configurations['WritePyramidImagesAfterEachResolution'] = "false"
configurations['WriteResultImage'] = "true"
configurations['ResultImageFormat'] = "nii.gz"
configurations['ShowExactMetricValue'] = "false"
configurations['ErodeMask'] = "false"
configurations['UseDirectionCosines'] = "true"

function_generate_transformation(bspline_filename, imageTypes, imageComponents, sampler, optimizer, interpolator_resampler,
                         configurations)



