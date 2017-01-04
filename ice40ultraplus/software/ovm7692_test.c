

#include "printf.h"
#include "sccb.h"
#include "ovm7692.h"
#include "time.h"
#include "vbx.h"
#include "base64.h"
#define SCCB_PIO_BASE   ((void *)0x00050000)

typedef unsigned char uchar;
typedef unsigned int  uint;

void ovm_write_reg(int reg_addr,int reg_val)
{
	sccb_write(SCCB_PIO_BASE, OVM7692_ADDRESS, reg_addr, reg_val);
}

int ovm_read_reg(int reg_addr)
{
	return sccb_read(SCCB_PIO_BASE, OVM7692_ADDRESS, reg_addr);
}

typedef struct{
	uint8_t addr,val;
} regval_t;


void ovm_set_start()
{
	((volatile int*)SCCB_PIO_BASE)[PIO_DATA_REGISTER]|=(1<<2);
}

void ovm_clear_start()
{
	((volatile int*)SCCB_PIO_BASE)[PIO_DATA_REGISTER]&=(~(1<<2));
}


int ovm_isdone()
{
	return !(((volatile int*)SCCB_PIO_BASE)[PIO_DATA_REGISTER] & (1<<3));

}

#if 0
static const regval_t regval_list[] ={
	// STARTUP
	{ 0x12, 0x00}, // end RESET
	{ 0x12, 0x80}, //  start RESET

	{0x3e, 0x30},
	{0x28, 0x00}, /* VSYNC NEG */
	{0x11, 0x00}, /* Internal clock dividers, 30 fps default */
	{0x5e, 0x10}, /* Divided PCLK */
	{0x0e, 0x00},/* Exit sleep mode necessary */
	// VGA ARRAY
#if 0
	{ 0x12, 0x80}, // start RESET
	{ 0x0e, 0x08}, // enable sleep mode
#endif
	// ...other init stuff...

	// DEVICE INIT
	// { 0x3e, 0x30}, //1/2 of regular PCLK, MIPI clk in YUV/RGB
	// { 0x28, 0x04 }, // VSYNG active on rising PCLK
	{ 0x11, 0x00}, // set 30fps
	// { 0x0C, 0x36}, // swap Blue and Red in RGB565
	{ 0x0C, 0x16}, // original Blue and Red in RGB565
	{ 0x0C, 0xD6}, // horizontal and vertical mirror
	// { 0x5e 0x10}, // divided PCLK
	// { 0x37 0x14}, // output PCLK/2
	{ 0x61, 0x00}, // no test pattern
	// { 0x61, 0x60}, // 8b test pattern
	//	{ 0x61, 0x70}, // 8b test pattern (model2)
	// { 0x64, 0x11}, // set PCLK to SCLK
	// { 0x64, 0x21}, // set PCLK to SCLK/2
	//{ 0x37, 0x1c},
	{ 0x30, 0x06 }, // sets PCLK to SCLK/2 using PLL /2 prescaler
	{ 0x12, 0x00}, // end RESET
	{ 0x12, 0x06}, // set RGB565

	{ 0x0e, 0x00}, // exit sleep mode

	// FRAMERATE (30fps)
	// set it again?
};
#else
#include "ovm7692_reg.c"
#endif


int ovm_configure()
{
	printf("STARTING OVM configuration\r\n");
	delayms(500);
	printf("Done Delay\r\n");
	sccb_init(SCCB_PIO_BASE);

	uint8_t pidh = ovm_read_reg(OVM7692_SUBADDRESS_PIDH);
	uint8_t pidl = ovm_read_reg(OVM7692_SUBADDRESS_PIDL);
	debugx(pidh);
	debugx(pidl);
	if((pidh != OVM7692_DEFAULT_PIDH) || (pidl != OVM7692_DEFAULT_PIDL)){
		printf("Error: BAD ,model ID\r\n");
		return 1;
	}
	ovm_write_reg(0x12, 0x06);
	if(ovm_read_reg(0x12) != 0x6){
		printf("Error: WRITE FAILED \r\n");
		return 1;
	}
	int i;
	printf("Writing Configuration Registers...");
	for(i=0;i<(sizeof(regval_list)/sizeof(regval_list[0]));i++){
		ovm_write_reg(regval_list[i].addr,regval_list[i].val);
		delayms(2);
	}

#if 1 /* dump configuration registers*/
	printf("\r\n");
	for(i=0;i<256;i++){
		printf("%02x  %02x\r\n",i,ovm_read_reg(i));
		if((i&0xF)==0xF){
			printf("\r\n");
		}
	}
#endif

	printf("Done\r\n");
	return 0;
}

#if 0
char gray2txt[]=" .'`,^:\";~-_+<>i!lI? /\\|()1{}[]rcvunxzjftLCJUYXZO0Qoahkbdpqwm*WMB8&%$#@";
void print_pic( uchar* pix,int cols,int rows,int stride)
{
	int  num_gray=sizeof(gray2txt);
	int i,j;
	for(i=0;i<rows;i++) {
		for(j=0;j<cols;j++) {
			int r = pix[i*stride*3 + j*3];
			int g = pix[i*stride*3 + j*3];
			int b = pix[i*stride*3 + j*3];
			int gray = (213*r + 715*g + 72*b)*num_gray/(255*1000);
			char txt = gray2txt[gray];
			mputc(0,txt);mputc(0,txt);
		}
		mputc(0,'\r');		mputc(0,'\n');
	}

}
#endif

void clear_frame( uchar *pixmap, int num_bytes )
{
	int i;
	for( i=0; i<num_bytes; i++ ) {
		pixmap[i] =0;
	}
}

void print_reg( int reg, char *description )
{
	int val = ovm_read_reg( reg );
	printf("reg(0x%02x) = 0x%02x <--  %s", reg, val, description );
}

void printf_rgb( uchar red, uchar grn, uchar blu )
{
	int i,b;
	printf("r");
	for( i=0x80; i; i>>=1 ) { b = red & i; mputc(0, b?'1':'0' ); }
	printf("_g");
	for( i=0x80; i; i>>=1 ) { b = grn & i; mputc(0, b?'1':'0' ); }
	printf("_b");
	for( i=0x80; i; i>>=1 ) { b = blu & i; mputc(0, b?'1':'0' ); }
	printf(" | ");
}

void printf_bin(uint rgb565)
{
	int i,b;
	for( i=0x8000; i; i>>=1 ) {
		if(i==0x8000) printf("r");
		if(i==0x0400) printf("_g");
		if(i==0x0010) printf("_b");
		if(i==0x0080) printf(":");
		b = rgb565 & i;
		mputc(0, b?'1':'0' );
	}
	mputc(0,' ');
}

int main()
{

	printf("\r\nTESTING OVM\r\n");

	//ovm_set_start();while(1);
	//choose bit

	/* cam_aux_out(0) <= v_load_pixel; */
	/* cam_aux_out(1) <= h_load_pixel; */
	/* cam_aux_out(2) <= ovm_pclk */
	/* cam_aux_out(3) <= ovm_pixel_valid; */
	/* cam_aux_out(4) <= v_load_row; */
	/* cam_aux_out(5) <= extra_href; */
	/* cam_aux_out(6) <= ff0; */
	/* cam_aux_out(7) <= v_rgb_out_valid; */


	int select=0;
	(((volatile int*)SCCB_PIO_BASE)[PIO_DATA_REGISTER]) &=0x1F;
	(((volatile int*)SCCB_PIO_BASE)[PIO_DATA_REGISTER]) |=(select << 5);


	if(ovm_configure()){
		printf("FAILED configuration\r\n");
		while(1);
	}

	volatile uchar* cam_address=SCRATCHPAD_BASE;
	int num_pixels=64*32;

	clear_frame((uchar*) cam_address, num_pixels*4 );

	//Add frame reading logic here

	printf("FIRST FRAME\r\n");
	printf("wait for done\r\n");
	ovm_clear_start();
	//wait for done bit
	while(!ovm_isdone()){
		debugx(((volatile int*)SCCB_PIO_BASE)[PIO_DATA_REGISTER]);
	}
	//set start bit
	printf("set start\r\n");
	ovm_set_start();
	printf("wait for not DONE\r\n");
	while(ovm_isdone()){
		//debugx(((volatile int*)SCCB_PIO_BASE)[PIO_DATA_REGISTER]);
	}
	ovm_clear_start();
	printf("wait for done\r\n");
	//wait for done bit
	while(!ovm_isdone());
	printf("DONE!\r\n");


	printf("SECOND FRAME\r\n");
	//get second frame
	int frame_counter=0;
	int 	start_time,end_time;
	while(1){

		clear_frame( (uchar*)cam_address, num_pixels*4 );

		start_time=get_time();
		ovm_set_start();
		while(ovm_isdone());
		ovm_clear_start();

		//wait for done bit
		while(ovm_isdone()==0);
		end_time=get_time();

#if 1
		print_reg( 0x04, "average Y " );
		print_reg( 0x05, "average B " );
		print_reg( 0x06, "average R " );
		print_reg( 0x07, "average G\r\n" );
#endif

		//remove alpha channel, swap Red/Blue for OpenCV display
		int r,c;
		for(r=0;r<30;r++){
			for(c=0;c<40;c++){
#if 0 /* RGB565 */
				const uint lsb = cam_address[(r*64+c)*4+0];
				const uint msb = cam_address[(r*64+c)*4+1];
				const uint rgb565 = (msb<<8) + lsb;
#define CLIM 10
#define RLIM 30
				//if( c<CLIM && r<RLIM ) { printf_bin(rgb565); }
				//if( c==39  && r<RLIM ) { printf("...\r\n"); }
				uchar red = (((rgb565 >> 11) & 0x1f) << 3); //cam_address[i*4+2];
				uchar grn = (((rgb565 >>  6) & 0x1f) << 3); //cam_address[i*4+1];
				uchar blu = (((rgb565 >>  0) & 0x1f) << 3); //cam_address[i*4+0];
				/* extend LSBs */
				red = red | ((red&0x8)?0x7:0x0) ;
				grn = grn | ((grn&0x4)?0x7:0x0) ;
				blu = blu | ((blu&0x8)?0x7:0x0) ;
				cam_address[(r*40+c)*3+2]/*CV_FRAME0: B*/ = (blu)/1; // 1011 1...
				cam_address[(r*40+c)*3+1]/*CV_FRAME1: G*/ = (grn)/1; // 1101 11..
				cam_address[(r*40+c)*3+0]/*CV_FRAME2: R*/ = (red)/1; // 1111 1...
#else /* RGB888 */
				uchar red = cam_address[(r*64+c)*4+2];
				uchar grn = cam_address[(r*64+c)*4+1];
				uchar blu = cam_address[(r*64+c)*4+0];
#define CLIM 10
#define RLIM 30
				//if( c<CLIM && r<RLIM ) { printf_rgb(red,grn,blu); }
				//if( c==39  && r<RLIM ) { printf("...\r\n"); }
#if 0
				/* extend LSBs */
				red = red | ((red&0x8)?0x7:0x0) ;
				grn = grn | ((grn&0x4)?0x7:0x0) ;
				blu = blu | ((blu&0x8)?0x7:0x0) ;
#endif
				cam_address[(r*40+c)*3+2]/*CV_FRAME0: B*/ = (blu)/1; // 1011 1...
				cam_address[(r*40+c)*3+1]/*CV_FRAME1: G*/ = (grn)/1; // 1101 11..
				cam_address[(r*40+c)*3+0]/*CV_FRAME2: R*/ = (red)/1; // 1111 1...
#endif /* RGB565 or RGB888 */

			}
		}

		//print_pic((char*)cam_address,40,30,64);

		printf("base64:");
		print_base64((char*)cam_address,3*40*30);
		printf("\r\n frame %d %d cycles\r\n",frame_counter++,end_time-start_time);

		//delayms(2000);
	}
	//always writing
	ovm_set_start();
	return 0;
}
