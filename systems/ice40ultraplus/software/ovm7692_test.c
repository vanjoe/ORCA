

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

	int rgb_rows=32,rgb_cols=64;
	char* rgba_plane=(char*)SCRATCHPAD_BASE;
	//set the bottom of the scratchpad to skip the camera dma buffer
	the_lve.sp_base = ((char*)SCRATCHPAD_BASE)+(rgb_rows*rgb_cols*4);
	the_lve.sp_ptr = ((char*)SCRATCHPAD_BASE)+ (rgb_rows*rgb_cols*4);
	//EXTRA,just used for opencv display
	char* rgb_plane=(char*)vbx_sp_alloc(34*40*3);




	int off;
	if(ovm_initialize()){
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
			rgb_plane[3*off+0]/*CV_FRAME2: R*/ = rgba_plane[4*off+0];
			rgb_plane[3*off+1]/*CV_FRAME1: G*/ = rgba_plane[4*off+1];
			rgb_plane[3*off+2]/*CV_FRAME0: B*/ = rgba_plane[4*off+2];
		}
		printf("base64:");
		print_base64((char*)rgb_plane,3*rgb_rows*rgb_cols);
		printf("\r\n");

		//delayms(2000);
	}

	return 0;
}
