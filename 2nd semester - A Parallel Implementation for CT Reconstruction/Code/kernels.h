#ifndef KERNELS_H_
#define KERNELS_H_

#include <cufft.h>

void sinogram (int angles, float * theta, int Width, int Height, float * img , int sensors,float dx,float dy, float dr,float x_min,float y_min,float r_min, float **h_img_out_t);

int backProjection (float ** filter_out ,float * sinogram_image, int angles, float * theta, int Width, int Height, int sensors,float dx,float dy, float dr,float x_min,float y_min,float r_min, float **reconstructed_out);




#endif
