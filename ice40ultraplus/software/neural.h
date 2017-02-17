#ifndef __NEURAL_H__
#define __NEURAL_H__

#include "vbx.h"
#include "printf.h"
#include "flash_dma.h"



#define DATA_SCALE 16
#define CES_GOLDEN 0 //1 is larger 3 second net, 0 is reduced 1.3 second net

#if CES_GOLDEN
#define FLASH_DATA_OFFSET 0x20000
#else
#define FLASH_DATA_OFFSET 0xB0000
#endif
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
    int weights;
    int biases;
    int scale;
    int scales;
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
void vbx_flash_dma(vbx_word_t *v_dst, int flash_byte_offset, const int bytes);
void vbx_flash_dma_async(vbx_word_t *v_dst, int flash_byte_offset, const int bytes);
void zeropad_input(vbx_ubyte_t *v_out, vbx_ubyte_t *v_in, const int m, const int n);
void convolution_ci_lve(vbx_ubyte_t *v_outb, vbx_ubyte_t *v_inb, convolution_layer_t *layer, const int debug);
void dense_lve(vbx_word_t *v_out, vbx_word_t *v_in, dense_layer_t *layer);

#endif // __NEURAL_H__
