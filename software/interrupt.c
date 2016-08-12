#include "interrupt.h"
#include <stdint.h>

long handle_trap(long cause, long epc, long regs[32])
{
	for(;;);
  return epc;
}

void set_timer_interrupt_cycles(int cycles) {
  uint32_t timer_overflow_h;
  uint32_t timer_overflow_l;

  // Load from timer, add offset for overflow.
  asm volatile("csrr %0,mtimeh"
    : "=r" (timer_overflow_h)
    : );
  asm volatile("csrr %0,mtime"
    : "=r" (timer_overflow_l)
    : );
  
  // Set interrupt to occur after "cycles" amount of CPU cycles.
  timer_overflow_l += cycles;

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
}

void clear_timer_interrupt_cycles(void) {
  asm volatile("li t0,-1"
    :
    : );
  asm volatile("sw t0,0(%0)"
    :
    : "r" MTIMECMP_L);
  asm volatile("sw t0,0(%0)"
    :
    : "r" MTIMECMP_H);
}
