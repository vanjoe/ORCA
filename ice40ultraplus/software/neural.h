#ifndef __NEURAL_H__
#define __NEURAL_H__

#include "vbx.h"
#include "printf.h"

#define DATA_SCALE 16

enum LAYER {
    DENSE,
    CONV
};


enum ACTIVATION{
    LINEAR,
    LEAKY,
    RELU
};


typedef struct {
    int layer_type;
    int activation_type;
    int last;
    int inputs;
    int outputs;
    int* weights;
    int* biases;
    int scale;
    int* scales;
} dense_layer_t; 


typedef struct {
    int layer_type;
    int activation_type;
    int last;
    int m;
    int n;
    int channels;
    int kernels;
    int maxpool;
    int weights;
    int scale;
    int zeropad_output;
} convolution_layer_t;


typedef union {
    int layer_type;
    dense_layer_t dense;
    convolution_layer_t conv;
} layer_t;


extern layer_t cifar[];
void cifar_lve();

#endif // __NEURAL_H__
