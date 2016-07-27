#include <stdint.h>

volatile uint32_t timer_flag = 0;
volatile uint32_t software_flag = 0;
volatile uint32_t external_flag = 0; 

#define MTIMECMP_L       ((volatile int*) 0x00000000)
#define MTIMECMP_H       ((volatile int*) 0x00000004)
#define MSOFTWARE_I      ((volatile int*) 0x00000008)
#define EDGE_SENS_VECTOR ((volatile int*) 0x0000000C)
#define INTRPT_CLAIM     ((volatile int*) 0x00000010)
#define INTRPT_COMPLETE  ((volatile int*) 0x00000014)

#define MSTATUS_IE_MASK 0x00000008
#define MIE_MEIE_MASK   0x00000800
#define MIE_MTIE_MASK   0x00000080
#define MIE_MSIE_MASK   0x00000008

#define SYS_CLK 125e5

int main(void) {

  uint32_t timer_overflow_h;
  uint32_t timer_overflow_l;
  volatile uint32_t count;

  // Load from timer, add offset for overflow.
  asm volatile("csrr %0,mtimeh"
    : "=r" (timer_overflow_h)
    : );
  asm volatile("csrr %0,mtime"
    : "=r" (timer_overflow_l)
    : );
  
  // Set interrupt to occur after 15 cycles.
  timer_overflow_l += 15;

  // Safe sequence of initializing timer interrupt without accidental interrupts.
  asm volatile("li t0,-1"
    :
    : );
  asm volatile("sw t0,0(%0)"
    :
    : "r" MTIMECMP_L);
  asm volatile("sw %0,0(%1)"
    :
    : "r" (timer_overflow_h), "r" (MTIMECMP_H)); 
  asm volatile("sw %0,0(%1)"
    :
    : "r" (timer_overflow_l), "r" (MTIMECMP_L));

  // Global enable for machine level interrupts.
  asm volatile("csrs mstatus,%0"
    :
    : "r" ((int) MSTATUS_IE_MASK)); 
  // Enable external, timer, and software machine level interrupts.
  asm volatile("csrs mie,%0"
    :
    : "r" ((int) (MIE_MEIE_MASK | MIE_MTIE_MASK | MIE_MSIE_MASK)));

  // Trigger software interrupt.
  asm volatile("sw %0,0(%1)"
    :
    : "r" ((int) 0x1), "r" (MSOFTWARE_I));

  for(count = 0; count < 25; count++);

#define EXT_INT_TO_TEST 14
  // Interrupts failed...
  if (!(software_flag & timer_flag) || (external_flag != EXT_INT_TO_TEST)) {
    asm volatile("csrw 0x780,%0"
      :
      : "r" ((int) (-1)));
  }

  return 1;
}

int handle_trap(long cause, long epc, long regs[32])
{
	//spin forever
	for(;;);
}

#define M_SOFTWARE_INTERRUPT 0x3
#define M_TIMER_INTERRUPT    0x7
#define M_EXTERNAL_INTERRUPT 0xB
long handle_interrupt(long cause, long epc, long regs[32])
{
  switch(cause & 0xF) {
    int plic_claim;

    case M_SOFTWARE_INTERRUPT:
      software_flag = 1;
      // Clear pending software interrupt.
      asm volatile("lw t0,0(%0)"
      :
      : "r" (MSOFTWARE_I)); 
      break;

    case M_TIMER_INTERRUPT:
      timer_flag = 1;
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

      external_flag = plic_claim; 

      // Write to INTRPT_COMPLETE to signify that the PLIC can 
      // receive another external interrupt from the source it
      // just processed.
      *INTRPT_COMPLETE = plic_claim;
      break;

    default:
      break;
  }

  // Re-enable interrupts after service.
  asm volatile("csrs mstatus,%0"
    :
    :"r" ((int) MSTATUS_IE_MASK)); 

  return epc;
}





