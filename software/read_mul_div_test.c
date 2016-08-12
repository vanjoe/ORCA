#include "gpio.h"
#include "interrupt.h"
#include "test_macros.h"

#define DATA_MEM  ((volatile int*) 0x01000200)
#define COUNT_REG ((volatile int*) 0x01000300)

int main(void)
{
  // Specifies the number of pipeline stages in the RAM.
  *COUNT_REG = 0x00000007;
  volatile register int data1 asm ("a0");
  volatile register int data2 asm ("a1");
  volatile register int result asm ("a2");
  volatile register int temp asm ("a3");

  // Write valued, then read them from pipelined RAM.
  // Immediately after, begin a divide.
  data1 = 20;
  data2 = 0;
  asm volatile("sw %0,0(%1)"
    :
    :  "r" (15), "r" (DATA_MEM));
  asm volatile("lw %0,0(%1)"
    : "=r" (temp)
    : "r" (DATA_MEM));
  asm volatile("div %0,%1,%2"
    : "=r" (result)
    : "r" (data1), "r" (data2));
  if (result != 0xFFFFFFFF) {
    *HEX0 = 0xF;    
    *HEX1 = 0xF;    
    *HEX2 = 0xF;    
    *HEX3 = 0xF;    
    TEST_FAIL();
  }

  data1 = 20;
  data2 = 5;
  // Test a multiply after read.
  asm volatile("lw %0,0(%1)"
    : "=r" (temp)
    : "r" (DATA_MEM)); 
  asm volatile("mul %0,%1,%2"
    : "=r" (result)
    : "r" (data1), "r" (data2));
  if (result != 100) {
    *HEX0 = 0xF;    
    *HEX1 = 0xF;    
    *HEX2 = 0xF;    
    *HEX3 = 0xF;    
    TEST_FAIL();
  }

  // Test a shift after read.
  data1 = 24;
  data2 = 2;
  asm volatile("sw %0,0(%1)"
    :
    : "r" (16), "r" (DATA_MEM));
  asm volatile("lw %0,0(%1)"
    : "=r" (temp)
    : "r" (DATA_MEM)); 
  asm volatile("srl %0,%1,%2"
    : "=r" (result)
    : "r" (data1), "r" (data2));

  if (result != 6) {
    *HEX0 = 0xF;    
    *HEX1 = 0xF;    
    *HEX2 = 0xF;    
    *HEX3 = 0xF;    
    TEST_FAIL();
  }

  *HEX0 = 0x1;    
  *HEX1 = 0x0;    
  *HEX2 = 0x0;    
  *HEX3 = 0x0;    
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

