#include "bsp.h"
#include "uart.h"
#include "printf.h"

int main() {
  init_printf(0, mputc);

  printf("Hello World\r\n");

  while(1){
  }
  return 0;
}

int tohost_exit() {
	for(;;);
}

int handle_interrupt(int cause, int epc, int regs[32])
{
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction
    // Nothing implemented yet; just print a debug message and hang.
		printf("Unhandled illegal instruction...\r\n");
		for (;;);
	}

	// Handle interrupt
  // Ignore and return for this test
	return epc;
}
