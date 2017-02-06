#include "neural.h"
#include "flash_dma.h"
#include "time.h"

#define IS_LVE
#define IS_CI

void print_Q(vbx_word_t *v, const int width, const int shift) {
#ifndef IS_LVE
	vbx_sync();
#endif
	int i;
	printf("\r\n");
	for (i = 0; i < width; i++) {
		printf("%d\t", v[i] >> shift);
	}
	printf("\r\n");
}

int close(vbx_word_t *a, vbx_word_t *b, const int width, const int max_diff) {
#ifndef IS_LVE
	vbx_sync();
#endif
	int i, diff, errors = 0;
	for (i = 0; i < width; i++) {
	    int diff = a[i] - b[i];
	    if (diff < 0) {
		diff = -diff;
	    }
	    if (diff > max_diff) {
	      errors++;
	      if (errors < 10) {
		printf("error @ %d\r\n", i);
	      }
	    }
	}
	return errors;
}

int equal(vbx_word_t *a, vbx_word_t *b, const int width) {
  return close(a, b, width, 0);
}

void vbx_pool(vbx_word_t *v_out, vbx_word_t *v_pool, const int width, const int height) {
#ifdef IS_LVE
    int i;
    the_lve.stride = 2;
    vbx_set_vl(width*height/2);
    vbx(VVW, VSLT, v_pool, v_out, v_out+1);
    vbx(VVW, VCMV_NZ, v_out, v_out+1, v_pool);
    for (i = 0; i < width*height/2; i++) {
	v_out[i] = v_out[i*2];
    }

    the_lve.stride = 1;
    vbx_set_vl(width/2);
    for (i = 0; i < height/2; i++) {
	vbx(VVW, VSLT, v_pool, v_out + (i*2) * width/2, v_out + (i*2+1) * width/2); 
	vbx(VVW, VCMV_NZ, v_out + (i*2) * width/2, v_out + (i*2+1) * width/2, v_pool); 
	vbx(SVW, VOR, v_out + i * width/2, 0, v_out + (i*2) * width/2); 
    }
#endif
}

void vbx_relu(vbx_word_t* v_out, vbx_word_t* v_flag) {
#ifdef IS_LVE
    vbx(SVW, VSLT, v_flag, 0, v_out);
    vbx(VVW, VMUL, v_out, v_flag, v_out);
#else
    vbx(SVW, VCMV_LTZ, v_out, 0, v_out);
#endif
}

void vbx_move(vbx_word_t* v_out, const int value) {
    vbx(SVW, VAND, v_out, 0, v_out);
    vbx(SVW, VOR, v_out, value, v_out);
}


void vbx_flash_dma(vbx_word_t *v_dst, int flash_byte_offset, const int bytes) {
#ifdef IS_LVE
	flash_dma_trans(flash_byte_offset, (void*)v_dst, bytes);
	while(!flash_dma_done());
#endif
}

void vbx_flash_dma_async(vbx_word_t *v_dst, int flash_byte_offset, const int bytes) {
#ifdef IS_LVE
	flash_dma_trans(flash_byte_offset, (void*)v_dst, bytes);
#endif
}

void vbx_dma(vbx_word_t *v_dst, int *src, const int bytes) {
#ifdef IS_LVE
    int i;
    for (i = 0; i < bytes/4; i++) {
	v_dst[i] = src[i];
    }
#else
    vbx_dma_to_vector(v_dst, src, bytes);
#endif
}

void dense_lve(vbx_word_t *v_out, vbx_word_t *v_in, dense_layer_t *layer)
{
#if 0
    int x;
    vbx_word_t *v_biases  = v_out + layer->outputs*1;
    vbx_word_t *v_scales  = v_out + layer->outputs*2;
    vbx_word_t *v_weights = v_out + layer->outputs*3;
    vbx_word_t *v_relu = v_in;


    vbx_set_vl(layer->inputs);

    for (x = 0; x < layer->outputs; x++) {
	vbx_flash_dma(v_weights, layer->weights + x*layer->inputs, layer->inputs*sizeof(vbx_word_t));
	vbx_acc(VVW, VMUL, v_out + x, v_in, v_weights); 
    }

    vbx_set_vl(layer->outputs);

    vbx_dma(v_biases, layer->biases, layer->outputs*sizeof(vbx_word_t));
    vbx(VVW, VADD, v_out, v_out, v_biases);

    if (layer->scale) {
	vbx_dma(v_scales, layer->scales, layer->outputs*sizeof(vbx_word_t));
	vbx(VVW, VMULH, v_out, v_out, v_scales); 
	vbx(SVW, VMUL, v_out, 4, v_out); 
    }

    if (layer->activation_type == RELU) {
	vbx_relu(v_out, v_relu);
    }
#endif
}

void convolution_lve(vbx_word_t *v_out, vbx_word_t *v_in, convolution_layer_t *layer)
{
#if 0
    int y, c, k, kw, kh;
    int m = layer->m, n = layer->n, m0 = m, n0 = n;
    if (layer->maxpool) {
	m0 = m/2; n0 = n/2;
    }

    vbx_word_t *v_map, *v_pad, *v_relu, *v_pool;
    v_pad = v_in + m*n*layer->channels;
    v_pool = v_pad + (n+2)*(m+2);
    v_relu = v_pool;

    vbx_set_vl((n+2)*(m+2));
    vbx(SVW, VAND, v_pad, 0, v_pad);

    for (k = 0; k < layer->kernels; k++) {
	v_map = v_out + k*m0*n0;
	vbx_set_vl(n*m);
	vbx(SVW, VAND, v_map, 0, v_map);
	vbx(SVW, VOR, v_map, layer->biases[k], v_map);

	for (c = 0; c < layer->channels; c++) {
	    vbx_set_vl(n);
	    for (y = 0; y < m; y++) {
		vbx(SVW, VOR, v_pad + (y+1)*(n+2) + 1, 0, v_in + c*m*n + y*n);
	    }

	    for (y = 0; y < m; y++) {
		for (kh = 0; kh < 3; kh++) {
		    for (kw = 0; kw < 3; kw++) {
			if (layer->weights[(k*layer->channels+c)*3*3 + kh*3 + kw] > 0) {
			    vbx(VVW, VADD, v_map+y*n, v_map+y*n, v_pad+(kh+y)*(n+2)+kw); 
			} else {
			    vbx(VVW, VSUB, v_map+y*n, v_map+y*n, v_pad+(kh+y)*(n+2)+kw); 
			}
		    }
		}
	    }
	}

	if (layer->maxpool) {
	    vbx_pool(v_map, v_pool, m, n);
	}

	vbx_set_vl(m0*n0);
	if (layer->scale) {
	    vbx(SVW, VMULH, v_map, layer->scales[k], v_map); 
	    vbx(SVW, VMUL, v_map, 4, v_map); 
	} 

	if (layer->activation_type == RELU) {
	    vbx_relu(v_map, v_relu);
	}
    }
#endif
}

void dummy_convolution_lve(vbx_word_t *v_out, vbx_word_t *v_in, convolution_layer_t *layer)
{
    int y, c, k, kw, kh;
    int m = layer->m, n = layer->n, m0 = m, n0 = n;
    if (layer->maxpool) {
	m0 = m/2; n0 = n/2;
    }

    vbx_word_t *v_map, *v_pad, *v_relu, *v_pool;
    v_pad = v_in;
    v_pool = v_pad + (n+2)*(m+2);
    v_relu = v_pool;

    vbx_set_vl((n+2)*(m+2));
    vbx(SVW, VAND, v_pad, 0, v_pad);

    for (k = 0; k < layer->kernels; k++) {
	v_map = v_out;
	vbx_set_vl(n*m);
	vbx(SVW, VAND, v_map, 0, v_map);
	vbx(SVW, VOR, v_map, v_map[0], v_map);

	for (c = 0; c < layer->channels; c++) {
	    vbx_set_vl(n);
	    if (k == 0) {
	      for (y = 0; y < m; y++) {
		  vbx(SVW, VOR, v_pad + (y+1)*(n+2) + 1, 0, v_in);
	      }
	    }

	    for (y = 0; y < m; y++) {
#ifdef IS_CI
		vbx(VVW, VADD, v_map+y*n, v_map+y*n, v_pad); 
#else
		for (kh = 0; kh < 3; kh++) {
		    for (kw = 0; kw < 3; kw++) {
			if (v_map[0] > 0) {
			    vbx(VVW, VADD, v_map+y*n, v_map+y*n, v_pad+(kh+y)*(n+2)+kw); 
			} else {
			    vbx(VVW, VSUB, v_map+y*n, v_map+y*n, v_pad+(kh+y)*(n+2)+kw); 
			}
		    }
		}
#endif
	    }
	}

	if (layer->maxpool) {
	    vbx_pool(v_map, v_pool, m, n);
	}

	vbx_set_vl(m0*n0);
	if (layer->scale) {
	    vbx(SVW, VMULH, v_map, v_map[0], v_map); 
	    vbx(SVW, VMUL, v_map, 4, v_map); 
	} 

	if (layer->activation_type == RELU) {
	    vbx_relu(v_map, v_relu);
	}
    }
}

void dummy_dense_lve(vbx_word_t *v_out, vbx_word_t *v_in, dense_layer_t *layer)
{
    int x;
    vbx_word_t *v_biases  = v_out + layer->outputs*1;
    vbx_word_t *v_scales  = v_out + layer->outputs*2;
    vbx_word_t *v_weights = v_out + layer->outputs*3;
    vbx_word_t *v_relu = v_in;


    vbx_set_vl(layer->inputs);

#if 1
    vbx_flash_dma(v_weights, 0, layer->inputs*sizeof(vbx_word_t));
#endif
    for (x = 0; x < layer->outputs; x++) {
#if 0
	vbx_flash_dma(v_weights, 0, layer->inputs*sizeof(vbx_word_t));
	vbx_acc(VVW, VMUL, v_out + x, v_in, v_weights); 
#else
	vbx_flash_dma_async(v_weights, 0, layer->inputs*sizeof(vbx_word_t)/8);
	vbx(SVW, VAND, v_weights, 0xFF, v_weights); 
	vbx(SVW, VSLT, v_weights, 0xff, v_weights); 
	vbx(SVW, VSLT, v_weights, 0xff, v_weights); 
	vbx_acc(VVW, VMUL, v_out + x, v_in, v_weights); 
	while(!flash_dma_done());
#endif
    }

    vbx_set_vl(layer->outputs);

    vbx_flash_dma(v_biases, 0, layer->outputs*sizeof(vbx_word_t));
    vbx(VVW, VADD, v_out, v_out, v_biases);

    if (layer->scale) {
	vbx_flash_dma(v_scales, 0, layer->outputs*sizeof(vbx_word_t));
	vbx(VVW, VMULH, v_out, v_out, v_scales); 
	vbx(SVW, VMUL, v_out, 4, v_out); 
    }

    if (layer->activation_type == RELU) {
	vbx_relu(v_out, v_relu);
    }
}

void cifar_lve() {
	init_lve();
	printf("\r\n");
	printf("\r\n\r\nCES or BUST!!\r\n");
	printf("\r\n");

	int i, errors;
	vbx_word_t *v_out, *v_in;
	v_out = (vbx_word_t*)SCRATCHPAD_BASE;
	v_in = v_out + 16384;
#if 0
	printf("\r\nTesting vbx_relu\r\n");
	int relu_input[] = {-1, 2, 4, 4, 8, 12, -8, 1};
	int relu_output[] = {0, 2, 4, 4, 8, 12, 0, 1};
	int relu_size = 8;

	v_out = (vbx_word_t*)SCRATCHPAD_BASE;
	vbx_word_t *v_flag = v_out + relu_size;

	for (i = 0; i < relu_size; i++) {
	    relu_input[i] = relu_input[i] << 16;
	    relu_output[i] = relu_output[i] << 16;
	}
	vbx_dma(v_out, relu_input, relu_size*sizeof(vbx_word_t));

	vbx_set_vl(relu_size);
	vbx_relu(v_out, v_flag);

	errors += equal(v_out, relu_output, relu_size);

	printf("errors %d\n", errors);

	printf("\r\nTesting vbx_pool\r\n");
	int pool_input[] = {2, -2, 4, 5,
                            12, 11, -8, 1,
	                    12, -12, 14, 15,
                            112, 111, -18, 11};
	int pool_output[] = {12, 5,
                             112, 15};
	int pool_size = 16;
	for (i = 0; i < pool_size; i++) {
	    pool_input[i] = pool_input[i] << 16;
	    pool_output[i] = pool_output[i] << 16;
	}
	v_out = (vbx_word_t*)SCRATCHPAD_BASE;
	v_flag = v_out + pool_size;
	vbx_dma(v_out, pool_input, pool_size*sizeof(vbx_word_t));
	vbx_pool(v_out, v_flag, 4, 4);
	errors = equal(v_out, pool_output, pool_size/2/2);
	printf("errors %d\n", errors);
	print_Q(v_out, pool_size/2/2, 16);
	
	printf("\r\nTesting vbx mul hi\r\n");
	int a[] = {2, -2, 4, 5};
	int b[] = {1, -1, 4, 5};
	int c[] = {2, 2, 16, 25};
	int mul_size = 4;

	v_out = (vbx_word_t*)SCRATCHPAD_BASE;
	vbx_word_t *v_a = v_out + 1*mul_size;
	vbx_word_t *v_b = v_out + 2*mul_size;

	for (i = 0; i < mul_size; i++) {
	    a[i] = a[i] << 16+4;
	    b[i] = b[i] << 16+12;
	    c[i] = c[i] << 16;
	}
	vbx_dma(v_a, a, mul_size*sizeof(vbx_word_t));
	vbx_dma(v_b, b, mul_size*sizeof(vbx_word_t));

	vbx_set_vl(mul_size);
	vbx(VVW, VMULH, v_out, v_a, v_b);
	print_Q(v_out, mul_size, 16);
	errors = equal(v_out, c, mul_size);

	printf("errors %d\n", errors);
#endif

#if 0
	printf("\r\nTesting vbx dense\r\n");
	while(FLASH_DMA_BASE[FLASH_DMA_STATUS] & 0x80000000){
	}

	printf("initialized DMA\r\n");

	int elements= 8;
	int xfer_size= 8*4;
	int flash_address = 0;

	int outputs = 10;
	vbx_word_t *v_weights = v_out + outputs*2;

	volatile char* sp_base=(volatile char*)SCRATCHPAD_BASE;
	flash_dma_trans(flash_address, (void*)v_weights, xfer_size);
	while(!flash_dma_done());

	vbx_word_t *v_a=(vbx_word_t *)SCRATCHPAD_BASE;

	printf("\r\n");
	int i;
	for (i=0; i < elements; i++) {
	    printf("%d\t", v_a[i]);
	}
	printf("\r\n");
#endif
#if 0
	printf("\r\nTesting vbx dense\r\n");

	int dense_biases[] = {-501514,-175794,-383338,-841043,-387872,-342826,-469085,-458890,-201922,-613068};
	int dense_scales[] = {111025912,96108008,112351344,104096248,117695752,108380824,111675008,108947872,114070048,88257352};
	int dense_inputs[] = {28371,56800,11240,68338,0,0,0,25252,0,0,0,0,0,12629,7266,0,7409,59101,91565,0,0,0,0,0,452,0,0,0,0,70101,0,0,0,53390,0,0,79039,0,0,0,0,0,0,0,0,3713,102832,89912,0,90517,0,0,0,64244,20784,57052,0,0,86067,47562,90065,0,0,0,0,0,29809,16951,0,5374,0,53295,0,24815,0,0,76092,902,54498,0,9694,0,30561,0,0,0,8458,27541,66738,69998,52422,24424,0,0,76781,0,80373,0,0,0,0,88795,0,0,0,0,0,0,0,0,0,0,0,102499,0,0,0,0,0,82429,0,0,0,0,0,54452,0,0,46694,83834,0,0,0,0,0,0,60733,8280,0,0,0,0,0,0,0,33004,0,0,0,0,0,0,122693,0,0,83243,0,0,61312,0,0,0,119241,0,28501,0,32779,0,0,43861,54430,0,0,0,0,0,0,0,0,0,81915,69277,58149,12507,0,50229,74836,0,0,0,32315,0,35791,0,35829,0,79019,0,0,24023,0,80796,83324,24785,0,0,0,0,0,0,0,0,0,0,7365,0,0,87333,36797,0,0,0,0,0,0,50350,0,0,38763,89204,0,0,0,60581,94030,70103,0,0,0,0,134430,0,0,0,46977,110268,99227,24406,0,0,0,0,6433,42403,0,0};
	int dense_outputs[] = {-210842,-148923,-183964,154733,-171223,-188231,-151054,-152742,-186070,-203593};

	dense_layer_t dense_layer;
	dense_layer.layer_type = DENSE;
	dense_layer.activation_type = LINEAR;
	dense_layer.inputs = 256;
	dense_layer.outputs = 10;
	dense_layer.scale = 1;
	dense_layer.weights = 0;
	dense_layer.biases = dense_biases;
	dense_layer.scales = dense_scales;

	vbx_dma(v_in, dense_inputs, dense_layer.inputs*sizeof(vbx_word_t));

	dense_lve(v_out, v_in, &dense_layer);

	errors = close(v_out, dense_outputs, dense_layer.outputs, 4);
	printf("errors %d\n", errors);

#endif
#if 0
	printf("\r\nTesting vbx convolution\r\n");
	int conv_biases[] = {-299797,-152806,98137,130968};
	int conv_scales[] = {806579392,258308416,624079808,771659072};
	int conv_weights[] = {1,-1,-1,1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,1,1,-1,1,-1,-1,1,-1,-1,1,1,-1,-1,-1,-1,1,1,-1,-1,1,-1,-1,-1,-1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,-1,-1,1,-1,-1,1,1,1,1,-1,-1,1,-1,-1,1,1,1,-1,1,-1,1,-1,-1,1,1,1,-1,1,1,-1,1,-1,-1,1,-1,-1,-1,1,1,-1,-1,-1,1,-1,1,-1,1,1,-1,-1,1,1,-1,1};

	convolution_layer_t conv_layer;
	conv_layer.activation_type = RELU;
	conv_layer.m = 32;
	conv_layer.n = 32;
	conv_layer.channels = 3;
	conv_layer.kernels = 4;
	conv_layer.maxpool = 0;
	conv_layer.scale = 1;
	conv_layer.weights = conv_weights;
	conv_layer.biases = conv_biases;
	conv_layer.scales = conv_scales;

	v_in = v_out + conv_layer.m*conv_layer.n*conv_layer.kernels;
	vbx_flash_dma(v_in, 0, conv_layer.m*conv_layer.n*conv_layer.channels*sizeof(vbx_word_t));

	int start_time = get_time();

	int l;
	for (l = 0; l < 10; l++) {
	  convolution_lve(v_out, v_in, &conv_layer);
	}
	int stop_time = get_time();
	printf("10xtime %d\n", stop_time - start_time);

	int size = conv_layer.m*conv_layer.n*conv_layer.kernels;
	if (conv_layer.maxpool) size = size / 4;

	vbx_flash_dma(v_in, 3*32*32*sizeof(vbx_word_t), size*sizeof(vbx_word_t));

	errors = close(v_out, v_in, size, 8);
	printf("errors %d\n", errors);
#endif
#if 1
	printf("\r\nTesting non-ci vbx runtime\r\n");
	int l = 0, done = 0;
	int time_start, time_stop;
	int time_init = get_time();
	while(1) {
		switch (cifar[l].layer_type) {
			case DENSE:
			    printf("dense %d\r\n", l);
			    time_start = get_time();

			    dummy_dense_lve(v_out, v_in, &(cifar[l].dense));

			    time_stop = get_time();
			    printf("cycles %d\r\n", time_stop-time_start);
			    if (cifar[l].dense.last) {
				done = 1;
			    }
			    break;
			case CONV:
			    printf("conv %d\r\n", l);
			    time_start = get_time();

			    dummy_convolution_lve(v_out, v_in, &(cifar[l].conv));

			    time_stop = get_time();
			    printf("cycles %d\r\n", time_stop-time_start);

			    if (cifar[l].conv.last) {
				done = 1;
			    }
			    break;
			
			default:
			  printf("unknown layer type\r\n");
			  break;
		}

		if (done) {
		    break;
		}
		l++;
	}
	printf("total cycles %d\r\n", get_time() - time_init);
#endif
}
