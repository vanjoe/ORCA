#include <stdint.h>

volatile uint32_t timer_flag = 0;
volatile uint32_t software_flag = 0;

int main(void)
{

#define MTIMECMP_L  ((volatile int*) 0x00000000)
#define MTIMECMP_H  ((volatile int*) 0x00000004)
#define MSOFTWARE_I ((volatile int*) 0x00000008)

#define MSTATUS_IE_MASK 0x00000008
#define MIE_MEIE_MASK   0x00000800
#define MIE_MTIE_MASK   0x00000080
#define MIE_MSIE_MASK   0x00000008

#define SYS_CLK 125e5

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

  // Interrupts failed...
  if (!(software_flag & timer_flag)) {
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





