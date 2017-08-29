#include "uart.h"
#include "main.h"
#include "cache_test.h"

#define J_FORWARD_BY(BYTES)                     \
  ((((BYTES) << 11) & 0x80000000) |             \
   (((BYTES) << 20) & 0x7FE00000) |             \
   (((BYTES) << 9)  & 0x00100000) |             \
   (((BYTES) << 0)  & 0x000FF000) |             \
   0x6F);

#define USE_ONCHIP_MEM 0

#define WAIT_SECONDS_BEFORE_START 0

#define RUN_ASM_TEST     1
#define RUN_IDRAM_LOOP   1
#define RUN_CACHED_LOOP  1
#define RUN_CACHE_MISSES 1

#define LOOP_RUNS 256

#define ICACHE_SIZE      8192
#define ICACHE_LINE_SIZE 16

//Target the last half of PS memory; the first bit does not seem set up as writeable.
#define PS7_MEM_CACHED_BASE   0x10000000
#define PS7_MEM_UNCACHED_BASE 0x10000000
#define PS7_MEM_SPAN          0x10000000

#define ONCHIP_MEM_CACHED_BASE   0x50000000
#define ONCHIP_MEM_UNCACHED_BASE 0xD0000000
#define ONCHIP_MEM_SPAN          0x00020000

#if USE_ONCHIP_MEM
#define NOT_TCM_CACHED_BASE   ONCHIP_MEM_CACHED_BASE
#define NOT_TCM_UNCACHED_BASE ONCHIP_MEM_UNCACHED_BASE
#define NOT_TCM_SPAN          ONCHIP_MEM_SPAN
#else //#if USE_ONCHIP_MEM
#define NOT_TCM_CACHED_BASE   PS7_MEM_CACHED_BASE
#define NOT_TCM_UNCACHED_BASE PS7_MEM_UNCACHED_BASE
#define NOT_TCM_SPAN          PS7_MEM_SPAN
#endif //#else //#if USE_ONCHIP_MEM

typedef void (*timing_loop)(uint32_t);

int main(void) {
  for(int i = 0; i < WAIT_SECONDS_BEFORE_START; i++){
    print_hex(i);
    ChangedPrint(" ...");
    delayms(1000);
  }
  ChangedPrint("\r\n");
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

    uint32_t *function_destination_ptr = (uint32_t *)NOT_TCM_UNCACHED_BASE;

    int word;
    for(word = 0; word < timing_loop_size; word++){
      function_destination_ptr[word] = function_copy_ptr[word];
    }
    ChangedPrint("Function copied to not TCM.\r\n");
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
    
    timing_loop the_timing_loop = (timing_loop)(NOT_TCM_CACHED_BASE);
  
    uint32_t start_cycle = get_time();
    (*the_timing_loop)(LOOP_RUNS);
    uint32_t end_cycle = get_time();
  
    print_hex(LOOP_RUNS);
    ChangedPrint(" runs of timing loop from not TCM (cached) took ");
    print_hex(end_cycle-start_cycle);
    ChangedPrint(" cycles.\r\n");
  }
#endif //#if RUN_CACHED_LOOP

#if RUN_CACHE_MISSES
  {
    ChangedPrint("Cache misses:\r\n");
    uint32_t *function_copy_ptr = (uint32_t *)(&idram_timing_loop);
    uint32_t *function_copy_end = &idram_timing_loop_end;
    uint32_t timing_loop_size   = (uint32_t)(function_copy_end-function_copy_ptr);

    uint32_t *function_destination_ptr = (uint32_t *)(NOT_TCM_UNCACHED_BASE+ICACHE_SIZE);

    int word;
    for(word = 0; word < timing_loop_size; word++){
      function_destination_ptr[word] = function_copy_ptr[word];
    }
    ChangedPrint("Function copied to not TCM.\r\n");
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
    //Overwrite the jump back to the beginning of the loop to a jump
    //forward to the next conflicting line in the cache.
    function_destination_ptr[2] = J_FORWARD_BY(ICACHE_SIZE-(2*sizeof(uint32_t)));

    function_destination_ptr = (uint32_t *)(NOT_TCM_UNCACHED_BASE+(2*ICACHE_SIZE));
    for(word = 0; word < timing_loop_size; word++){
      function_destination_ptr[word] = function_copy_ptr[word];
    }
    //Overwrite the jump back to the beginning of the loop to a jump
    //backward to the previous conflicting line in the cache.  The
    //function will ping-pong back and forth between these two lines
    //and always cause a conflict miss.
    function_destination_ptr[2] = J_FORWARD_BY(0-(ICACHE_SIZE+(2*sizeof(uint32_t))));
    
    
    timing_loop the_timing_loop = (timing_loop)(NOT_TCM_CACHED_BASE+ICACHE_SIZE);
  
    uint32_t start_cycle = get_time();
    (*the_timing_loop)(LOOP_RUNS);
    uint32_t end_cycle = get_time();
  
    print_hex(LOOP_RUNS);
    ChangedPrint(" runs of timing loop from not TCM (cached) took ");
    print_hex(end_cycle-start_cycle);
    ChangedPrint(" cycles.\r\n");
  }
#endif //#if RUN_CACHE_MISSES

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
