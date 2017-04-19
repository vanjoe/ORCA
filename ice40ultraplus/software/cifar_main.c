#include "neural.h"
#include "time.h"
#include "ovm7692.h"
#include "base64.h"
#include "sccb.h"

#define USE_CAM_IMG 1
#define PRINT_B64_IMG 1


//expects 3 padded 32x32 byte images at SCRATCHPAD_BASE+80*1024, output @ SCRATCHPAD_BASE
void run_network(const int verbose,layer_t *cifar)
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
				v_outb = (vbx_ubyte_t*)(SCRATCHPAD_BASE+0*1024);
				v_padb = (vbx_ubyte_t*)(SCRATCHPAD_BASE+80*1024);
			} else {
				v_padb = (vbx_ubyte_t*)(SCRATCHPAD_BASE+0*1024);
				v_outb = (vbx_ubyte_t*)(SCRATCHPAD_BASE+80*1024);
			}
			convolution_ci_lve(v_outb, v_padb, &(cifar[l].conv), 0);
			if (cifar[l].conv.last) break;
		} else {
			if(verbose){
				printf("dense layer\r\n");
			}
			if (!buf) {
				v_out = (vbx_word_t*)(SCRATCHPAD_BASE+0*1024);
				v_in = (vbx_word_t*)(SCRATCHPAD_BASE+80*1024);
			} else {
				v_in = (vbx_word_t*)(SCRATCHPAD_BASE+0*1024);
				v_out = (vbx_word_t*)(SCRATCHPAD_BASE+80*1024);
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
	printf("Testing convolution ci\r\n");

	init_lve();
	//enable output on LED
	SCCB_PIO_BASE[PIO_ENABLE_REGISTER] |= (1<<PIO_LED_BIT);
#if USE_CAM_IMG
	ovm_initialize();
	int last_max_cat=0;
#endif

	int max_cat=0;

	int c, m = 32, n = 32, verbose = 0;
	vbx_ubyte_t* v_padb = (vbx_ubyte_t*)(SCRATCHPAD_BASE+80*1024); // IMPORTANT: padded input placed here
	vbx_word_t* v_out = (vbx_word_t*)  (SCRATCHPAD_BASE+0*1024); // IMPORTANT: 10 outputs produced here
	vbx_ubyte_t* v_inb = (vbx_ubyte_t*)(SCRATCHPAD_BASE+0*1024);
	char *categories[] = {"air", "auto", "bird", "cat", "person", "dog", "frog", "horse", "ship", "truck"};
	printf("catagories:\r\n");
	for (c = 0; c < 10; c++) {
		printf("%s\r\n", categories[c]);
	}
	do{
		unsigned start_time=get_time();


#if USE_CAM_IMG
		//get camera frame
		if(last_max_cat != 4 /*person*/){
			//turn on led
			SCCB_PIO_BASE[PIO_DATA_REGISTER] |= (1<<PIO_LED_BIT);
		}else {
			//turn off led
			SCCB_PIO_BASE[PIO_DATA_REGISTER] &= ~(1<<PIO_LED_BIT);
		}
		ovm_get_frame();
		last_max_cat = max_cat;
		if(max_cat == 4 /*person*/){
			//turn on led
			SCCB_PIO_BASE[PIO_DATA_REGISTER] |= (1<<PIO_LED_BIT);
			if(verbose){
				printf("PERSON DETECTED %d\r\n ",(int)v_out[max_cat]);
			}
		}else {
			//turn off led
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
		//hack for cleaning up last two rows
		if(max_cat==4){
			rgb_plane[3*(row*32)]= 0xFF;
		}else{
			rgb_plane[3*(row*32)]= 0;
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

#else

		// dma in test image (or get from camera!!)
		int test_img_offset= CES_GOLDEN?GOLDEN_FLASH_DATA_OFFSET:REDUCED_FLASH_DATA_OFFSET;
		vbx_flash_dma((vbx_word_t*)v_inb, test_img_offset+0, (3*m*n)*sizeof(vbx_ubyte_t));

		// zero pad imaged w/ bytes
		for (c = 0; c < 3; c++) {
			zeropad_input(v_padb + c*(m+2)*(n+4), v_inb + c*m*n, m, n);
		}
#endif
		layer_t* network=CES_GOLDEN? cifar_golden:cifar_reduced;
		run_network(verbose,network);

		// print results (or toggle LED if person is max, and > 0)
		printf("scores: ");
		for (c = 0; c < 10; c++) {
			if(v_out[c] > v_out[max_cat] ){
				max_cat =c;
			}
			printf("%d\t", (int)v_out[c]);
		}
		printf("\r\n");

		if (verbose) {
			for (c = 0; c < 10; c++) {
				printf("%s\t%d\r\n", categories[c], (int)v_out[c]);
			}
		}

#if 1
#endif
		unsigned net_cycles=get_time()-start_time;
		unsigned net_ms=cycle2ms(net_cycles);
		printf("Frame processing took %u cycles %u ms \r\n",net_cycles,net_ms);

	}while(USE_CAM_IMG);
}
