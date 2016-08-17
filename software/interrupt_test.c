#include <stdint.h>

#include "gpio.h"
#include "interrupt.h"
#include "test_macros.h"


volatile uint32_t timer_flag = 0;
volatile uint32_t software_flag = 0;
volatile uint32_t external_flag0 = 0;
volatile uint32_t external_flag1 = 0;
volatile uint32_t edge_count = 0;
volatile uint32_t interrupt_mask = 0x0;

#define SYS_CLK 125e5
#define HARDWARE_TEST 1
#define LEDR ((volatile int *) (0x01000010))
#define HEX0 ((volatile int *) (0x01000030))
#define HEX1 ((volatile int *) (0x01000040))
#define HEX2 ((volatile int *) (0x01000050))
#define HEX3 ((volatile int *) (0x01000060))

int main(void) {

  volatile uint32_t count;

  // Each set bit corresponds to an edge-sensitive interrupt.
  *EDGE_SENSITIVE_VECTOR = 0x2;

  set_timer_interrupt_cycles(15);
  enable_interrupts();
  enable_external_interrupts();
  enable_software_interrupts();
  enable_timer_interrupts();

  trigger_software_interrupt();

  for(count = 0; count < 25; count++);


  *LEDR = interrupt_mask;

  if (!(software_flag & timer_flag & external_flag0 & external_flag1)) {
    *HEX0 = 0xF;    
    *HEX1 = 0xF;    
    *HEX2 = 0xF;    
    *HEX3 = 0xF;    
    TEST_FAIL();
  }
  else {
    *HEX0 = 0x1;    
    *HEX1 = edge_count;    
    *HEX2 = 0x0;    
    *HEX3 = 0x0;    
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
      interrupt_mask |= 0x1;
      break;

    case M_TIMER_INTERRUPT:
      // Safe sequence of disabling timer interrupt without accidental interrupts.
      clear_timer_interrupt_cycles();
      timer_flag = 1;
      interrupt_mask |= 0x2;
      break;

    case M_EXTERNAL_INTERRUPT:
      // Read INTRPT_CLAIM to show the PLIC that the pending interrupt 
      // is being handled.
      claim_external_interrupt(&plic_claim);
      
      if (plic_claim == 0) {
        external_flag0 = 1;
        interrupt_mask |= 0x4;
      }
      else if (plic_claim == 1) {
        external_flag1 = 1;
        interrupt_mask |= 0x8;
        edge_count++;
      }
      
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
