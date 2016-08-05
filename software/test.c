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
    asm volatile("csrw 0x780,%0"
      :
      :"r" ((int) -1));

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
    asm volatile("csrw 0x780,%0"
      :
      :"r" ((int) -1));
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
    asm volatile("csrw 0x780,%0"
      :
      :"r" ((int) -1));
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
      clear_software_interrupt();
      break;

    case M_TIMER_INTERRUPT:
      clear_timer_interrupt_cycles();
      break;

    case M_EXTERNAL_INTERRUPT:
      claim_external_interrupt(&plic_claim);
      complete_external_interrupt(plic_claim);
      break;

    default:
      break;
  }
  return epc;
}

