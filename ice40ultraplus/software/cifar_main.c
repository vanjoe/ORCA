#include "neural.h"
#include "time.h"
#include "ovm7692.h"
#include "base64.h"
#include "sccb.h"

//expects 3 padded 32x32 byte images at SCRATCHPAD_BASE+80*1024, output @ SCRATCHPAD_BASE
void run_network(const int verbose)
{
  int l = 0, buf = 0;
  vbx_ubyte_t* v_outb;
  vbx_ubyte_t* v_padb;
  vbx_word_t* v_in;
  vbx_word_t* v_out;

  while(1) {
    if (cifar[l].layer_type == CONV) {
      printf("conv layer\r\n");
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
      printf("dense layer\r\n");
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
  }
}

#define USE_CAM_IMG 0
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
#endif

  do{
	  unsigned start_time=get_time();
	  int c, m = 32, n = 32, verbose = 1;
	  vbx_ubyte_t* v_padb = (vbx_ubyte_t*)(SCRATCHPAD_BASE+80*1024); // IMPORTANT: padded input placed here
	  vbx_word_t* v_out = (vbx_word_t*)(SCRATCHPAD_BASE+0*1024); // IMPORTANT: 10 outputs produced here
	  vbx_ubyte_t* v_inb = (vbx_ubyte_t*)(SCRATCHPAD_BASE+0*1024);


#if USE_CAM_IMG
#if 0
	  //zero the img buffer first (uncomment for better presentation
	  vbx_set_vl(32*64);
	  vbx(SVW,VAND,(vbx_word_t*)v_inb,0,(vbx_word_t*)v_inb);
#endif


	  ovm_get_frame();
	 //print base64 encoding of rgb image
	 char* rgb_plane = (char*)v_padb;
	 int off;

	 for(off=0;off<32*64;off++){
		rgb_plane[3*off+0]/*CV_FRAME2: R*/ = v_inb[4*off+2];
		rgb_plane[3*off+1]/*CV_FRAME1: G*/ = v_inb[4*off+1];
		rgb_plane[3*off+2]/*CV_FRAME0: B*/ = v_inb[4*off+0];
	 }
#if 0
	 printf("base64:");
	 print_base64((char*)rgb_plane,3*32*64);
	 printf("\r\n");
#endif
	 for (c = 0; c < 3; c++) {
	     cam_extract_and_pad(v_padb + c*(m+2)*(n+4), (vbx_word_t*)v_inb,c, m, n, 64);
	 }

#else

	  // dma in test image (or get from camera!!)
	  vbx_flash_dma((vbx_word_t*)v_inb, FLASH_DATA_OFFSET+0, (3*m*n)*sizeof(vbx_ubyte_t));

	  // zero pad imaged w/ bytes
	  for (c = 0; c < 3; c++) {
	      zeropad_input(v_padb + c*(m+2)*(n+4), v_inb + c*m*n, m, n);
	  }
#endif

	  run_network(verbose);
	  int max_cat=0;
		  // print results (or toggle LED if person is max, and > 0)
	  char *categories[] = {"air", "auto", "bird", "cat", "person", "dog", "frog", "horse", "ship", "truck"};
	  for (c = 0; c < 10; c++) {
		  if(v_out[c] > v_out[max_cat] ){
			  max_cat =c;
		  }
		  if (verbose) {
			  printf("%s\t%d\r\n", categories[c], (int)v_out[c]);
		  }
	  }
#if 1

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
#endif
	  if(verbose){
		  printf("network took %d ms\r\n",cycle2ms(get_time()-start_time));
	  }

  }while(USE_CAM_IMG);
}
