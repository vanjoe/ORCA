#include "test_macros.h"
#include "interrupt.h"

int main(void)
{
  volatile int source1;
  volatile int result1;
  volatile int source2;
  volatile int result2;
  volatile int* data;
  source1 = 2; 
  source2 = 4;

  // Test consecutive shifts
  asm volatile("slli %0,%1,4"
    : "=r" (result1)
    : "r" (source1));
  asm volatile("slli %0,%1,2"
    : "=r" (result2)
    : "r" (source2));

  if (result1 != 32 || result2 != 16) {
    TEST_FAIL();
  }

  // Test consecutive delayed stores/loads
#define DATA_MEM  ((volatile int*) 0x01000200)
#define COUNT_REG ((volatile int*) 0x01000300)
  data = DATA_MEM;
  source1 = result1;
  source2 = result2;

  // Specifies the number of pipeline stages in the long read
  *COUNT_REG = 0x00000004;

  // Test consecutive reads
  asm volatile("sw %0,4(%1)"
    :  
    : "r" (source1), "r" (data));
  asm volatile("sw %0,8(%1)"
    :
    : "r" (source2), "r" (data));
  // Test consecutive writes
  asm volatile("lw %0,4(%1)"
    : "=r" (result1)
    : "r" (data));
  asm volatile("lw %0,8(%1)"
    : "=r" (result2)
    : "r" (data));
  if (result1 != 32 || result2 != 16) {
    TEST_FAIL();
  }

  // Test read after write
  source1 = 0xDEADBEEF;
  asm volatile("sw %0,4(%1)"
    :  
    : "r" (source1), "r" (data));
  asm volatile("lw %0,4(%1)"
    : "=r" (result1)
    : "r" (data));
  if (result1 != 0xDEADBEEF) {
    TEST_FAIL();
  }

  TEST_PASS();
  return 1;
}

long handle_interrupt(long cause, long epc, long regs[32])
{
  switch(cause & 0xF) {
    int plic_claim;

    case M_SOFTWARE_INTERRUPT:
      // Clear pending software interrupt.
      asm volatile("lw t0,0(%0)"
      :
      : "r" (MSOFTWARE_I)); 
      break;

    case M_TIMER_INTERRUPT:
      // Safe sequence of disabling timer interrupt without accidental interrupts.
      asm volatile("li t0,-1"
        :
        : );
      asm volatile("sw t0,0(%0)"
        :
        : "r" MTIMECMP_L);
      asm volatile("sw t0,0(%0)"
        :
        : "r" MTIMECMP_H);
      break;

    case M_EXTERNAL_INTERRUPT:
      // Read INTRPT_CLAIM to show the PLIC that the pending interrupt 
      // is being handled.
      plic_claim = *INTRPT_CLAIM;

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
      *INTRPT_COMPLETE = plic_claim;
      break;

    default:
      break;
  }

  return epc;
}
