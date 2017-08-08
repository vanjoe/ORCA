#include "uart.h"
#include "main.h"
#include "cache_test.h"

#define TEST_RUNS 3

#define PS7_MEM_BASE 0x80000000
#define PS7_MEM_SPAN 0x20000000

int main(void) {
  int run = 0;
	for(run = 0; run < TEST_RUNS; run++){
		ChangedPrint("Test run");
		char runText[2];
		runText[0] = '0' + run;
		runText[1] = '\0';
		ChangedPrint(runText);
		ChangedPrint("\r\n");

		int result = cache_test();
		ChangedPrint("Cache test returned ");
		char resultTxt[2];
		resultTxt[0] = '0' + result;
		resultTxt[1] = '\0';
		ChangedPrint(resultTxt);
		ChangedPrint("\r\n");
		delayms(1000);
	}

  return 0;
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
