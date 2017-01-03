

#include "printf.h"
#include "sccb.h"
#include "ovm7692.h"
#include "time.h"
#include "vbx.h"
#include "base64.h"
#define SCCB_PIO_BASE   ((void *)0x00050000)

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

static const regval_t regval_list[] ={


	// STARTUP
	{ 0x12, 0x00}, // end RESET
	{ 0x12, 0x80}, //  start RESET
#if 0
	////////////////////////////////////////////////////////////
	{0x12, 0x80},															 //
	{0x0e, 0x08},															 //
	{0x69, 0x52},															 //
	{0x1e, 0xb3},															 //
	{0x48, 0x42},															 //
	{0xff, 0x01},															 //
	{0xb5, 0x30},															 //
	{0xff, 0x00},															 //
	{0x16, 0x03},															 //
	{0x62, 0x10}, /* YUV */												 //
	{0x12, 0x00},															 //
	{0x17, 0x65},															 //
	{0x18, 0xa4},															 //
	{0x19, 0x0a},															 //
	{0x1a, 0xf6},															 //
	/*{0x3e, 0x20}, part of ovm7692_device_init_regs */		 //
	{0x64, 0x11},															 //
	{0x67, 0x20},															 //
	{0x81, 0x3f},															 //
	{0xcc, 0x02},															 //
	{0xcd, 0x80},															 //
	{0xce, 0x01},															 //
	{0xcf, 0xe0},															 //
	{0xc8, 0x02},															 //
	{0xc9, 0x80},															 //
	{0xca, 0x01},															 //
	{0xcb, 0xe0},															 //
	{0xd0, 0x48},															 //
	{0x82, 0x03},															 //
	{0x70, 0x00},															 //
	{0x71, 0x34},															 //
	{0x74, 0x28},															 //
	{0x75, 0x98},															 //
	{0x76, 0x00},															 //
	{0x77, 0x64},															 //
	{0x78, 0x01},															 //
	{0x79, 0xc2},															 //
	{0x7a, 0x4e},															 //
	{0x7b, 0x1f},															 //
	{0x7c, 0x00},															 //
	/*{0x11, 0x01}, ovm7692_device_init_regs */					 //
	{0x20, 0x00},															 //
	{0x21, 0x57},															 //
	{0x50, 0x4d},															 //
	{0x51, 0x40},															 //
	{0x4c, 0x7d},															 //
	{0x0e, 0x00},															 //
	{0x80, 0x7f},															 //
	{0x85, 0x00}, /*OVT default 0x10*/								 //
	{0x86, 0x00},															 //
	{0x87, 0x00},															 //
	{0x88, 0x00},															 //
	{0x89, 0x2a}, /*OVT default 0x2f*/								 //
	{0x8a, 0x22}, /*OVT default 0x20*/								 //
	{0x8b, 0x20}, /*OVT default 0x23*/								 //
	{0xbb, 0xab}, /*OVT default 0x7a*/								 //
	{0xbc, 0x84}, /*OVT default 0x69*/								 //
	{0xbd, 0x27}, /*OVT default 0x11*/								 //
	{0xbe, 0x0e}, /*OVT default 0x13*/								 //
	{0xbf, 0xb8}, /*OVT default 0x81*/								 //
	{0xc0, 0xc5}, /*OVT default 0x96*/								 //
	{0xc1, 0x1e},															 //
	{0xb7, 0x05},															 //
	{0xb8, 0x09},															 //
	{0xb9, 0x00},															 //
	{0xba, 0x18},															 //
	{0x5a, 0x1f}, /*OVT default 0x29*/								 //
	{0x5b, 0x9f},															 //
	{0x5c, 0x69}, /*OVT default 0x68*/								 //
	{0x5d, 0x62}, /*exp set to center 1/4 average*/				 //
	{0x24, 0x78},															 //
	{0x25, 0x68},															 //
	{0x26, 0xb3},															 //
	{0xa3, 0x0b},															 //
	{0xa4, 0x15},															 //
	{0xa5, 0x29}, /*OVT default 0x2a*/								 //
	{0xa6, 0x4a}, /*OVT default 0x51*/								 //
	{0xa7, 0x58}, /*OVT default 0x63*/								 //
	{0xa8, 0x65}, /*OVT default 0x74*/								 //
	{0xa9, 0x70}, /*OVT default 0x83*/								 //
	{0xaa, 0x7b}, /*OVT default 0x91*/								 //
	{0xab, 0x85}, /*OVT default 0x9e*/								 //
	{0xac, 0x8e}, /*OVT default 0xaa*/								 //
	{0xad, 0xa0}, /*OVT default 0xbe*/								 //
	{0xae, 0xb0}, /*OVT default 0xce*/								 //
	{0xaf, 0xcb}, /*OVT default 0xe5*/								 //
	{0xb0, 0xe1}, /*OVT default 0xf3*/								 //
	{0xb1, 0xf1}, /*OVT default 0xfb*/								 //
	{0xb2, 0x14}, /*OVT default 0x06*/								 //
	{0x8c, 0x56}, /*OVT default 0x5c*/								 //
	{0x8d, 0x11},															 //
	{0x8e, 0x12},															 //
	{0x8f, 0x19},															 //
	{0x90, 0x50},															 //
	{0x91, 0x22}, /*OVT default 0x20*/								 //
	{0x92, 0x99}, /*OVT default 0x96*/								 //
	{0x93, 0x8f}, /*OVT default 0x80*/								 //
	{0x94, 0x11}, /*OVT default 0x13*/								 //
	{0x95, 0x1f}, /*OVT default 0x1b*/								 //
	{0x96, 0xff},															 //
	{0x97, 0x00},															 //
	{0x98, 0x33}, /*OVT default 0x3d*/								 //
	{0x99, 0x2a}, /*OVT default 0x36*/								 //
	{0x9a, 0x54}, /*OVT default 0x51*/								 //
	{0x9b, 0x50}, /*OVT default 0x43*/								 //
	{0x9c, 0xf0},															 //
	{0x9d, 0xf0},															 //
	{0x9e, 0xf0},															 //
	{0x9f, 0xff},															 //
	{0xa0, 0x61}, /*OVT default 0x68*/								 //
	{0xa1, 0x5c}, /*OVT default 0x62*/								 //
	{0xa2, 0x0c}, /*OVT default 0x0e*/								 //
																				 //
	////////////////////////////////////////////////////////////

#endif

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
	// { 0x0C, 0x16}, // original Blue and Red in RGB565
	// { 0x5e 0x10}, // divided PCLK
	// { 0x37 0x14}, // output PCLK/2
	{ 0x61, 0x00}, // or 0x70, to generate one of two test patterns
	// { 0x64, 0x11}, // set PCLK to SCLK
	// { 0x64, 0x21}, // set PCLK to SCLK/2
	//{ 0x37, 0x1c},
	{0x30, 0x06},
	{ 0x12, 0x00}, // end RESET
	{ 0x12, 0x06}, // set RGB565

	{ 0x0e, 0x00}, // exit sleep mode

	// FRAMERATE (30fps)
	// set it again?
};


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




int main(){

	printf("\r\nTESTING OVM\r\n");

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

#if 1
	if(ovm_configure()){
		printf("FAILED configuration\r\n");
		while(1);
	}
#endif
	volatile char* cam_address=SCRATCHPAD_BASE;
	int num_pixels=64*32;
	int i;

	for(i=0;i<num_pixels*4;i++){
		cam_address[i]=0;
	}

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
	while(1){
		for(i=0;i<num_pixels*4;i++){
			cam_address[i]=0;
		}


		ovm_set_start();
		while(ovm_isdone());
		ovm_clear_start();

		//wait for done bit
		while(!ovm_isdone());


		//remove alpha channel
		for(i=0;i<num_pixels;i++){
			cam_address[i*3+2]=cam_address[i*4+0];
			cam_address[i*3+1]=cam_address[i*4+1];
			cam_address[i*3+0]=cam_address[i*4+2];
		}
		//swap red/blow

		for(i=0;i<32;i++){
			int j;
			for(j=0;j<40;j++){
				printf("%02X%02X%02x ",
				       cam_address[i*64*3+0+j*3],
				       cam_address[i*64*3+1+j*3],
				       cam_address[i*64*3+2+j*3]);
			}
			printf("\r\n");
		}

		print_base64((char*)cam_address,3*64*32);
		printf("\n\n\n\r");
		delayms(2000);
	}
	//always writing
	ovm_set_start();
	return 0;
}
