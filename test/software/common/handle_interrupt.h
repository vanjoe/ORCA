#ifndef HANDLE_INTERRUPT_H
#define HANDLE_INTERRUPT_H

int handle_interrupt(int cause, int epc, int regs[32]);
void schedule_interrupt(int cycles);

#endif
