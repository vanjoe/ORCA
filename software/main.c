#define SYS_CLK 50000000
#include "macros.h"
#include "vbx_cproto.h"
#include "printf.h"

vbx_uhalf_t* scratchpad_base = (vbx_uhalf_t*)0x80000000;

volatile int *  gpio_data= (volatile int*)0x10000;
volatile int *  hex0= (volatile int*)0x01000030;
volatile int *  hex1= (volatile int*)0x01000040;
volatile int *  hex2= (volatile int*)0x01000050;
volatile int *  hex3= (volatile int*)0x01000060;
volatile int *  uart= (volatile int*)0x01000070;
volatile int *  mic_ready= (volatile int*)0x01000100;
volatile int *  mic_data = (volatile int*)0x01000108;


#define UART_INIT() ((void)0)
#define UART_PUTC(c) do{*((char*)uart) = (c);}while(0)
#define UART_BUSY() ((uart[1]&0xFFFF0000) ==0 )


void mputc ( void* p, char c)
{
	while(UART_BUSY());
	UART_PUTC(c);
}
#define debug(var)  //printf("%s:%d  %s = %d \r\n",__FILE__,__LINE__,#var,(signed)(var))
#define debugx(var) //printf("%s:%d  %s = %08X \r\n",__FILE__,__LINE__,#var,(unsigned)(var))

////////////
//TIMER   //
////////////
static inline unsigned get_time() {
  int tmp;       
  asm volatile(" csrr %0,time":"=r"(tmp));return tmp;
}

void delayus(int us)
{
	unsigned start=get_time();
	us*=(SYS_CLK/1000000);
	while(get_time()-start < us);
}

#define delayms(ms) delayus(ms*1000)


//volatile int *gpio_data= (volatil1e int*)0x10000;
void test_mxp() {
	vbx_uhalf_t* a=scratchpad_base+0;
	vbx_uhalf_t* b=scratchpad_base+6;
	vbx_uhalf_t* c=scratchpad_base+12;
	*hex0=__LINE__;
	b[0]=3;
	b[1]=3;
	b[2]=3;
	b[3]=3;
	b[4]=3;
	b[5]=3;

	c[0]=4;
	c[1]=4;
	c[2]=4;
	c[3]=4;
	c[4]=4;
	c[5]=4;

	*hex1=*c;
	*hex2=*b;
	*hex0=__LINE__;
	vbx_set_vl(6);
	vbx(SEHU,VADD,a,0,vbx_ENUM);
	*hex0=__LINE__;
	vbx_set_vl(4);
	vbx(VVHU,VADD,a,b,c);
	*hex1=a[0];
	*hex2=a[1];
	*hex3=a[2];
}


int main() {
	test_mxp();
}


int tohost_exit() {
	for(;;);
}

int handle_interrupt(long cause, long epc, long regs[32]) {
  for(;;);
}
