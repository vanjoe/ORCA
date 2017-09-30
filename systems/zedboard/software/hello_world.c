#include "uart.h"
#include "main.h"

int main(void) {

  ChangedPrint("Hello World\r\n");

	while(1){
	}
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
	ChangedPrint("Interrupt handled\r\n");
	return epc;
}
