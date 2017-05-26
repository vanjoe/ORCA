#include "uart.h"
#include "main.h"

int main(void) {

  for (;;) {
    ChangedPrint("Hello World\r\n");
    delayms(500);
  }

  return 1;
}

int handle_trap(long cause,long epc, long regs[32])
{
	//spin forever
	for(;;);
}
