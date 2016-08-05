#include "test_macros.h"
#include "interrupt.h"
#include <stdint.h>

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

  while(1);

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

      // Each external interrupt can be handled differently.
      /*
      switch(plic_claim) {
        case 0:
          break;
        case 1:
          break;
        case 2:
          break;
        case 3:
          break;
        case 4:
          break;
        case 5:
          break;
        case 6:
          break;
        case 7:
          break;
        case 8:
          break;
        case 9:
          break;
        case 10:
          break;
        case 11:
          break;
        case 12:
          break;
        case 13:
          break;
        case 14:
          break;
        case 15:
          break;
        case 16:
          break;
        case 17:
          break;
        case 18:
          break;
        case 19:
          break;
        case 20:
          break;
        case 21:
          break;
        case 22:
          break;
        case 23:
          break;
        case 24:
          break;
        case 25:
          break;
        case 26:
          break;
        case 27:
          break;
        case 28:
          break;
        case 29:
          break;
        case 30:
          break;
        case 31:
          break;
        default
          break;
      }
      */

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
