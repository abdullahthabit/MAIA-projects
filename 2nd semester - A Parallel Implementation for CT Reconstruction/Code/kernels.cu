#include "kernels.h"
#include <iostream>
#include <cmath>
#include <iostream>
#include <sys/time.h>
#include <unistd.h>
#include "get_micro_second.h"
#include <cstdlib>


// Includes CUDA
#include <cuda_runtime.h>
#include <cuda_profiler_api.h>
#include <cufft.h>


// 2D float texture
texture<float, cudaTextureType2D, cudaReadModeElementType> texRef;



/*
 * Function Name : sinogram_serial
 ***************************************************************************
 * This fucntion takes in the filtered sinogram and backprojects it. BackProjection
 * is calculated using the formula of inverse radon transform.
 ***************************************************************************
 * angles: int : total number of angles in the sinogram
 * sensors : int : number of sensors in the sinogram.
 * theta: float *: the values of theta at which the image projections are required
 		   in the sinogram
 * x_min: float : this is minimum pixel distance in the x direction
 * y_min: float : this is the minimum pixel distance in the y direction
 * r_min: float : this is the minimum pixel distance along the diagonal direction
 * dx: float : the x pixel width
 * dy: float: the y pixel width
 * dr: float : the pixel diagonal length
 * Width: int : the width of the original image to be reconstructed
 * Height: int: the height of the original image to be reconstructed
 * img: float *: the image whose sinogram needs to be calculated
 * sinogram_output: float *: the sinogram that has been calculated
 ***************************************************************************
 * Returns void
 */

void sinogram_serial(float * img,float* sinogram_output, float dx, float x_min, float dy, float y_min, int sensors, float dr, float r_min, int angles, float* theta,int Width,int Height)
{
    for (int sensor_no=0 ; sensor_no < sensors ; sensor_no++)
    {
    	for (int angle_no=0; angle_no <angles ; angle_no++)
    	{

		    if (sensor_no < sensors && angle_no < angles) 
		    {
		        float sum = 0;
		        float r = sensor_no * dr + r_min;
		        int ind_x,ind_y;
		        float d00,d11,d10,d01;
		        float a,b;
		        float result_temp1,result_temp2;
		        for (int z_idx = 0; z_idx < sensors; z_idx++) 
		        {
		            float z = z_idx * dr + r_min;


		            // Transform coordinates------from r, theta to x, t-----------------------------------------------
		            float r_real = (r * cosf(theta[angle_no]) + z * sinf(theta[angle_no]) - x_min)/dx + 0.5f;
		            float z_real = (z * cosf(theta[angle_no]) - r * sinf(theta[angle_no]) - y_min)/dy + 0.5f;

            		//BILINEAR INTERPOLATION START
	               if ((r_real<Width)&&(z_real<Height)) 
	               {

	     

	                   ind_x = floor(r_real);
	                   a      = r_real-ind_x;

	                   ind_y = floor(z_real);
	                   b      = z_real-ind_y;

	                   if (((ind_x)   < Width)&&((ind_y)   < Height))    d00 = img[ind_y*Height+ind_x];   else d00 = 0;     
	                   if (((ind_x+1) < Width)&&((ind_y)   < Height))    d10 = img[ind_y*Height+ind_x+1]; else d10 = 0;      
	                   if (((ind_x)   < Width)&&((ind_y+1) < Height))    d01 = img[(ind_y+1)*Height+ind_x];   else d01 = 0; 
	                   if (((ind_x+1) < Width)&&((ind_y+1) < Height))    d11 = img[(ind_y+1)*Height+ind_x+1]; else d11 = 0;

	                    result_temp1 = a * d10+ (-d00 * a + d00);
	      

	                    result_temp2 = a * d11 + (-d01 * a + d01);
	                    sum += b * result_temp2 + (-result_temp1 * b + result_temp1);
	      
	                }
           
            
        		}
        		sinogram_output[angle_no*sensors + sensor_no] = sum;

			}
		}
	}
}


/*
 * Kernel Name : sinogram_kernel_tex
 ***************************************************************************
 * This kernel takes in the filtered sinogram and backprojects it. BackProjection
 * is calculated using the formula of inverse radon transform.
 ***************************************************************************
 * angles: int : total number of angles in the sinogram
 * sensors : int : number of sensors in the sinogram.
 * theta: float *: the values of theta at which the image projections are required
 		   in the sinogram
 * x_min: float : this is minimum pixel distance in the x direction
 * y_min: float : this is the minimum pixel distance in the y direction
 * r_min: float : this is the minimum pixel distance along the diagonal direction
 * dx: float : the x pixel width
 * dy: float: the y pixel width
 * dr: float : the pixel diagonal length
 * Width: int : the width of the original image to be reconstructed
 * Height: int: the height of the original image to be reconstructed
 * img: float *: the image whose sinogram needs to be calculated
 * sinogram_output: float *: the sinogram that has been calculated
 ***************************************************************************
 * Returns void
 */

__global__ void sinogram_kernel_tex(float * img,float* sinogram_output, float dx, float x_min, float dy, float y_min, int sensors, float dr, float r_min, int angles, float* theta,int Width,int Height)
{
    unsigned int sensor_no = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int angle_no = blockIdx.y * blockDim.y + threadIdx.y;

    if (sensor_no < sensors && angle_no < angles) 
    {
        float sum = 0;
        float r = sensor_no * dr + r_min;
        for (int z_idx = 0; z_idx < sensors; z_idx++) 
        {
            float z = z_idx * dr + r_min;


            // Transform coordinates------from r, theta to x, t-----------------------------------------------
            float r_real = (r * cosf(theta[angle_no]) + z * sinf(theta[angle_no]) - x_min)/dx + 0.5f;
            float z_real = (z * cosf(theta[angle_no]) - r * sinf(theta[angle_no]) - y_min)/dy + 0.5f;

            sum += tex2D(texRef, r_real, z_real);
      

        }

        sinogram_output[angle_no*sensors + sensor_no] = sum;
    }
}


/*
 * Kernel Name : sinogram_kernel
 ***************************************************************************
 * This kernel takes in the filtered sinogram and backprojects it. BackProjection
 * is calculated using the formula of inverse radon transform.
 ***************************************************************************
 * angles: int : total number of angles in the sinogram
 * sensors : int : number of sensors in the sinogram.
 * theta: float *: the values of theta at which the image projections are required
 		   in the sinogram
 * x_min: float : this is minimum pixel distance in the x direction
 * y_min: float : this is the minimum pixel distance in the y direction
 * r_min: float : this is the minimum pixel distance along the diagonal direction
 * dx: float : the x pixel width
 * dy: float: the y pixel width
 * dr: float : the pixel diagonal length
 * Width: int : the width of the original image to be reconstructed
 * Height: int: the height of the original image to be reconstructed
 * img: float *: the image whose sinogram needs to be calculated
 * sinogram_output: float *: the sinogram that has been calculated
 ***************************************************************************
 * Returns void
 */

__global__ void sinogram_kernel(float * img,float* sinogram_output, float dx, float x_min, float dy, float y_min, int sensors, float dr, float r_min, int angles, float* theta,int Width,int Height)
{
    unsigned int sensor_no = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int angle_no = blockIdx.y * blockDim.y + threadIdx.y;

    if (sensor_no < sensors && angle_no < angles) 
    {
        float sum = 0;
        float r = sensor_no * dr + r_min;
        int ind_x,ind_y;
        float d00,d11,d10,d01;
        float a,b;
        float result_temp1,result_temp2;
        for (int z_idx = 0; z_idx < sensors; z_idx++) 
        {
            float z = z_idx * dr + r_min;


            // Transform coordinates------from r, theta to x, t-----------------------------------------------
            float r_real = (r * cosf(theta[angle_no]) + z * sinf(theta[angle_no]) - x_min)/dx + 0.5f;
            float z_real = (z * cosf(theta[angle_no]) - r * sinf(theta[angle_no]) - y_min)/dy + 0.5f;
            
            //BILINEAR INTERPOLATION START
               if ((r_real<Width)&&(z_real<Height)) 
               {

     

                   ind_x = floor(r_real);
                   a      = r_real-ind_x;

                   ind_y = floor(z_real);
                   b      = z_real-ind_y;

                   if (((ind_x)   < Width)&&((ind_y)   < Height))    d00 = img[ind_y*Height+ind_x];   else d00 = 0;     
                   if (((ind_x+1) < Width)&&((ind_y)   < Height))    d10 = img[ind_y*Height+ind_x+1]; else d10 = 0;      
                   if (((ind_x)   < Width)&&((ind_y+1) < Height))    d01 = img[(ind_y+1)*Height+ind_x];   else d01 = 0; 
                   if (((ind_x+1) < Width)&&((ind_y+1) < Height))    d11 = img[(ind_y+1)*Height+ind_x+1]; else d11 = 0;

                    result_temp1 = a * d10+ (-d00 * a + d00);
      

                    result_temp2 = a * d11 + (-d01 * a + d01);
                    sum += b * result_temp2 + (-result_temp1 * b + result_temp1);
      
                }
           
            //  BILINEAR INTERPOLATION END
            
        }

        sinogram_output[angle_no*sensors + sensor_no] = sum;
    }
}


/*
 * Function Name : sinogram
 ***************************************************************************
 * This function calls the sinogram kernel and returns the sinogram calculated
 * This function is also responsible for memory allocation and resource freeing
 * for calling the concerned kernel
 ***************************************************************************
 * angles: int : total number of angles in the sinogram
 * sensors : int : number of sensors in the sinogram.
 * theta: float *: the values of theta at which the image projections are required
 		   in the sinogram
 * x_min: float : this is minimum pixel distance in the x direction
 * y_min: float : this is the minimum pixel distance in the y direction
 * r_min: float : this is the minimum pixel distance along the diagonal direction
 * dx: float : the x pixel width
 * dy: float: the y pixel width
 * dr: float : the pixel diagonal length
 * Width: int : the width of the original image to be reconstructed
 * Height: int: the height of the original image to be reconstructed
 * img: float *: the image whose sinogram needs to be calculated
 * h_img_out_t: float **: the sinogram output is returned
 ***************************************************************************
 * Returns void
 */


void sinogram (int angles, float * theta, int Width, int Height, float * img , int sensors,float dx,float dy, float dr,float x_min,float y_min,float r_min, float **h_img_out_t)
{
    //
    // Declare the variables for measuring elapsed time
    double sTime;
    double eTime;
    
    float* device_angles,*device_img;
    //Allocating space 
    cudaMalloc(&device_angles, angles * sizeof(float));
    cudaMalloc(&device_img, Width * Height * sizeof(float));

    sTime = getMicroSecond();

    // Copy host to device
    cudaMemcpy(device_angles, theta, angles * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(device_img, img, Width * Height * sizeof(float), cudaMemcpyHostToDevice);

    eTime = getMicroSecond();
    double SinogramTransferTime = eTime - sTime;

    // Allocate result of sinogram kernel in device memory
    float* device_result;
    cudaMalloc(&device_result, sensors * angles * sizeof(float));

    // Kernel Initializations
    dim3 dimBlock(16, 16, 1); // 256 threads per block
    dim3 dimGrid((sensors + dimBlock.x - 1) / dimBlock.x, (angles + dimBlock.y - 1) / dimBlock.y, 1); // rounding of to the next int according to image dimensions
    sTime = getMicroSecond();

    // Calling the Kernel
    sinogram_kernel<<<dimGrid, dimBlock>>>(device_img,device_result, dx, x_min, dy, y_min, sensors, dr, r_min, angles, device_angles,Width,Height);

    eTime = getMicroSecond();

    double singogramKernelTime = eTime - sTime;
    std::cout <<"Sinogram Kernel Time = "<< singogramKernelTime * 1e3 << "[ms]" <<std::endl;

    // Returning the image back
    float *h_img_out;
    h_img_out = (float *)malloc(sensors * angles * sizeof(float));

    /*
    sTime = getMicroSecond();

    sinogram_serial(img, h_img_out,  dx,  x_min,  dy, y_min, sensors, dr, r_min,  angles, theta, Width, Height);

    eTime = getMicroSecond();
    SinogramTransferTime += ( eTime - sTime );
    std::cout <<"Sinogram Serial time is = "<< SinogramTransferTime * 1e3 << "[ms]" <<std::endl;
    */
    
    sTime = getMicroSecond();

    // Copy Device to Host
    cudaMemcpy(h_img_out, device_result, sensors * angles * sizeof(float), cudaMemcpyDeviceToHost);

    eTime = getMicroSecond();
    SinogramTransferTime += ( eTime - sTime );
    std::cout <<"Sinogram Data Transfer Time = "<< SinogramTransferTime * 1e3 << "[ms]" <<std::endl;
    
    for( unsigned int i = 0; i < angles; i++ ) 
    {
    	for( unsigned int j = 0; j < sensors; j++ )
    	{
        	unsigned int pixelPos = i * sensors + j;
        	(*h_img_out_t)[pixelPos] = (h_img_out)[pixelPos];
    	}
    }
    // Free device memory
    cudaFree(device_result);

}

/*
 * Function Name : sinogram_tex
 ***************************************************************************
 * This function calls the sinogram kernel and returns the sinogram calculated
 * This function is also responsible for memory allocation and resource freeing
 * for calling the concerned kernel
 ***************************************************************************
 * angles: int : total number of angles in the sinogram
 * sensors : int : number of sensors in the sinogram.
 * theta: float *: the values of theta at which the image projections are required
 		   in the sinogram
 * x_min: float : this is minimum pixel distance in the x direction
 * y_min: float : this is the minimum pixel distance in the y direction
 * r_min: float : this is the minimum pixel distance along the diagonal direction
 * dx: float : the x pixel width
 * dy: float: the y pixel width
 * dr: float : the pixel diagonal length
 * Width: int : the width of the original image to be reconstructed
 * Height: int: the height of the original image to be reconstructed
 * img: float *: the image whose sinogram needs to be calculated
 * h_img_out_t: float **: the sinogram output is returned
 ***************************************************************************
 * Returns void
 */


void sinogram_tex(int angles, float * theta, int Width, int Height, float * img , int sensors,float dx,float dy, float dr,float x_min,float y_min,float r_min, float **h_img_out_t)
{
    //
    // Declare the variables for measuring elapsed time
    double sTime;
    double eTime;
    
    float* device_angles,*device_img;
    //Allocating space 
    cudaMalloc(&device_angles, angles * sizeof(float));
    cudaMalloc(&device_img, Width * Height * sizeof(float));

    // Allocate CUDA array in device memory
    cudaChannelFormatDesc channelDesc = cudaCreateChannelDesc(32, 0, 0, 0, cudaChannelFormatKindFloat);
    cudaArray* cuArray;
    cudaMallocArray(&cuArray, &channelDesc, Width, Height);

    // Copy to device memory some data located at address h_img in host memory 
    cudaMemcpyToArray(cuArray, 0, 0, img, Width * Height * sizeof(float), cudaMemcpyHostToDevice);

    // Set texture reference parameters
    texRef.addressMode[0] = cudaAddressModeBorder;
    texRef.addressMode[1] = cudaAddressModeBorder;
    texRef.filterMode = cudaFilterModeLinear;
    texRef.normalized = false;

    // Bind the array to the texture reference
    cudaBindTextureToArray(texRef, cuArray, channelDesc);

    sTime = getMicroSecond();

    // Copy host to device
    cudaMemcpy(device_angles, theta, angles * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(device_img, img, Width * Height * sizeof(float), cudaMemcpyHostToDevice);

    eTime = getMicroSecond();
    double SinogramTransferTime = eTime - sTime;

    // Allocate result of sinogram kernel in device memory
    float* device_result;
    cudaMalloc(&device_result, sensors * angles * sizeof(float));

    // Kernel Initializations
    dim3 dimBlock(16, 16, 1); // 256 threads per block
    dim3 dimGrid((sensors + dimBlock.x - 1) / dimBlock.x, (angles + dimBlock.y - 1) / dimBlock.y, 1); // rounding of to the next int according to image dimensions
    sTime = getMicroSecond();

    // Calling the Kernel
    sinogram_kernel<<<dimGrid, dimBlock>>>(device_img,device_result, dx, x_min, dy, y_min, sensors, dr, r_min, angles, device_angles,Width,Height);

    eTime = getMicroSecond();

    double singogramKernelTime = eTime - sTime;
    std::cout <<"Sinogram Kernel Time = "<< singogramKernelTime * 1e3 << "[ms]" <<std::endl;

    // Returning the image back
    float *h_img_out;
    h_img_out = (float *)malloc(sensors * angles * sizeof(float));

    sTime = getMicroSecond();

    // Copy Device to Host
    cudaMemcpy(h_img_out, device_result, sensors * angles * sizeof(float), cudaMemcpyDeviceToHost);

    eTime = getMicroSecond();
    SinogramTransferTime += ( eTime - sTime );
    std::cout <<"Sinogram Data Transfer Time = "<< SinogramTransferTime * 1e3 << "[ms]" <<std::endl;

    for( unsigned int i = 0; i < angles; i++ ) 
    {
    	for( unsigned int j = 0; j < sensors; j++ )
    	{
        	unsigned int pixelPos = i * sensors + j;
        	(*h_img_out_t)[pixelPos] = (h_img_out)[pixelPos];
    	}
    }
    // Free device memory
    cudaFree(device_result);

}


/*
 * Kernel Name : filterationkernel
 ***************************************************************************
 * This kernel takes in the fft of the sinogram and multiplies with the
 * ramlak filter. This is intended to suppress the low frequencies and intensify 
 * the high frequency content.
 ***************************************************************************
 * filter_subject: cufftComplex* : This the fft of the sinogram that needs to be
 				   filtered.
 * sensors : int : number of sensors in the sinogram.
 * angles : int : number of angles in the sinogram.
 ***************************************************************************
 * Returns void
 */

__global__ void filterationkernel(cufftComplex* filter_subject, int sensors, int angles)
{
    unsigned int sensor_no = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int angle_no = blockIdx.y * blockDim.y + threadIdx.y;

    if (sensor_no < sensors && angle_no < angles)
    {
        filter_subject[sensor_no + sensors*angle_no].x *= ((sensor_no< sensors - sensor_no) ? sensor_no :(sensors - sensor_no)) / (float)sensors;
        filter_subject[sensor_no + sensors*angle_no].y *= ((sensor_no< sensors - sensor_no) ? sensor_no :(sensors - sensor_no)) / (float)sensors;
    }
}



/*
 * Kernel Name : inversefft_real
 ***************************************************************************
 * This kernel takes in the inverse fft of the filtered sinogram and returns
 * only the real part of the inverse fft.
 ***************************************************************************
 * filter_subject: cufftComplex* : This the fft of the sinogram that needs to be
 				   filtered.
 * sensors : int : number of sensors in the sinogram.
 * angles : int : number of angles in the sinogram.
 ***************************************************************************
 * Returns void
 */

 __global__ void inversefft_real(float* real_ifft, cufftComplex* ifft, int len_ifft)
{
    unsigned int index = blockIdx.x * blockDim.x + threadIdx.x;
    if (index < len_ifft)  
    {
    	real_ifft[index] = ifft[index].x;
   	}
}

/*
 * Kernel Name : backprojection_kernel
 ***************************************************************************
 * This kernel takes in the filtered sinogram and backprojects it. BackProjection
 * is calculated using the formula of inverse radon transform.
 ***************************************************************************
 * angles: int : total number of angles in the sinogram
 * sensors : int : number of sensors in the sinogram.
 * theta: float *: the total number of thetas used.
 * x_min: float : this is minimum pixel distance in the x direction
 * y_min: float : this is the minimum pixel distance in the y direction
 * r_min: float : this is the minimum pixel distance along the diagonal direction
 * dx: float : the x pixel width
 * dy: float: the y pixel width
 * dr: float : the pixel diagonal length
 * Width: int : the width of the original image to be reconstructed
 * Height: int: the height of the original image to be reconstructed
 * filtered_sinogram: float *: filtered sinogram of the image
 * output_recon: float *: this is the reconstructed image that is to be used
 ***************************************************************************
 * Returns void
 */

 __global__ void backprojection_kernel(int angles,int sensors, float *theta,float x_min, float dx, int Width,float y_min, float dy, int Height,float r_min, float dr, float *output_recon,float *filtered_sinogram)
{
    unsigned int x_index = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int y_index = blockIdx.y * blockDim.y + threadIdx.y;

    if (x_index < Width && y_index < Height)
    {
        float x, y, unscaled_r;
        float sum = 0;
        int sensor_index;

        x = x_min + x_index * dx;
        y = y_min + y_index * dy;

        for (int theta_idx = 0; theta_idx < angles; theta_idx++) 
        {
            unscaled_r = x*cosf(theta[theta_idx] * M_PI / 180.0f) + y*sinf(theta[theta_idx] * M_PI / 180.0f);
            sensor_index = (unscaled_r - r_min) / dr ; 
            sum +=  filtered_sinogram[theta_idx*sensors + sensor_index];
        }
        output_recon[x_index + Width * y_index] = sum;
    }
}






/*
 * Function Name : backProjection
 ***************************************************************************
 * This function calls the sinogram kernel and returns the sinogram calculated
 * This function is also responsible for memory allocation and resource freeing
 * for calling the concerned kernel
 ***************************************************************************
 * angles: int : total number of angles in the sinogram
 * sensors : int : number of sensors in the sinogram.
 * theta: float *: the values of theta at which the image projections are required
 		   in the sinogram
 * x_min: float : this is minimum pixel distance in the x direction
 * y_min: float : this is the minimum pixel distance in the y direction
 * r_min: float : this is the minimum pixel distance along the diagonal direction
 * dx: float : the x pixel width
 * dy: float: the y pixel width
 * dr: float : the pixel diagonal length
 * Width: int : the width of the original image to be reconstructed
 * Height: int: the height of the original image to be reconstructed
 * sinogram_image: float *: the sinogram whose output needs to be calculated
 * reconstructed_out: float **: the reconstructed image is returned 
 * filter_out: float **: Output of the filter that is to be used
 ***************************************************************************
 * Returns void
 */

int backProjection (float ** filter_out ,float * sinogram_image, int angles, float * theta, int Width, int Height, int sensors,float dx,float dy, float dr,float x_min,float y_min,float r_min, float **reconstructed_out)
{   

    // Declare the variables for measuring elapsed time
    double sTime;
    double eTime;

    

/********************************************* FILTERATION STARTS ************************************************************/
    // Declaring the cufftComplex Variable on the Host side + fft_input variable of the image.
    cufftComplex* fft_input;
    fft_input = (cufftComplex *)malloc(sizeof(cufftComplex) * angles * sensors);
    float *filtered_result;
    filtered_result = (float*)malloc(angles*sensors*sizeof(float));

   	for( unsigned int i = 0; i < angles; i++ ) 
    {
        for( unsigned int j = 0; j < sensors; j++ ) 
        {
           unsigned int pixelPos = i * sensors + j;
           fft_input[pixelPos].x = sinogram_image[pixelPos];
           fft_input[pixelPos].y = sinogram_image[pixelPos];

        }
    }
  

     // Allocate space on the GLOBAL memory for theta and the filtered image
    sTime = getMicroSecond();
    float *device_theta, *device_filtered;
    cudaMalloc(&device_theta, angles * sizeof(float));
    cudaMalloc(&device_filtered, angles * sensors * sizeof(float));
    cudaMemcpy(device_theta, theta, angles * sizeof(float), cudaMemcpyHostToDevice);
    eTime = getMicroSecond();
    double BackProjectionTransferTime = eTime - sTime;


 /************************************** FFT OF THE SINOGRAM *********************/
    // FFT initialization to contain the fft of the sinogram
    cufftComplex* device_fft;
    cudaMalloc((void **)&device_fft, sizeof(cufftComplex) * angles * sensors);


    // Copy the image sinogram to the fft
    sTime = getMicroSecond();
    cudaMemcpy(device_fft, fft_input, sizeof(cufftComplex)* angles * sensors, cudaMemcpyHostToDevice);
    eTime = getMicroSecond();
    double filteringTransferTime = eTime - sTime;

    // cufftHandle is used so that the configuration of the fft is used again and again
    // This reduces the overhead time
    cufftHandle plan;
    cufftPlan1d(&plan, sensors, CUFFT_C2C, angles);

    // Execute FFT - Complex input, Complex output. We are overriding the input with the fft result
    cufftExecC2C(plan, device_fft, device_fft, CUFFT_FORWARD);


/***** FILTERATION OF THE SINOGRAM FFT WITH RAMLAK FILTER ***********************/
    // Now Ramp Filter the FFT
    dim3 dimBlockRF(16, 16, 1); // 256 Threads
    // rounding of to the next int according to image dimensions
    dim3 dimGridRF((sensors + dimBlockRF.x - 1) / dimBlockRF.x, 
        (angles + dimBlockRF.y - 1) / dimBlockRF.y, 1);

    sTime = getMicroSecond();
    filterationkernel << <dimGridRF, dimBlockRF >> >(device_fft, sensors, angles);
    eTime = getMicroSecond();
    double FilteringKernelTime = eTime - sTime;


/******************************** INVERSE FFT *********************************/
	cufftExecC2C(plan, device_fft, device_fft, CUFFT_INVERSE);



/****************************** REAL PART OF THE FFT RESULT ******************/
    // Write the real part of output as the ramp filtered sinogram
    int thdsPerBlk = 256;
    int blksPerGrid = (sensors*angles + thdsPerBlk - 1) / thdsPerBlk;
 	sTime = getMicroSecond();
    inversefft_real << <blksPerGrid, thdsPerBlk >> >(device_filtered, device_fft, sensors*angles);
    eTime = getMicroSecond();
    FilteringKernelTime += (eTime - sTime);
    std::cout <<"Filtering Kernel Time = "<< FilteringKernelTime * 1e3 << "[ms]" <<std::endl;
    sTime = getMicroSecond();
    cudaMemcpy(filtered_result, device_filtered, sizeof(float)*sensors*angles, cudaMemcpyDeviceToHost);
    eTime = getMicroSecond();
    filteringTransferTime += (eTime - sTime);
    std::cout <<"Filtering Data Transfer Time = "<< filteringTransferTime * 1e3 << "[ms]" <<std::endl;

  	for( unsigned int i = 0; i < angles; i++ ) 
    {
        for( unsigned int j = 0; j < sensors; j++ ) 
        {
            unsigned int pixelPos = i * sensors + j;
            (*filter_out)[pixelPos] = (filtered_result)[pixelPos];
       
        }
    }
 



/****************************** BACK PROJECTION ******************************/
   

    // Allocate result of backprojection in device memory ----------------------------------------------
    float *d_output;
    cudaMalloc(&d_output, Width * Height * sizeof(float));
    float *h_output;
    h_output = (float*)malloc(Width*Height*sizeof(float));

    // Invoke kernel to BackProject------------Kernel 3-------------------------------------------------------------
    dim3 dimBlockbackproj(16, 16, 1);
    dim3 dimGridbackproj((Width + dimBlockbackproj.x - 1) / dimBlockbackproj.x, (Height + dimBlockbackproj.y - 1) / dimBlockbackproj.y, 1);

    sTime = getMicroSecond();
    backprojection_kernel << <dimGridbackproj, dimBlockbackproj >>> (angles,sensors, device_theta, x_min, dx, Width, y_min, dy, Height, r_min, dr, d_output,device_filtered);
    eTime = getMicroSecond();
    double backProjectionKernelTime = eTime - sTime;
    std::cout <<"Back-Projection Kernel Time = "<< backProjectionKernelTime * 1e3 << "[ms]" <<std::endl;

    sTime = getMicroSecond();
    cudaMemcpy(h_output, d_output, Width * Height * sizeof(float), cudaMemcpyDeviceToHost);
    eTime = getMicroSecond();
    BackProjectionTransferTime += (eTime - sTime);
    std::cout <<"Back-Projection Data Transfer Time = "<< BackProjectionTransferTime * 1e3 << "[ms]" <<std::endl;


    // Returning the output
    for (int y_idx = 0; y_idx < Height; y_idx++) 
    {
        for (int x_idx = 0; x_idx < Width; x_idx++) 
        {
            (*reconstructed_out)[x_idx + Width * y_idx] = (h_output)[x_idx + Width * y_idx];
        }
    }
    return 0;
}

