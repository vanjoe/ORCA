#include "printf.h"
#include "i2s.h"
#include "interrupt.h"


#define SYS_CLK 8000000
static inline unsigned get_time()
{int tmp;       asm volatile("csrr %0,time":"=r"(tmp));return tmp;}

void delayus(unsigned int us)
{
	unsigned start=get_time();
	us*=(SYS_CLK/1000000);
	while(get_time()-start < us);
}
void delayms( unsigned int ms)
{
	unsigned long long us = ((unsigned long long)ms)*1000;

	unsigned long long max_us=0x7FFFFFFF;
	while(1){
		if(us > max_us){
			delayus((unsigned int)max_us);
			us-=max_us;
		}else{
			delayus((unsigned int)us);
			break;
		}
	}
}

int main()
{
	int i;
	while(1){
		printf("Hello world %X\r\n",i++);
		delayms(500);
	}
	return 0;
}

int handle_interrupt(long cause, long epc, long regs[32]) {
	/*  switch(cause & 0xF) {

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
	*/
	return epc;

}
