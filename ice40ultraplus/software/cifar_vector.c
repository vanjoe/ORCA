#include "neural.h"

void vbx_flash_dma(vbx_word_t *v_dst, int flash_byte_offset, const int bytes)
{
	flash_dma_trans(flash_byte_offset, (void*)v_dst, bytes);
	while(!flash_dma_done());
}

void vbx_flash_dma_async(vbx_word_t *v_dst, int flash_byte_offset, const int bytes)
{
	flash_dma_trans(flash_byte_offset, (void*)v_dst, bytes);
}

void vbx_pool(vbx_word_t *v_out, vbx_word_t *v_pool, const int width, const int height) {
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
}

void vbx_relu(vbx_word_t* v_out, vbx_word_t* v_flag) {
    vbx(SVW, VSLT, v_flag, 0, v_out);
    vbx(VVW, VMUL, v_out, v_flag, v_out);
}

void vbx_unpack_weights(vbx_word_t *v_unpacked, vbx_word_t *v_packed, const int size)
{
  int b;
  vbx_set_vl(size/32);
  for (b = 0; b < 32; b++) {
    vbx(SVW, VAND, v_unpacked + b*(size/32), 1<<(b), v_packed);
    vbx(SVW, VCMV_NZ, v_unpacked + b*(size/32), 1, v_unpacked + b*(size/32));
    vbx(SVW, VCMV_Z, v_unpacked + b*(size/32), -1, v_unpacked + b*(size/32));
  }
}

void vbx_convolve_ci(vbx_half_t *v_out, vbx_ubyte_t *v_in, vbx_half_t *v_conv, const int m, const int n, const short weights)
{
    int y, x;

    vbx_set_vl(1);
    vbx(SVW, VCUSTOM1, 0, weights, 0);

    vbx_set_vl(m+2);
    the_lve.stride = n+4;

    for(x = 0; x < n; x +=2) {
	vbx(VVHB, VCUSTOM2, v_conv + x, (vbx_byte_t*)v_in + x, (vbx_byte_t*)v_in + x + 4);
    }

    vbx_set_vl(n/2);
    the_lve.stride = 1;
    for (y = 0; y < m; y++) {
      vbx(VVW, VCUSTOM3, (vbx_word_t*)(v_out + y*n), (vbx_word_t*)(v_out + y*n), (vbx_word_t*)(v_conv + y*(n+4)));
    }
}

void vbx_zeropad_ci(vbx_ubyte_t *v_out, vbx_word_t *v_pad, vbx_word_t *v_in, const int m, const int n)
{
    int y;

    // zero top and bottom
    vbx_set_vl(n+2+2);
    vbx(SVW, VAND, v_pad, 0, v_pad);
    vbx(VVBW, VCUSTOM0, (vbx_byte_t*)v_out + (0)*(n+2+2), v_pad, 0);
    vbx(VVBW, VCUSTOM0, (vbx_byte_t*)v_out + (m+1)*(n+2+2), v_pad, 0);

    // move in rows
    for (y = 0; y < m; y++) {
	vbx_set_vl(n);
	vbx(SVW, VOR, v_pad + 1, 0, v_in + y*n);
	vbx_set_vl(n+2+2);
	vbx(VVBW, VCUSTOM0, (vbx_byte_t*)v_out + (y+1)*(n+2+2), v_pad, 0);
    }
}

void vbx_accumulate_columns(vbx_word_t *v_map, vbx_half_t *v_maph, vbx_word_t *v_tmp, const int m, const int n) 
{
  // add each packed column to output
  the_lve.stride = 2;
  vbx_set_vl(n/2*m);
  vbx(SVWH, VMUL, v_tmp, (1<<16), v_maph);
  vbx(SVW, VMULH, v_tmp, (1<<16), v_tmp);
  vbx(SVWH, VMULH, v_tmp + 1, (1<<16), v_maph);

  the_lve.stride = 1;
  vbx_set_vl(n*m);
  vbx(VVW, VADD, v_map, v_map, v_tmp);

  // zero v_maph for next round of accum
  vbx_set_vl(n/2*m);
  vbx(SVW, VAND, (vbx_word_t*)v_maph, 0, (vbx_word_t*)v_maph);
}

// takes in padded inputs
#if 0
void convolution_ci_lve(vbx_ubyte_t *v_outb, vbx_ubyte_t *v_inb, convolution_layer_t *layer, const int debug)
{
    int c, k, m = layer->m, n = layer->n, m0 = m, n0 = n;
#ifdef SCALAR
    int i;
#endif
    if (layer->maxpool) {
	m0 = m/2; n0 = n/2;
    }

    // assumes 128K scratch
    vbx_word_t *v_map = (vbx_word_t*)(SCRATCHPAD_BASE + 110*1024);
    vbx_half_t *v_maph = (vbx_half_t*)(SCRATCHPAD_BASE + 114*1024);
    vbx_word_t *v_tmp = (vbx_word_t*)(SCRATCHPAD_BASE + 116*1024);
    vbx_word_t *v_dma0 = (vbx_word_t*)(SCRATCHPAD_BASE + 124*1024);
    vbx_word_t *v_dma1 = (vbx_word_t*)(SCRATCHPAD_BASE + 126*1024);
    vbx_word_t *v_dma[] = {v_dma0, v_dma1};
    vbx_uhalf_t *v_weights;

    int buf = 0;
    int dma_size = 2*4 + layer->channels*2;
    int dma_pad = dma_size % 4;

    vbx_flash_dma(v_dma[buf], layer->weights, dma_size+dma_pad);

    for (k = 0; k < layer->kernels; k++) {
	v_weights = (vbx_uhalf_t*)(v_dma[buf] + 2);

	if (k < layer->kernels-1) {
	  vbx_flash_dma_async(v_dma[!buf], layer->weights + (k+1)*dma_size, dma_size+dma_pad);
	}
	// set kernel bias
#ifndef SCALAR
	vbx_set_vl(n*m);
	vbx(SVW, VAND, v_map, 0, v_map);
	vbx(SVW, VOR, v_map, v_dma[buf][0], v_map);

	vbx_set_vl(n/2*m);
	vbx(SVW, VAND, (vbx_word_t*)v_maph, 0, (vbx_word_t*)v_maph);
#else
	for (i = 0; i < n*m; i++) {
	  v_map[i] = v_dma[buf][0];
	  v_maph[i] = 0;
	}
#endif

	for (c = 0; c < layer->channels; c++) {
#ifndef SCALAR
	    vbx_convolve_ci(v_maph, v_inb + c*(m+2)*(n+4), (vbx_half_t*)v_tmp, m, n, v_weights[c]);
#else
	    scalar_convolve_ci(v_maph, v_inb + c*(m+2)*(n+4), v_tmp, m, n, v_weights[c]);
#endif
	    if ((c+1)%16 == 0) {
#ifndef SCALAR
	      vbx_accumulate_columns(v_map, v_maph, v_tmp, m, n);
#else
	      scalar_accumulate_columns(v_map, v_maph, m, n);
#endif
	    }
	}
	if (layer->channels % 16) {
#ifndef SCALAR
	    vbx_accumulate_columns(v_map, v_maph, v_tmp, m , n);
#else
	    scalar_accumulate_columns(v_map, v_maph, m , n);
#endif
	}

	if (layer->maxpool) {
#ifndef SCALAR
	    vbx_pool(v_map, v_tmp, m, n);
#else
	    scalar_pool(v_map, m, n);
#endif
	}

	vbx_set_vl(m0*n0);
	if (layer->scale) {
#ifndef SCALAR
	    vbx(SVW, VMULH, v_map, v_dma[buf][1], v_map);
#else
	    long long mul;
	    for (i = 0; i < m0*n0; i++) {
	      mul = (long long)v_map[i] * (long long)v_dma[buf][1];
	      v_map[i] = (int)(mul >> 32);
	    }
#endif
	}

	if (!layer->zeropad_output && layer->activation_type == RELU) {
#ifndef SCALAR
	    vbx_relu(v_map, v_tmp);
#else
	    scalar_relu(v_map, m0, n0);
#endif
	}
	if (layer->zeropad_output) {
#ifndef SCALAR
	  vbx_zeropad_ci(v_outb+(k*(n0+4)*(m0+2)), v_tmp, v_map, m0, n0);
#else
	  scalar_zeropad_ci(v_outb+(k*(n0+4)*(m0+2)), v_map, m0, n0);
#endif
	} else {
#ifndef SCALAR
	  vbx_set_vl(m0*n0);
	  vbx(SVW, VOR, (vbx_word_t*)v_outb+(k*n0*m0), 0, v_map);
#else
	  vbx_word_t* v_out = (vbx_word_t*)v_outb;
	  for (i = 0; i < m0*n0; i++) {
	    v_out[k*n0*m0+i] = v_map[i];
	  }
#endif
	}

	if (k < layer->kernels-1) {
	  while(!flash_dma_done());
	}
	buf = !buf;
    }
}
#else
void convolution_ci_lve(vbx_ubyte_t *v_outb, vbx_ubyte_t *v_inb, convolution_layer_t *layer, const int debug)
{
    int c, k, m = layer->m, n = layer->n, m0 = m, n0 = n;
    if (layer->maxpool) {
	m0 = m/2; n0 = n/2;
    }

    // assumes 128K scratch
    vbx_word_t *v_map = (vbx_word_t*)(SCRATCHPAD_BASE + 110*1024);
    vbx_half_t *v_maph = (vbx_half_t*)(SCRATCHPAD_BASE + 114*1024);
    vbx_word_t *v_tmp = (vbx_word_t*)(SCRATCHPAD_BASE + 116*1024);
    vbx_word_t *v_dma0 = (vbx_word_t*)(SCRATCHPAD_BASE + 124*1024);
    vbx_word_t *v_dma1 = (vbx_word_t*)(SCRATCHPAD_BASE + 126*1024);
    vbx_word_t *v_dma[] = {v_dma0, v_dma1};
    vbx_uhalf_t *v_weights;

    int buf = 0;
    int dma_size = 2*4 + layer->channels*2;
    int dma_pad = dma_size % 4;

    vbx_flash_dma(v_dma[buf], layer->weights, dma_size+dma_pad);

    for (k = 0; k < layer->kernels; k++) {
	v_weights = (vbx_uhalf_t*)(v_dma[buf] + 2);

	if (k < layer->kernels-1) {
	  vbx_flash_dma_async(v_dma[!buf], layer->weights + (k+1)*dma_size, dma_size+dma_pad);
	}
	// set kernel bias
	vbx_set_vl(n*m);
	vbx(SVW, VAND, v_map, 0, v_map);
	vbx(SVW, VOR, v_map, v_dma[buf][0], v_map);

	vbx_set_vl(n/2*m);
	vbx(SVW, VAND, (vbx_word_t*)v_maph, 0, (vbx_word_t*)v_maph);

	for (c = 0; c < layer->channels; c++) {
	    vbx_convolve_ci(v_maph, v_inb + c*(m+2)*(n+4), (vbx_half_t*)v_tmp, m, n, v_weights[c]);
	    if ((c+1)%16 == 0) {
	      vbx_accumulate_columns(v_map, v_maph, v_tmp, m, n);
	    }
	}
	if (layer->channels % 16) {
	    vbx_accumulate_columns(v_map, v_maph, v_tmp, m , n);
	}

	if (layer->maxpool) {
	    vbx_pool(v_map, v_tmp, m, n);
	}

	vbx_set_vl(m0*n0);
	if (layer->scale) {
	    vbx(SVW, VMULH, v_map, v_dma[buf][1], v_map);
	}

	if (!layer->zeropad_output && layer->activation_type == RELU) {
	    vbx_relu(v_map, v_tmp);
	}
	if (layer->zeropad_output) {
	  vbx_zeropad_ci(v_outb+(k*(n0+4)*(m0+2)), v_tmp, v_map, m0, n0);
	} else {
	  vbx_set_vl(m0*n0);
	  vbx(SVW, VOR, (vbx_word_t*)v_outb+(k*n0*m0), 0, v_map);
	}

	if (k < layer->kernels-1) {
	  while(!flash_dma_done());
	}
	buf = !buf;
    }
}
#endif

void dense_lve(vbx_word_t *v_out, vbx_word_t *v_in, dense_layer_t *layer)
{
    int x;
    vbx_word_t *v_biases  = v_out + layer->outputs*1;
    vbx_word_t *v_scales  = v_out + layer->outputs*2;
    vbx_word_t *v_weights = v_out + layer->outputs*3;
    vbx_word_t *v_buf0 = v_weights + layer->inputs*1;
    vbx_word_t *v_buf1 = v_weights + layer->inputs*2;

    vbx_word_t *v_dma[] = {v_buf0, v_buf1};

    vbx_word_t *v_relu = v_in;

    // packed into 32x
    int buf = 0;
    vbx_flash_dma(v_dma[buf], layer->weights, layer->inputs/32*sizeof(vbx_word_t));

    for (x = 0; x < layer->outputs; x++) {
	if (x < layer->outputs -1) {
	  vbx_flash_dma_async(v_dma[!buf], layer->weights + (x+1)*layer->inputs/32*sizeof(vbx_word_t), layer->inputs/32*sizeof(vbx_word_t));
	}

	vbx_unpack_weights(v_weights, v_dma[buf], layer->inputs);

	vbx_set_vl(layer->inputs);
	vbx_acc(VVW, VMUL, v_out + x, v_in, v_weights);

	if (x < layer->outputs -1) {
	  while(!flash_dma_done());
	}
	buf = !buf;
    }

    vbx_set_vl(layer->outputs);

    vbx_flash_dma(v_biases, layer->biases, layer->outputs*sizeof(vbx_word_t));
    vbx(VVW, VADD, v_out, v_out, v_biases);

    if (layer->scale) {
	vbx_flash_dma(v_scales, layer->scales, layer->outputs*sizeof(vbx_word_t));
	vbx(VVW, VMULH, v_out, v_out, v_scales);
    }

    if (layer->activation_type == RELU) {
	vbx_relu(v_out, v_relu);
    }
}
