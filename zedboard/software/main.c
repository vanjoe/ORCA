#include "uart.h"
#include "main.h"

#define DMEM ((volatile unsigned int *) (0x00004000))

int main(void) {

  volatile unsigned int* data;
  volatile unsigned int i, temp; 

  data = DMEM;
  for (i = 0x20; i < 0x30; i++) {
    *(data++) = i;
  }

  data = DMEM;
  for (i = 0x20; i < 0x30; i++) {
    temp = *(data++);
  }
  
  data = DMEM;
  for (i = 0x20; i < 0x30; i++) {
    *(data) = 2*i;
    temp = *(data++); 
  }

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
