#include <stdint.h>
#include "test_macros.h"
#include "interrupt.h"

volatile uint32_t timer_flag = 0;
volatile uint32_t software_flag = 0;
volatile uint32_t external_flag = 0; 

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

#define EXT_INT_TO_TEST 14
  // Interrupts failed...
  if (!(software_flag & timer_flag) || (external_flag != EXT_INT_TO_TEST)) {
#if HARDWARE_TEST
    *LEDR = 0xFFFFFFFF;
#endif 
    TEST_FAIL();
  }

#if HARDWARE_TEST
    *LEDR = interrupt_mask;
#endif 
  TEST_PASS();
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

      external_flag = plic_claim;
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
