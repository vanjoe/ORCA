#include "printf.h"
#include "i2s.h"
#include "interrupt.h"
#include "lve_test.h"

#define SYS_CLK 6000000
static inline unsigned get_time()
{int tmp;       asm volatile("csrr %0,time":"=r"(tmp));return tmp;}

void delayus(int us)
{
	unsigned start=get_time();
	us*=(SYS_CLK/1000000);
	while(get_time()-start < us);
}

int main()
{
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
