

#include "printf.h"
#include "sccb.h"
#include "ovm7692.h"
#include "time.h"
#include "vbx.h"
#include "base64.h"



// image speckle removing, based on median filter
// compare 3 horizontal pixels, replace center with median value
/*
  static void h_denoise( uchar* buf )
  {
  uchar out, t;
  int off, r, c;
  for(r=0;r<rgb_v;r++){
  c=0;
  off = (rgb_pad_t+r)*rgb_pad_h + rgb_pad_l + (c-0);
  out = buf[off];
  for(c=1;c<rgb_h-1;c++){
  off = (rgb_pad_t+r)*rgb_pad_h + rgb_pad_l + (c-0);
  uchar pl = buf[off-1];
  uchar pc = buf[off-0];
  uchar pr = buf[off+1];
  if( pl > pc ) { t=pl; pl=pc; pc=t; }
  if( pc > pr ) { t=pc; pc=pr; pr=t; }
  if( pl > pc ) { t=pl; pl=pc; pc=t; }
  buf[off-1] = out;
  out = pc;
  }
  buf[off]=out;
  }
  }

  // image speckle removing, based on median filter
  // compare 3 vertical pixels, replace center with median value
  static void v_denoise( uchar* buf )
  {
  uchar out, t;
  int off, r, c;
  for(c=0;c<rgb_h;c++){
  r=0;
  off = (rgb_pad_t+r)*rgb_pad_h + rgb_pad_l + (c-0);
  out = buf[off];
  for(r=1;r<rgb_v-1;r++){
  off = (rgb_pad_t+r)*rgb_pad_h + rgb_pad_l + (c-0);
  uchar pl = buf[off-rgb_pad_h];
  uchar pc = buf[off-0];
  uchar pr = buf[off+rgb_pad_h];
  if( pl > pc ) { t=pl; pl=pc; pc=t; }
  if( pc > pr ) { t=pc; pc=pr; pr=t; }
  if( pl > pc ) { t=pl; pl=pc; pc=t; }
  buf[off-rgb_pad_h] = out;
  out = pc;
  }
  buf[off]=out;
  }
  }
*/

int main()
{
	printf("\r\nTESTING OVM\r\n");
	init_lve();

	//set the bottom of the scratchpad to skip the camera dma buffer
	the_lve.sp_base = ((char*)SCRATCHPAD_BASE)+( 64*32*4);
	the_lve.sp_ptr = ((char*)SCRATCHPAD_BASE)+( 64*32*4);

	char* r_plane = (char*)vbx_sp_alloc(34*40);
	char* g_plane=	 (char*)vbx_sp_alloc(34*40);
	char* b_plane=  (char*)vbx_sp_alloc(34*40);

	//EXTRA,just used for opencv display
	char* rgb_plane=(char*)vbx_sp_alloc(34*40*3);

	int rgb_rows=34,rgb_cols=40;

	int off;
	if(ovm_initialize(r_plane,g_plane,b_plane)){
		printf("Initializtion Failed\r\n");
		return 1;
	}else{
		printf("Initializtion Done\r\n");
	}

	while(1){
		printf("Get frame\r\n");
		int frame_time = get_time();
		if(ovm_get_frame()){
			printf("Get frame Failed\r\n");
		}else{
			frame_time=get_time()-frame_time;
			printf("Done Get frame. Took %d cycles %d ms\r\n",frame_time,cycle2ms(frame_time));
		}

		//recombine plane for OPENCV display
		for(off=0;off<rgb_rows*rgb_cols;off++){
			rgb_plane[3*off+0]/*CV_FRAME2: R*/ = r_plane[off];
			rgb_plane[3*off+1]/*CV_FRAME1: G*/ = g_plane[off];
			rgb_plane[3*off+2]/*CV_FRAME0: B*/ = b_plane[off];

		}

		printf("base64:");
		print_base64((char*)rgb_plane,3*rgb_rows*rgb_cols);
		printf("\r\n");

		//delayms(2000);
	}

	return 0;
}
