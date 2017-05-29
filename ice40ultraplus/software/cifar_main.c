#include "neural.h"
#include "time.h"
#include "ovm7692.h"
#include "base64.h"
#include "sccb.h"

#define USE_CAM_IMG 1
#define PRINT_B64_IMG 0

#define SP0 (SCRATCHPAD_BASE+0*1024)
#define SP4 (SCRATCHPAD_BASE+4*1024)
#define SP44 (SCRATCHPAD_BASE+44*1024)
#define SP84 (SCRATCHPAD_BASE+84*1024)

void transfer_network(layer_t *cifar, const int dst, const int src, const int verbose)
{
	int k, l = 0, offset = 0, koffset, dma_size, dma_pad;
	while(1) {
		if (cifar[l].layer_type == CONV) {
			dma_size = (2*4 + 2*cifar[l].conv.channels);
			dma_pad = dma_size % 4;

			koffset = 0;
			for (k=0; k < cifar[l].conv.kernels; k++) {
				vbx_flash_dma((vbx_void_t*)(dst+offset+koffset), cifar[l].conv.weights + dma_size*k, dma_size+dma_pad);
				koffset += dma_size+dma_pad;
			}
			if (verbose) {
				printf("conv layer\r\n");
			}
			cifar[l].conv.weights = dst+offset;
			offset += koffset;

			if (cifar[l].conv.last) break;
		} else {
			dma_size = cifar[l].dense.inputs/32*4*cifar[l].dense.outputs;
			if(verbose){
				printf("dense layer weights\r\n");
			}
			vbx_flash_dma((vbx_void_t*)(dst+offset), cifar[l].dense.weights, dma_size);
			cifar[l].dense.weights = dst+offset;
			offset += dma_size;

			dma_size = cifar[l].dense.outputs*4;
			if(verbose){
				printf("dense layer biases\r\n");
			}
			vbx_flash_dma((vbx_void_t*)(dst+offset), cifar[l].dense.biases, dma_size);
			cifar[l].dense.biases = dst+offset;
			offset += dma_size;

			dma_size = cifar[l].dense.outputs*4;
			if (verbose) {
				printf("dense layer scales\r\n");
			}
			vbx_flash_dma(((vbx_word_t*)dst)+offset/4, cifar[l].dense.scales, dma_size);
			cifar[l].dense.scales = dst+offset;
			offset += dma_size;

			if (cifar[l].dense.last) break;
		}
		l++;
	}
}

//expects 3 padded 32x32 byte images at SCRATCHPAD_BASE+80*1024, output @ SCRATCHPAD_BASE
void run_network(layer_t *cifar, const int verbose)
{
	int l = 0, buf = 0;
	vbx_ubyte_t* v_outb;
	vbx_ubyte_t* v_padb;
	vbx_word_t* v_in;
	vbx_word_t* v_out;
	unsigned time;
	while(1) {
		if(verbose){
			time=get_time();
		}
		if (cifar[l].layer_type == CONV) {
			if(verbose){
				printf("conv layer\r\n");
			}
			if (!buf) {
				v_outb = (vbx_ubyte_t*)SP4;
				v_padb = (vbx_ubyte_t*)SP84;
			} else {
				v_padb = (vbx_ubyte_t*)SP4;
				v_outb = (vbx_ubyte_t*)SP84;
			}
			convolution_ci_lve(v_outb, v_padb, &(cifar[l].conv), 0);
			if (cifar[l].conv.last) break;
		} else {
			if(verbose){
				printf("dense layer\r\n");
			}
			if (!buf) {
				v_out = (vbx_word_t*)SP4;
				v_in = (vbx_word_t*)SP84;
			} else {
				v_in = (vbx_word_t*)SP4;
				v_out = (vbx_word_t*)SP84;
			}
			dense_lve(v_out, v_in, &(cifar[l].dense));
			if (cifar[l].dense.last) break;
		}
		buf = !buf;
		l++;
		if(verbose){
			time=get_time()-time;
			printf("layer took %u cycles %u ms \r\n",time,cycle2ms(time));
		}
	}
}


#if USE_CAM_IMG
void cam_extract_and_pad(vbx_ubyte_t* channel,vbx_word_t* rgba_in,int byte_sel,int rows,int cols,int pitch)
{
	int c,r;
	//channel reverse
	if(byte_sel==2){
		byte_sel=0;
	}else if(byte_sel ==0){
		byte_sel =2;
	}
	for(r=0;r<rows+2;r++){
		for(c=0;c<cols+4;c++){

			int pixel;
			if (c==0 || r==0 ||
			    c>=cols+1 || r>=rows+1){
				pixel=0;
			}else {
				pixel=rgba_in[(r-1)*pitch+(c-1)];
			}
			pixel=(pixel>>(byte_sel*8))&0xFF;
			channel[r*(cols+4) + c]=pixel;
		}
	}
}
#endif

void zeropad_input(vbx_ubyte_t *v_out, vbx_ubyte_t *v_in, const int m, const int n)
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
			v_out[(j+1)*(n+2+2) + i+1] = v_in[j*n+i];
		}
	}
}

void cifar_lve() {

	printf("CES demo\r\n");
	printf("Lattice\r\n");

		//wait while initializing
	while(FLASH_DMA_BASE[FLASH_DMA_STATUS] & 0x80000000){
		printf("waiting for Flash initialization\r\n");
	}

	init_lve();
	//enable output on LED
	SCCB_PIO_BASE[PIO_ENABLE_REGISTER] |= (1<<PIO_LED_BIT);
#if USE_CAM_IMG
	ovm_initialize();
#endif
	int frame_num=0;
	int is_face=0;
	int max_cat;
	int c, m = 32, n = 32, verbose = 0;
	vbx_ubyte_t* v_padb = (vbx_ubyte_t*)SP84; // IMPORTANT: padded input placed here
	vbx_word_t* v_out = (vbx_word_t*)  SP4; // IMPORTANT: 10 outputs produced here
	vbx_ubyte_t* v_inb = (vbx_ubyte_t*)SP0;

#if CATEGORIES == 10
	char *categories[] = {"air", "auto", "bird", "cat", "person", "dog", "frog", "horse", "ship", "truck"};
#else
	char *categories[] = {"noface","face"};
#endif

	printf("categories:\r\n");
	for (c = 0; c < CATEGORIES; c++) {
		printf("%s\r\n", categories[c]);
	}


	//boot loop
	int i=0;
	for(i=0;i<3*4;i++){
	    //turn off led
		SCCB_PIO_BASE[PIO_DATA_REGISTER] |= (1<<PIO_LED_BIT);
		delayms(125);
		//turn off led
		SCCB_PIO_BASE[PIO_DATA_REGISTER] &= ~(1<<PIO_LED_BIT);
		delayms(125);
	}

	layer_t* network=CES_GOLDEN? cifar_golden:cifar_reduced;
	transfer_network(network, SP44, REDUCED_FLASH_DATA_OFFSET, verbose);

#if USE_CAM_IMG
	/* ovm_get_frame_async(); */
#endif

	do{
		unsigned start_time=get_time();


#if USE_CAM_IMG

		//turn on led during camera capture
		SCCB_PIO_BASE[PIO_DATA_REGISTER] |= (1<<PIO_LED_BIT);

		//get camera frame
		/* ovm_wait_frame(); */
		ovm_get_frame();

		//if not face, turn off led
		if(!is_face) {
			SCCB_PIO_BASE[PIO_DATA_REGISTER] &= ~(1<<PIO_LED_BIT);
		}


#if PRINT_B64_IMG

		//print base64 encoding of rgb image
		char* rgb_plane = (char*)v_padb;
		int b64_time=get_time();
		int row,col;
		for(row=0;row<30;row++){
			for(col=0;col<32;col++){
				rgb_plane[3*(row*32+col)+0]= v_inb[4*(row*64+col) +0];
				rgb_plane[3*(row*32+col)+1]= v_inb[4*(row*64+col) +1];
				rgb_plane[3*(row*32+col)+2]= v_inb[4*(row*64+col) +2];

			}
		}

		printf("base64:");
		print_base64((char*)rgb_plane,3*32*32);
		printf("\r\n");
		b64_time=get_time()-b64_time;
		//adjust start_time to elimate time spent printing base64 image
		start_time+=b64_time;
#endif

		for (c = 0; c < 3; c++) {
			cam_extract_and_pad(v_padb + c*(m+2)*(n+4), (vbx_word_t*)v_inb,c, m, n, 64);
		}
		/* ovm_get_frame_async(); */

#else

		// dma in test image
		int test_img_offset= GOLDEN_FLASH_DATA_OFFSET;
		vbx_flash_dma((vbx_word_t*)v_inb, test_img_offset+0, (3*m*n)*sizeof(vbx_ubyte_t));

		// zero pad imaged w/ bytes
		for (c = 0; c < 3; c++) {
			zeropad_input(v_padb + c*(m+2)*(n+4), v_inb + c*m*n, m, n);
		}
#endif
		run_network(network, verbose);

		// print results (or toggle LED if person is max, and > 0)
		max_cat = 0;
		for (c = 0; c < CATEGORIES; c++) {
			if(v_out[c] > v_out[max_cat] ){
				max_cat = c;
			}
		}
		is_face = (max_cat == 1);

		if (verbose) {
			for (c = 0; c < CATEGORIES; c++) {
				printf("%s\t%d\r\n", categories[c], (int)v_out[c]);
			}
		}
		unsigned net_cycles=get_time()-start_time;
		unsigned net_ms=cycle2ms(net_cycles);
		printf("Frame %d: %u ms Face Score = %d \r\n",frame_num++,net_ms,(int) v_out[1]);

	} while(USE_CAM_IMG);
}
