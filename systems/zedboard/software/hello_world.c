#include "uart.h"
#include "main.h"

int main(void) {

	while(1) {
		ChangedPrint("Hello World\r\n");
		delayms(1000);
	}

	int i = 1000;
	while(i) {
		asm volatile("addi %0, %0, -1":"=r"(i):"r"(i));
	};
  return i;
}

int handle_interrupt(int cause, int epc, int regs[32])
{
	return epc;
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction.
		ChangedPrint("Illegal Instruction\r\n");
		for (;;);
	}

	// Handle interrupt	
	ChangedPrint("Hello World\r\n");
	return epc;
}
