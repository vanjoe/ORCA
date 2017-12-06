#include "neural.h"

__attribute__((unused)) static  int channel_sum(vbx_ubyte_t* chan,int size) {
	int sum=0;
	while(size--){
		sum+=chan[size];
	}
	return sum;
}
__attribute__((unused)) static  int channel_sumh(vbx_half_t* chan,int size) {
	int sum=0;
	while(size--){
		sum+=chan[size];
	}
	return sum;
}
__attribute__((unused)) static  int channel_sumw(vbx_word_t* chan,int size) {
	int sum=0;
	while(size--){
		sum+=chan[size];
	}
	return sum;
}

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
	vbx_set_vl(1,width*height/2);
	int stride=2*sizeof(vbx_word_t);
	vbx_set_2D(stride,stride,stride);
	vbx(VVW, VSLT, v_pool, v_out, v_out+1);
	vbx(VVW, VCMV_NZ, v_out, v_out+1, v_pool);
	for (i = 0; i < width*height/2; i++) {
		v_out[i] = v_out[i*2];
	}


	vbx_set_vl(width/2,1);
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

	vbx_set_vl(1,m+2);
	vbx_set_2D(sizeof(vbx_half_t)*(n+4),sizeof(vbx_byte_t)*(n+4),sizeof(vbx_byte_t)*(n+4));

	for(x = 0; x < n; x +=2) {
		vbx(VVW, VCUSTOM2,
		    (vbx_word_t*)(v_conv + x),
		    (vbx_word_t*)((vbx_byte_t*)v_in + x),
		    (vbx_word_t*)((vbx_byte_t*)v_in + x + 4));
	}

	vbx_set_vl(n/2);
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
	vbx_set_vl(1,n+2+2);
	vbx_set_2D(sizeof(vbx_byte_t),sizeof(vbx_word_t),sizeof(vbx_word_t));


	vbx(VVW, VCUSTOM0, (vbx_word_t*)((vbx_byte_t*)v_out + (0)*(n+2+2)), v_pad, 0);
	vbx(VVW, VCUSTOM0, (vbx_word_t*)((vbx_byte_t*)v_out + (m+1)*(n+2+2)), v_pad, 0);
	// move in rows
	for (y = 0; y < m; y++) {
		vbx_set_vl(n);
		vbx(SVW, VOR, v_pad + 1,0, v_in + y*n);
		vbx_set_vl(1,n+2+2);
		//2D strides are still correct
		vbx(VVW, VCUSTOM0,(vbx_word_t*)((vbx_byte_t*)v_out + (y+1)*(n+2+2)), v_pad, 0);
	}
}

void vbx_accumulate_columns(vbx_word_t *v_map, vbx_half_t *v_maph, vbx_word_t *v_tmp, const int m, const int n)
{
	// add each packed column to output
	vbx_set_vl(1,n/2*m);
	vbx_set_2D(2*sizeof(vbx_word_t),2*sizeof(vbx_half_t),2*sizeof(vbx_half_t));
	vbx(SVW, VMUL, v_tmp, (1<<16), (vbx_word_t*)v_maph);
	vbx_set_2D(2*sizeof(vbx_word_t),2*sizeof(vbx_word_t),2*sizeof(vbx_word_t));
	vbx(SVW, VMULH, v_tmp, (1<<16), v_tmp);
	vbx_set_2D(2*sizeof(vbx_word_t),2*sizeof(vbx_half_t),2*sizeof(vbx_half_t));
	vbx(SVW, VMULH, v_tmp + 1, (1<<16), (vbx_word_t*)v_maph);

	vbx_set_vl(n*m);
	vbx(VVW, VADD, v_map, v_map, v_tmp);

	// zero v_maph for next round of accum
	vbx_set_vl(n/2*m);
	vbx(SVW, VAND, (vbx_word_t*)v_maph, 0, (vbx_word_t*)v_maph);
}

// takes in padded inputs

void convolution_ci_lve(vbx_ubyte_t *v_outb, vbx_ubyte_t *v_inb, convolution_layer_t *layer, const int debuglayer)
{
	int c, k, m = layer->m, n = layer->n, m0 = m, n0 = n;
	if (layer->maxpool) {
		m0 = m/2; n0 = n/2;
	}

	int32_t bias, scale;

	// assumes 128K scratch
	vbx_word_t *v_map = (vbx_word_t*)(SCRATCHPAD_BASE + 114*1024);
	vbx_half_t *v_maph = (vbx_half_t*)(SCRATCHPAD_BASE + 118*1024);
	vbx_word_t *v_tmp = (vbx_word_t*)(SCRATCHPAD_BASE + 120*1024);
	int dma_size = 2*4 + layer->channels*2;
	int dma_pad = dma_size % 4;
	vbx_word_t *v_packed;
	vbx_uhalf_t *v_weights;

	for (k = 0; k < layer->kernels; k++) {
		v_packed = (vbx_word_t*)(layer->weights + k*(dma_size+dma_pad));
		bias = v_packed[0];
		scale = v_packed[1];
		v_weights = (vbx_uhalf_t*)(v_packed + 2);

		// set kernel bias
		vbx_set_vl(n*m);
		vbx(SVW, VAND, v_map, 0, v_map);
		vbx(SVW, VOR, v_map, bias, v_map);

		vbx_set_vl(n/2*m);
		vbx(SVW, VAND, (vbx_word_t*)v_maph, 0, (vbx_word_t*)v_maph);

		for (c = 0; c < layer->channels; c++) {
			vbx_convolve_ci(v_maph, v_inb + c*(m+2)*(n+4), (vbx_half_t*)v_tmp, m, n, v_weights[c]);
			if ((c+1)%13 == 0) {
				vbx_accumulate_columns(v_map, v_maph, v_tmp, m, n);
			}
		}
		if (layer->channels % 13) {
			vbx_accumulate_columns(v_map, v_maph, v_tmp, m , n);
		}
		if (layer->maxpool) {
			vbx_pool(v_map, v_tmp, m, n);
		}
		vbx_set_vl(m0*n0);
		if (layer->scale) {
			if (layer->zeropad_output) {
				vbx(SVW, VMULH, v_map, scale, v_map);
			} else {
				vbx(SVW, VMUL, v_map, scale, v_map);
			}
		}
		if (!layer->zeropad_output && layer->activation_type == RELU) {
			vbx_relu(v_map, v_tmp);
		}
		if (layer->zeropad_output) {
			vbx_zeropad_ci(v_outb+(k*(n0+4)*(m0+2)), v_tmp, v_map, m0, n0);
		} else {
			#if 1
			//FIXME: For some reason the VMOV doesn't work, manually copying.
			for(int i=0;i<m0*n0;i++){
				((vbx_word_t*)v_outb+(k*n0*m0))[i]=v_map[i];
			}
			#else
			vbx_set_vl(m0*n0);
			vbx(VVW, VMOV, (vbx_word_t*)v_outb+(k*n0*m0),v_map,0);
			#endif
		}
	}
}

void dense_lve(vbx_word_t *v_out, vbx_word_t *v_in, dense_layer_t *layer)
{
	int x;
	vbx_word_t *v_biases  = (vbx_word_t *)layer->biases;
	vbx_word_t *v_scales  = (vbx_word_t *)layer->scales;
	vbx_word_t *v_packed = (vbx_word_t *)layer->weights; // packed into 32x
	vbx_word_t *v_weights = v_out + layer->outputs*3;
	vbx_word_t *v_relu = v_in;

	for (x = 0; x < layer->outputs; x++) {
		vbx_unpack_weights(v_weights, v_packed + x*layer->inputs/32, layer->inputs);
		vbx_set_vl(layer->inputs);
		vbx_acc(VVW, VMUL, v_out + x, v_in, v_weights);
	}

	vbx_set_vl(layer->outputs);
	vbx(VVW, VADD, v_out, v_out, v_biases);

	if (layer->scale) {
		vbx(VVW, VMULH, v_out, v_out, v_scales);
	}

	if (layer->activation_type == RELU) {
		vbx_relu(v_out, v_relu);
	}
}
