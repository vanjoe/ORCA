#include "handle_interrupt.h"
#include "test_passfail.h"

volatile int interrupt_count;

int handle_interrupt(int cause, int epc, int regs[32])
{
	if (!((cause >> 31) & 0x1)) {
		asm volatile("la sp, _end_of_memory");
		asm volatile("addi sp, sp, -4");
		test_fail();
	}

	interrupt_count++;
	schedule_interrupt(-1);//clear interrupt
	return epc;
}

void schedule_interrupt(int cycles)
{
	// When an integer is written to the INT_GEN_REGISTER,
	// an interrupt will be triggered that many cycles from now.
	// if the number is negative, no interrupt will occur.

	// Note that an interrupt must clear flush the pipeline, before the
	// processor can be interrupted, so if the next instruction disables
	// interrupts, the interrupt will probably not be taken.

	volatile int*  INT_GEN_REGISTER = (volatile int*)(0x01000000);
	*INT_GEN_REGISTER = cycles;
}
