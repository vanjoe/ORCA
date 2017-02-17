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

void scalar_pool(vbx_word_t *v_out, const int width, const int height) {
    int i, j;
    int a, b, c, d;
    for (j = 0; j < height; j+=2) {
      for (i = 0; i < width; i+=2) {
	a = v_out[j*width + i];
	b = v_out[j*width + i+1];
	c = v_out[(j+1)*width + i];
	d = v_out[(j+1)*width + i+1];
	if (b > a) a = b;
	if (d > c) c = d;
	if (c > a) a = c;
	v_out[j/2*width/2+i/2] = a;
      }
    }
}

void scalar_relu(vbx_word_t* v_out, const int m, const int n) {
  int i, j;
  for (j = 0; j < m; j++) {
    for (i = 0; i < n; i++) {
      if (v_out[j*n+i] < 0) {
	v_out[j*n+i] = 0;
      }
    }
  }
}

void scalar_unpack_weights(vbx_word_t *v_unpacked, vbx_word_t *v_packed, const int size)
{
  int b, i;
  for (b = 0; b < 32; b++) {
    for (i = 0; i < size/32; i++) {
      v_unpacked[b*(size/32)+i] = v_packed[i] & (1<<b);
      if (v_unpacked[b*size/32+i]) {
	v_unpacked[b*size/32+i] = 1;
      } else {
	v_unpacked[b*size/32+i] = -1;
      }
    }
  }
}


//scales are prescaled by 1 << 32 aka need to be less than 0.5/-0.5 else prescale by less and scale v_out
void dense_lve(vbx_word_t *v_out, vbx_word_t *v_in, dense_layer_t *layer)
{
    int x, i;
    vbx_word_t *v_biases  = v_out + layer->outputs*1;
    vbx_word_t *v_scales  = v_out + layer->outputs*2;
    vbx_word_t *v_weights = v_out + layer->outputs*3;
    vbx_word_t *v_buf0 = v_weights + layer->inputs*1;
    vbx_word_t *v_buf1 = v_weights + layer->inputs*2;

    vbx_word_t *v_dma[] = {v_buf0, v_buf1};

    // packed into 32x
    int buf = 0;
    vbx_flash_dma(v_dma[buf], layer->weights, layer->inputs/32*sizeof(vbx_word_t));

    for (x = 0; x < layer->outputs; x++) {
	if (x < layer->outputs -1) {
	  vbx_flash_dma_async(v_dma[!buf], layer->weights + (x+1)*layer->inputs/32*sizeof(vbx_word_t), layer->inputs/32*sizeof(vbx_word_t));
	}

	scalar_unpack_weights(v_weights, v_dma[buf], layer->inputs);

	int sum = 0;
	for (i = 0; i < layer->inputs; i++ ) {
	  sum += v_in[i] * v_weights[i];
	}
	v_out[x] = sum;

	if (x < layer->outputs -1) {
	  while(!flash_dma_done());
	}
	buf = !buf;
    }

    vbx_set_vl(layer->outputs);

    vbx_flash_dma(v_biases, layer->biases, layer->outputs*sizeof(vbx_word_t));
    for (i = 0; i < layer->outputs; i++ ) {
      v_out[i] += v_biases[i];
    }

    if (layer->scale) {
	vbx_flash_dma(v_scales, layer->scales, layer->outputs*sizeof(vbx_word_t));
	long long mul;
	for (i = 0; i < layer->outputs; i++ ) {
	  mul = (long long)v_out[i] * (long long)v_scales[i];
	  v_out[i] = (int)(mul >> 32);
	}
    }

    if (layer->activation_type == RELU) {
	scalar_relu(v_out, 1, layer->outputs);
    }
}


void scalar_convolve_ci(vbx_half_t *v_out, vbx_ubyte_t *v_in, vbx_half_t *v_conv, const int m, const int n, const short weights)
{
  int i, j, ki, kj, value;
  short sum0, sum1;
  for (j = 0; j < m; j++) {
    for (i = 0; i < m; i+=2) {
      sum0 = 0;
      sum1 = 0;
      for (kj = 0; kj < 3; kj++) {
	for (ki = 0; ki < 3; ki++) {
	  value = weights & (1<<(8-(kj*3+ki)));
	  if (value) {
	    sum0 += v_in[(j+kj)*(n+4)+(i+ki)];
	    sum1 += v_in[(j+kj)*(n+4)+(i+1+ki)];
	  } else {
	    sum0 -= v_in[(j+kj)*(n+4)+(i+ki)];
	    sum1 -= v_in[(j+kj)*(n+4)+(i+1+ki)];
	  }
	}
      }
      v_out[j*m+i]   += sum0;
      v_out[j*m+i+1] += sum1;
    }
  }
}

void scalar_zeropad_ci(vbx_ubyte_t *v_out, vbx_word_t *v_in, const int m, const int n)
{
    // zero map
    int j, i;
    for(j = 0; j < m+2; j++) {
      for(i = 0; i < n+2+2; i++) {
	v_out[j*(n+2+2)+i] = 0;
      }
    }

    // move in rows
    for (j = 0; j < m; j++) {
      for(i = 0; i < n; i++) {
	if (v_in[j*n+i] > 255) {
	  v_out[(j+1)*(n+2+2) + i+1] = 255;
	} else if (v_in[j*n+i] < 0) {
	  v_out[(j+1)*(n+2+2) + i+1] = 0;
	} else {
	  v_out[(j+1)*(n+2+2) + i+1] = v_in[j*n+i];
	}
      }
    }
}

// called once every 16 channels (touches data 3x)
void scalar_accumulate_columns(vbx_word_t *v_map, vbx_half_t *v_maph, const int m, const int n) 
{
  int i;
  // add each packed column to output
  for (i = 0; i < n*m; i++) {
    v_map[i] += (int)(v_maph[i]);
  }

  // zero v_maph for next round of accum
  for (i = 0; i < n*m; i++) {
    v_maph[i] = 0;
  }
}

// takes in padded inputs
void convolution_ci_lve(vbx_ubyte_t *v_outb, vbx_ubyte_t *v_inb, convolution_layer_t *layer, const int debug)
{
    int i, c, k, m = layer->m, n = layer->n, m0 = m, n0 = n;
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
	for (i = 0; i < n*m; i++) {
	  v_map[i] = v_dma[buf][0];
	  v_maph[i] = 0;
	}

	for (c = 0; c < layer->channels; c++) {
	    scalar_convolve_ci(v_maph, v_inb + c*(m+2)*(n+4), (vbx_half_t*)v_tmp, m, n, v_weights[c]);
	    if ((c+1)%16 == 0) {
	      scalar_accumulate_columns(v_map, v_maph, m, n);
	    }
	}
	if (layer->channels % 16) {
	    scalar_accumulate_columns(v_map, v_maph, m , n);
	}

	if (layer->maxpool) {
	    scalar_pool(v_map, m, n);
	}

	vbx_set_vl(m0*n0);
	if (layer->scale) {
	    long long mul;
	    for (i = 0; i < m0*n0; i++) {
	      mul = (long long)v_map[i] * (long long)v_dma[buf][1];
	      v_map[i] = (int)(mul >> 32);
	    }
	}

	if (!layer->zeropad_output && layer->activation_type == RELU) {
	    scalar_relu(v_map, m0, n0);
	}
	if (layer->zeropad_output) {
	  scalar_zeropad_ci(v_outb+(k*(n0+4)*(m0+2)), v_map, m0, n0);
	} else {
	  vbx_word_t* v_out = (vbx_word_t*)v_outb;
	  for (i = 0; i < m0*n0; i++) {
	    v_out[k*n0*m0+i] = v_map[i];
	  }
	}

	if (k < layer->kernels-1) {
	  while(!flash_dma_done());
	}
	buf = !buf;
    }
}
