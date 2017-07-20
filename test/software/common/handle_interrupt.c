#include "handle_interrupt.h"

volatile int interrupt_count;

int handle_interrupt(int cause, int epc, int regs[32])
{
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction.
		for (;;);
	}

	interrupt_count++;
	schedule_interrupt(-1);//clear interrupt
	return epc;
}
