

#include "sccb.h"
#include "ovm7692.h"
#include "time.h"
#include "vbx.h"

#define OVM_VERBOSE 0
#if OVM_VERBOSE
#include "printf.h"
#define ovm_printf printf
#else
#define ovm_printf(...)
#endif

static void ovm_write_reg(int reg_addr,int reg_val)
{
	sccb_write(SCCB_PIO_BASE, OVM7692_ADDRESS, reg_addr, reg_val);
}

static int ovm_read_reg(int reg_addr)
{
	return sccb_read(SCCB_PIO_BASE, OVM7692_ADDRESS, reg_addr);
}



#define PIO_BIT_START 2
#define PIO_BIT_DONE  3

static void ovm_set_bit( int bitpos )
{
	volatile unsigned *p = &( SCCB_PIO_BASE[PIO_DATA_REGISTER] );
	*p |= (1<<bitpos);
}

static void ovm_clear_bit( int bitpos )
{
	volatile unsigned *p = &( SCCB_PIO_BASE[PIO_DATA_REGISTER] );
	*p &= (~(1<<bitpos));
}

static int ovm_get_bit( int bitpos )
{
	volatile unsigned *p = &( SCCB_PIO_BASE[PIO_DATA_REGISTER] );
	return (*p & (1<<bitpos)) ? 1 : 0 ;
}


static int ovm_isdone()
{
	return !ovm_get_bit( PIO_BIT_DONE );
}



static int ovm_configure()
{
	ovm_printf("STARTING OVM configuration\r\n");
	delayms(500);
	ovm_printf("Done Delay\r\n");
	sccb_init(SCCB_PIO_BASE);

	uint8_t pidh = ovm_read_reg(OVM7692_SUBADDRESS_PIDH);
	uint8_t pidl = ovm_read_reg(OVM7692_SUBADDRESS_PIDL);

	if((pidh != OVM7692_DEFAULT_PIDH) || (pidl != OVM7692_DEFAULT_PIDL)){
		ovm_printf("Error: BAD ,model ID\r\n");
		return 1;
	}
	ovm_write_reg(0x12, 0x06);
	if(ovm_read_reg(0x12) != 0x6){
		ovm_printf("Error: WRITE FAILED \r\n");
		return 1;
	}
	int i;
	ovm_printf("Writing Configuration Registers...");
	for(i=0;i<(sizeof(regval_list)/sizeof(regval_list[0]));i++){
		ovm_write_reg(regval_list[i].addr,regval_list[i].val);
		delayms(2);
	}

	ovm_printf("Done\r\n");
	return 0;
}

static int initialized=0;


#define INCOMING_COLS 64
#define INCOMING_ROWS 32

#define OUT_COLS 32
#define OUT_ROWS 32
#define OUT_PAD_COLS_LEFT 4
#define OUT_PAD_COLS_RIGHT 4
#define OUT_PAD_ROWS_TOP 1
#define OUT_PAD_ROWS_BOT 1

#define OVM_DMA_BUFFER SCRATCHPAD_BASE


int ovm_initialize()
{
	int i;
	for(i=0;i<INCOMING_COLS*INCOMING_ROWS;i++){
		((volatile int*)OVM_DMA_BUFFER)[i]=0;
	}

	if(ovm_configure()){
		return 1;
	}


	initialized=1;
	return 0;
}
int ovm_get_frame()
{
	if (initialized ==0){
		return 1;
	}
	ovm_printf("is initialized\r\n");
	// tell camera to capture a frame
	ovm_set_bit( PIO_BIT_START );
	ovm_printf("start bit set\r\n");
	// wait until FSM actually starts
	while( ovm_isdone() ){
		ovm_printf("not done\r\n");
	}
	ovm_printf("done bit clear\r\n");
	// clear the start bit
	ovm_clear_bit( PIO_BIT_START );
	ovm_printf("start bit clear\r\n");
	// wait until DMA is DONE
	while( ovm_isdone()==0 );
	ovm_printf("done bit set\r\n");


	return 0;
}

int ovm_get_frame_async()
{
	if (initialized ==0){
		return 1;
	}
	ovm_printf("is initialized\r\n");
	// tell camera to capture a frame
	ovm_set_bit( PIO_BIT_START );
	ovm_printf("start bit set\r\n");
	// wait until FSM actually starts
	while( ovm_isdone() ){
		ovm_printf("not done\r\n");
	}
	ovm_printf("done bit clear\r\n");
	// clear the start bit
	ovm_clear_bit( PIO_BIT_START );
	ovm_printf("start bit clear\r\n");

	return 0;
}

int ovm_wait_frame()
{
	// wait until DMA is DONE
	while( ovm_isdone()==0 );
	ovm_printf("done bit set\r\n");


	return 0;
}
