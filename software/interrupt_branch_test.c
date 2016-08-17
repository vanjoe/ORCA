#include <stdint.h>

#include "gpio.h"
#include "interrupt.h"
#include "test_macros.h"

int main(void) {

  enable_interrupts();
  enable_external_interrupts();
  enable_software_interrupts();
  enable_timer_interrupts();

  // Should never leave this loop unless interrupt
  // handles the branch wrong.
  asm volatile("li t3, 1"
    :
    : );
    *HEX0 = 0x1;    
    *HEX1 = 0x0;    
    *HEX2 = 0x0;    
    *HEX3 = 0x0;    

  while(1);

  *HEX0 = 0xF;    
  *HEX1 = 0xF;    
  *HEX2 = 0xF;    
  *HEX3 = 0xF;    
  TEST_FAIL();

  return 1;
}

long handle_interrupt(long cause, long epc, long regs[32])
{
  switch(cause & 0xF) {
    int plic_claim;

    case M_SOFTWARE_INTERRUPT:
      // Clear pending software interrupt.
      clear_software_interrupt();

    case M_TIMER_INTERRUPT:
      // Safe sequence of disabling timer interrupt without accidental interrupts.
      clear_timer_interrupt_cycles();

    case M_EXTERNAL_INTERRUPT:
      // Read INTRPT_CLAIM to show the PLIC that the pending interrupt 
      // is being handled.
      claim_external_interrupt(&plic_claim);

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
