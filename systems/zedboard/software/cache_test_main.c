#include "uart.h"
#include "main.h"
#include "cache_test.h"

#define WAIT_SECONDS_BEFORE_START 10

#define RUN_ASM_TEST    1
#define RUN_IDRAM_LOOP  1
#define RUN_CACHED_LOOP 1

#define LOOP_RUNS 1000

#define PS7_MEM_CACHED_BASE   0x00000000
#define PS7_MEM_UNCACHED_BASE 0x80000000
#define PS7_MEM_SPAN          0x20000000

typedef void (*timing_loop)(uint32_t);

int main(void) {
  for(int i = 0; i < WAIT_SECONDS_BEFORE_START; i++){
    ChangedPrint("Waiting...");
    delayms(1000);
  }
#if RUN_ASM_TEST
  {
    ChangedPrint("ASM cache test:\r\n");

    int result = cache_test();
    ChangedPrint("Cache test returned ");
    print_hex(result);
    ChangedPrint("\r\n");
  }
#endif //#if RUN_ASM_TEST
  
#if RUN_IDRAM_LOOP
  {
    ChangedPrint("IDRAM loop:\r\n");
    timing_loop the_timing_loop = &idram_timing_loop;
  
    uint32_t start_cycle = get_time();
    (*the_timing_loop)(LOOP_RUNS);
    uint32_t end_cycle = get_time();
  
    print_hex(LOOP_RUNS);
    ChangedPrint(" runs of timing loop from idram took ");
    print_hex(end_cycle-start_cycle);
    ChangedPrint(" cycles.\r\n");
  }
#endif //#if RUN_IDRAM_LOOP

#if RUN_CACHED_LOOP
  {
    ChangedPrint("Cached loop:\r\n");
    uint32_t *function_copy_ptr = (uint32_t *)(&idram_timing_loop);
    uint32_t *function_copy_end = &idram_timing_loop_end;
    uint32_t timing_loop_size   = (uint32_t)(function_copy_end-function_copy_ptr);

    uint32_t *function_destination_ptr = (uint32_t *)PS7_MEM_UNCACHED_BASE;

    int word;
    for(word = 0; word < timing_loop_size; word++){
      function_destination_ptr[word] = function_copy_ptr[word];
    }
    ChangedPrint("Function copied to PS7 memory\r\n");
    for(word = 0; word < timing_loop_size; word++){
      if(function_destination_ptr[word] != function_copy_ptr[word]){
        ChangedPrint("Error at word ");
        print_hex(word);
        ChangedPrint(" expected ");
        print_hex(function_copy_ptr[word]);
        ChangedPrint(" got ");
        print_hex(function_destination_ptr[word]);
        ChangedPrint("\r\n");
      }
    }
    
    timing_loop the_timing_loop = (timing_loop)(PS7_MEM_CACHED_BASE);
  
    uint32_t start_cycle = get_time();
    (*the_timing_loop)(LOOP_RUNS);
    uint32_t end_cycle = get_time();
  
    print_hex(LOOP_RUNS);
    ChangedPrint(" runs of timing loop from PS7 memory (cached) took ");
    print_hex(end_cycle-start_cycle);
    ChangedPrint(" cycles.\r\n");
  }
#endif //#if RUN_CACHED_LOOP

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
