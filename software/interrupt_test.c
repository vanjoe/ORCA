#include <stdint.h>
#include "test_macros.h"
#include "interrupt.h"

volatile uint32_t timer_flag = 0;
volatile uint32_t software_flag = 0;

#define SYS_CLK 125e5
#define HARDWARE_TEST 1
#define LEDR ((volatile int *) (0x01000010))

#if HARDWARE_TEST
volatile uint32_t interrupt_mask = 0x00000000;
#endif

int main(void) {

  volatile uint32_t count;

  set_timer_interrupt_cycles(15);
  enable_interrupts();
  enable_external_interrupts();
  enable_software_interrupts();
  enable_timer_interrupts();

  trigger_software_interrupt();

  for(count = 0; count < 25; count++);


#if HARDWARE_TEST
  *LEDR = interrupt_mask;
#endif 

  if (!(software_flag & timer_flag)) {
    asm volatile("csrw 0x780,%0"
      :
      : "r" ((int) (-1)));
    TEST_FAIL();
  }
  else {
    asm volatile("csrw 0x780,%0"
      :
      : "r" ((int) (1)));
    TEST_PASS();
  }

  return 1;
}

long handle_interrupt(long cause, long epc, long regs[32])
{
  switch(cause & 0xF) {
    int plic_claim;

    case M_SOFTWARE_INTERRUPT:
      // Clear pending software interrupt.
      clear_software_interrupt();
      software_flag = 1;
#if HARDWARE_TEST
      interrupt_mask |= 0x1;
#endif
      break;

    case M_TIMER_INTERRUPT:
      // Safe sequence of disabling timer interrupt without accidental interrupts.
      clear_timer_interrupt_cycles();
      timer_flag = 1;
#if HARDWARE_TEST
      interrupt_mask |= 0x2;
#endif
      break;

    case M_EXTERNAL_INTERRUPT:
      // Read INTRPT_CLAIM to show the PLIC that the pending interrupt 
      // is being handled.
      claim_external_interrupt(&plic_claim);

#if HARDWARE_TEST
      interrupt_mask |= 0x4;
#endif
      
      // Write to INTRPT_COMPLETE to signify that the PLIC can 
      // receive another external interrupt from the source it
      // just processed.
      complete_external_interrupt(plic_claim);
      break;

    default:
      break;
  }
  return epc;
}
