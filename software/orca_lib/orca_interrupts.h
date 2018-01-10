#ifndef ORCA_INTERRUPTS_H
#define ORCA_INTERRUPTS_H

#include <stdint.h>

//Disable interrupts and return the old MSTATUS value for a future
//restore_interrupts() call.
uint32_t disable_interrupts();

//Enable interrupts and return the old MSTATUS value for a future
//restore_interrupts() call.
uint32_t enable_interrupts();

//Restore interrupts based on a previous MSTATUS value.
void restore_interrupts(uint32_t previous_mstatus);

#endif //#ifndef ORCA_INTERRUPTS_H
