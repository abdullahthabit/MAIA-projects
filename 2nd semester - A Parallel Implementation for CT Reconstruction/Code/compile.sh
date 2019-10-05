#! /bin/bash

rm filter
rm kernels.o
nvcc -c kernels.cu -I/home/abdullah/Desktop/active/newFolder/NVIDIA_CUDA-10.0_Samples/common/inc -I/usr/local/cuda/include -L/usr/local/cuda/lib -lcufft
nvcc -ccbin g++ -Xcompiler "-std=c++11" kernels.o main.cpp get_micro_second.cpp -lcuda -lcudart -lcufft -o filter `pkg-config --cflags --libs opencv` 
