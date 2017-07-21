#include "uart.h"
#include "main.h"
#include "cache_test.h"


int main(void) {

	int i = 1000;
	while(i) {
		asm volatile("addi %0, %0, -1":"=r"(i):"r"(i));
	};









  return i;
}

int handle_interrupt(int cause, int epc, int regs[32])
{
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction.
		for (;;);
	}

	// Handle interrupt	
	//ChangedPrint("Hello World\r\n");
	return epc;
}
