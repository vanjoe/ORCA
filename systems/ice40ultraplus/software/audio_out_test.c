#include "printf.h"
#include "i2s.h"

#include "interrupt.h"

//////////////////////
//
// UART stuff
//////////////////////
#define  UART_BASE ((volatile int*) 0x04000000)
volatile int*  UART_DATA=UART_BASE;
volatile int*  UART_LCR=UART_BASE+3;
volatile int*  UART_LSR=UART_BASE+5;

#define UART_LCR_8BIT_DEFAULT 0x03
#define UART_INIT() do{*UART_LCR = UART_LCR_8BIT_DEFAULT;}while(0)
#define UART_PUTC(c) do{*UART_DATA = (c);}while(0)
#define UART_BUSY() (!((*UART_LSR) &0x20))
void mputc ( void* p, char c)
{
        while(UART_BUSY());
        *UART_DATA = c;
}



#define SYS_CLK 8000000
static inline unsigned get_time()
{int tmp;       asm volatile("csrr %0,time":"=r"(tmp));return tmp;}
static inline void to_host(unsigned tmp)
{   asm volatile("csrw mepc,%0"::"r"(tmp));}


void delayus(int us)
{
	unsigned start=get_time();
	us*=(SYS_CLK/1000000);
	while(get_time()-start < us);
}

#define SCRATCHPAD_BASE 0x80000000
int main(void) {

	int buffer_loc = 0;
	short mic0, mic1;
	i2s_set_frequency(SYS_CLK,8000);

	mic0 = 5;
	mic1 = 6;


	for (;;buffer_loc += 2) {

			if (buffer_loc >= 5) {
				buffer_loc = 0;
				break;
			}


			i2s_put_data(mic0,mic1);
			mic0++;mic1=0;
	}
	while(1);
	return 0;
}

int handle_interrupt(long cause, long epc, long regs[32]) {
  switch(cause & 0xF) {

    case M_SOFTWARE_INTERRUPT:
      clear_software_interrupt();

    case M_TIMER_INTERRUPT:
      clear_timer_interrupt_cycles();

    case M_EXTERNAL_INTERRUPT:
      {
        int plic_claim;
        claim_external_interrupt(&plic_claim);
        complete_external_interrupt(plic_claim);
      }
      break;

    default:
      break;
  }

  return epc;
}
