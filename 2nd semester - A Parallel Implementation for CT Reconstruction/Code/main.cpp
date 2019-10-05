#include <iostream>
#include <cstdlib>
#include <string>
#include <cuda.h>
#include <cuda_runtime.h>
#include <cufft.h>
#include "kernels.h"
#include <functional>
#include <fstream>
#include <opencv2/core/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <string>
#include "get_micro_second.h"
using namespace cv;
using namespace std;
#define pi acos(-1)



int main(int argc, char** argv) {

    //
    // Declare the variables for measuring elapsed time
    //
    double sTime;
    double eTime;

    string imageName; // by default
    if( argc > 1)
    {
        imageName = argv[1];
    }
    Mat image;

	Mat_<float> fm;

	image = imread(imageName.c_str(), IMREAD_UNCHANGED);
	image.convertTo(fm,CV_32F);
    // fm = fm.t();

	cout << "Width : " << image.cols << endl;
	cout << "Height: " << image.rows << endl;
	cout << "Channels: " << image.channels() <<endl;

	imshow("orig",image);
	// waitKey(0);
    //----------------------------------------------------------------------
    int n_y = image.rows;
    int n_x = image.cols;
    float d_x = 0.1;
    float d_y = 0.1;
    float x[n_x];
    float y[n_y];
    
    float dr = 1/(1/d_x + 1/d_y);
    float x_min=100000;
    float x_max=-100000;
    float y_min=100000;
    float y_max=-100000;


    int cnt = 0;
    for (float i= float(-(n_x - 1)/2.0); i <= float((n_x - 1)/2.0); i++) {
    		x[cnt] = i * d_x;
    		if (x[cnt] <  x_min)
    			x_min = x[cnt];

    		if (x[cnt] > x_max)
    			x_max = x[cnt];

    		// cout<< x[cnt] << " " << endl;
    		cnt++;
    }
    for (float i= float(-(n_y - 1)/2.0); i <= float((n_y - 1)/2.0); i++) {
    		y[cnt] = i * d_y;
    		if (y[cnt] <  y_min)
    			y_min = y[cnt];

    		if (y[cnt] > y_max)
    			y_max = y[cnt];

    		// cout<< x[cnt] << " " << endl;
    		cnt++;
    }

    float r_max_t = sqrt((x_max * x_max) + (y_max * y_max));
    float r_max = dr * ceil(r_max_t/dr);
    float r_min = -1 * r_max;

    int Nr = (2*r_max/dr + 1 + 0.5);
    // std::max_element(std::begin(x), std::end(x))
    cout<< "xmin = " << x_min << endl;
    cout<< "xmax = " << x_max << endl;
   	cout<< "ymin = " << y_min << endl;
    cout<< "ymax = " << y_max << endl;
    cout << "Nr=" << Nr<<endl;
    cout << "rmax=" <<r_max <<endl;
    cout << "rmin=" <<r_min <<endl;
    cout << "dr= " <<dr <<endl;
  	float *h_img1, *h_image;
    unsigned int iWidth = image.cols;
    unsigned int iHeight = image.rows;

    try {
	h_img1 = new float[ iWidth * iHeight ];
    h_image = new float[ iWidth * iHeight ];
    } catch( std::bad_alloc & ) {
	std::cerr << "Could not allocate the memory space for h_image: "
		  << __FILE__ << " : " << __LINE__
		  << std::endl;
	exit(1);
    }

    for( unsigned int i = 0; i < iHeight; i++ ) 
    {
        for( unsigned int j = 0; j < iWidth; j++ ) 
        {
            unsigned int pixelPos = i * iWidth + j;
            h_image[pixelPos] = fm.at<float>(i,j);
            h_img1[pixelPos] = fm.at<float>(i,j)/255;
        }
    }

    // Get all values from inputs
	int numAngles = 180;
	// cout<<numAngles<<endl;
	float minR = r_min;
	// cout<<minR<<endl;
	float maxR = r_max;
	// cout<<maxR<<endl;
	int numSensors = Nr;
	// cout<<numSensors<<endl;
	float minX = x_min;
	// cout<<minX<<endl;
	float maxX = x_max;
	// cout<<maxX<<endl;
	int numX = iWidth;
	// cout<<numX<<endl;
	float minY = y_min;
	// cout<<minY<<endl;
	float maxY = y_max;
	// cout<<maxY<<endl;
	int numY = iHeight;
	// cout<<numY<<endl;

	// Calculate some other values based on those inputs
	// cout<<dr<<endl;
	float dx = d_x;
	// cout<<dx<<endl;
	float dy = d_y;
	// cout<<dy<<endl;
	int count = 0;
	// Read Image and Projection Angles from File
	float datfromfile, *h_img, *h_angles,*h_angles_d;
	h_img = (float *)malloc(numX*numY*sizeof(float));
	h_angles = (float *)malloc(numAngles*sizeof(float));
	h_angles_d = (float *)malloc(numAngles*sizeof(float));





    int rows = iHeight;
    int cols = iWidth;
 

	float step = 180.0/numAngles;
	for (int i = 0; i < numAngles; i++) {
		h_angles[i] = step* i * pi / 180.0f;
		h_angles_d[i] = step*i;
	}

	float *h_img_out = new float[numAngles * numSensors ];

    sTime = getMicroSecond();
	sinogram (numAngles, h_angles, numX, numY, h_img1 , numSensors,dx,dy, dr, minX, minY, minR, &h_img_out);
    eTime = getMicroSecond();

    double sinogramTime = eTime - sTime;
 	cout <<"Sinogram Overall Time = "<< sinogramTime * 1e3 << "[ms]" <<std::endl;

	printf("numSensors = %d, numAngles = %d", numSensors, numAngles);
	for (int t_idx = 0; t_idx < numAngles; t_idx++) {
		for (int r_idx = 0; r_idx < numSensors; r_idx++) {
			//printf("Writing file!\n"); 
		}
	}

	Mat out_im(cv::Size( numSensors,numAngles), CV_32F);
	for( unsigned int i = 0; i < numAngles; i++ ) 
    {
        for( unsigned int j = 0; j < numSensors; j++ ) 
        {
            unsigned int pixelPos = i * numSensors + j;
            out_im.at<float>(i,j) = h_img_out[pixelPos];
        }
    }

    imshow("Sinogram Result",out_im);
    Mat out_show(cv::Size(numAngles, numSensors), CV_8U);
    out_im.convertTo(out_show,CV_8U);
    // imshow("display", out_show);
    // waitKey(0);
 	imwrite("sino_out.png", out_show);

    // Read data from files to host arrays

   	float *filter_out;
    filter_out = (float*)malloc(numAngles*numSensors*sizeof(float));

	float *h_bp_out = new float[numX * numY ];

    sTime = getMicroSecond();
	backProjection (&filter_out,h_img_out,numAngles, h_angles_d, numX, numY,numSensors,dx,dy, dr, minX, minY, minR, &h_bp_out);
    eTime = getMicroSecond();
    double backProjectionTime = eTime - sTime;
    cout <<"backProjection+Filtering Overall Time = "<< backProjectionTime * 1e3 << "[ms]" <<std::endl;

	Mat reconstructed(cv::Size( numSensors,numAngles), CV_32F);
	for( unsigned int i = 0; i < numAngles; i++ ) 
    {
        for( unsigned int j = 0; j < numSensors; j++ ) 
        {
            unsigned int pixelPos = i * numSensors + j;
            reconstructed.at<float>(i,j) = filter_out[pixelPos];
            //cout << i << "," << j << ":" << filter_out[pixelPos] << endl;
        }
    }


    reconstructed.convertTo(out_show,CV_8U);
    imshow("filtered sinogram", out_show);
    imwrite("filter_out.png", out_show);


    Mat reconstructed1(cv::Size( numY,numX), CV_32F);


    for( unsigned int y_idx = 0; y_idx < numY; y_idx++ ) {
    for( unsigned int x_idx = 0; x_idx < numX; x_idx++ ) {
        unsigned int pixelPos = x_idx * numX + y_idx;

            reconstructed1.at<float>(y_idx,x_idx) = h_bp_out[pixelPos]/256;
            //cout << y_idx<< "," << x_idx << ":" << h_bp_out[pixelPos] << endl;
    }
    }
    Mat recon_temp(cv::Size(numY, numX), CV_8U);
    reconstructed1.convertTo(recon_temp,CV_8U);

    Mat dst;
    flip(recon_temp, dst, 1);

    // imshow("reconstructed", recon_temp.t());
    imshow("reconstructed", dst.t());
    imwrite("recon_out.png", dst.t());
    waitKey(0);
 	// imwrite("reconstructed.png", reconstructed_show);


    return 0;

}



