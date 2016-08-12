#include "printf.h"
#include "i2s.h"

#define SYS_CLK 6000000
volatile int *ledrgb= (volatile int*)0x10000;

/********/
/* GPIO */
/********/
volatile int *gpio_data= (volatile int*)0x30000;
volatile int *gpio_ctrl= (volatile int*)0x30004;
//////////////////////
//
// UART stuff
//////////////////////
#define  UART_BASE ((volatile int*) 0x00020000)
volatile int*  UART_DATA=UART_BASE;
volatile int*  UART_LCR=UART_BASE+3;
volatile int*  UART_LSR=UART_BASE+5;

#define UART_LCR_8BIT_DEFAULT 0x03
#define UART_INIT() do{*UART_LCR = UART_LCR_8BIT_DEFAULT;}while(0)
#define UART_PUTC(c) do{*UART_DATA = (c);}while(0)
#define UART_BUSY() (!((*UART_LSR) &0x20))
#define debug(var) printf("%s:%d  %s = %d \r\n",__FILE__,__LINE__,#var,(signed)(var))
#define debugx(var) printf("%s:%d  %s = %08X \r\n",__FILE__,__LINE__,#var,(unsigned)(var))

////////////
//TIMER   //
////////////
static inline unsigned get_time()
{int tmp;       asm volatile(" csrr %0,time":"=r"(tmp));return tmp;}

void delayus(int us)
{
	unsigned start=get_time();
	us*=(SYS_CLK/1000000);
	while(get_time()-start < us);
}
#define delayms(ms) delayus(ms*1000)
void mputc ( void* p, char c)
{
  //delayms(200);
  //*UART_DATA= UART_BUSY()?'1':'0';
  while(UART_BUSY());
  *UART_DATA = c;
}



int main()
{
	int i='a';
	int colour=0x01;
	//initialize uart
	UART_INIT();
	init_printf(0,mputc);
	printf("hello\n");
	UART_INIT();

	int delay_length=500;
	printf("1");
	i=0;
	for(;;){
	  	printf("hello\r\n");
		printf("Hello World %d\r\n",i+=2);
		delayms(delay_length);
		debugx(i2s_base[I2S_BUFFER_OFFSET]);
	}
}


int handle_trap(long cause,long epc, long regs[32])
{
	//spin forever
	for(;;);
}
