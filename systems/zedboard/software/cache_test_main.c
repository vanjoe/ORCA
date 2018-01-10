#include "uart.h"
#include "orca_csrs.h"
#include "orca_memory.h"
#define ORCA_CLK 100000000
#include "orca_time.h"
#include "cache_test.h"

#define J_FORWARD_BY(BYTES)                     \
  ((((BYTES) << 11) & 0x80000000) |             \
   (((BYTES) << 20) & 0x7FE00000) |             \
   (((BYTES) << 9)  & 0x00100000) |             \
   (((BYTES) << 0)  & 0x000FF000) |             \
   0x6F);

#define WAIT_SECONDS_BEFORE_START 0

#define RUN_ASM_TEST      1
#define RUN_CACHED_LOOP   1
#define RUN_CACHE_MISSES  1

#define LOOP_RUNS 256

#define CACHE_SIZE      8192
#define CACHE_LINE_SIZE 32

#define TEST_C   1
#define TEST_AUX 1
#define TEST_UC  1

//Some peripherals are only mapped to UC; when fiddling with xMRs make
//sure that UC peripherals (like UART) are still accesible
#define UC_MIN_MEMORY_BASE 0xC0000000

typedef void (*timing_loop)(uint32_t);

int main(void) {
  if(WAIT_SECONDS_BEFORE_START){
    for(int i = 0; i < WAIT_SECONDS_BEFORE_START; i++){
      print_hex(i);
      ChangedPrint(" ...");
      delayms(1000);
    }
    ChangedPrint("\r\n");
  }

  uint8_t test_space[3*CACHE_SIZE];
  uint8_t *test_space_aligned = (uint8_t *)((((uintptr_t)test_space) + (CACHE_SIZE-1)) & (~(CACHE_SIZE-1)));

  uint32_t previous_amr0_addr_base = 0;
  uint32_t previous_amr0_addr_last = 0;
  uint32_t previous_umr0_addr_base = 0;
  uint32_t previous_umr0_addr_last = 0;

  int type = 0;
  for(type = 0; type < 3; type++){
    switch(type){
    case 0:
      if(TEST_C){
        ChangedPrint("----------------------------------------\r\n-- CACHED\r\n----------------------------------------\r\n\r\n");
        //Disable the AUX interface
        disable_xmr(false, 0);
        //Change the UC interface to be only the peripherals
        set_xmr(true, 0, UC_MIN_MEMORY_BASE, 0xFFFFFFFF, &previous_umr0_addr_base, &previous_umr0_addr_last);
      } else {
        continue;
      }
      break;
    case 1:
      if(TEST_AUX){
        ChangedPrint("----------------------------------------\r\n-- AUX\r\n----------------------------------------\r\n\r\n");
        //Set the AUX memory interface to the non-UC addresses
        set_xmr(false, 0, 0x00000000, UC_MIN_MEMORY_BASE-1, &previous_amr0_addr_base, &previous_amr0_addr_last);
        //Change the UC interface to be only the peripherals
        set_xmr(true, 0, UC_MIN_MEMORY_BASE, 0xFFFFFFFF, &previous_umr0_addr_base, &previous_umr0_addr_last);
      } else {
        continue;
      }
      break;
    case 2:
      if(TEST_UC){
        ChangedPrint("----------------------------------------\r\n-- UNCACHED\r\n----------------------------------------\r\n\r\n");
        //Change the UC interface to be everything (besides the AMRs which take priority)
        set_xmr(true, 0, 0x00000000, 0xFFFFFFFF, &previous_umr0_addr_base, &previous_umr0_addr_last);
        //Disable the AUX interface
        disable_xmr(false, 0);
      } else {
        continue;
      }
      break;
    default:
      ChangedPrint("Error in type\r\n");
      continue;
      break;
    }
  
#if RUN_ASM_TEST
    {
      ChangedPrint("ASM test:\r\n");

      int result = cache_test((void *)test_space_aligned, 2*CACHE_SIZE, CACHE_SIZE, CACHE_LINE_SIZE);
      ChangedPrint("ASM test returned ");
      print_hex(result);
      ChangedPrint("\r\n");
    }
#endif //#if RUN_ASM_TEST
  
#if RUN_CACHED_LOOP
    {
      ChangedPrint("3 instruction loop:\r\n");
      timing_loop the_timing_loop = &idram_timing_loop;
  
      uint32_t start_cycle = get_time();
      (*the_timing_loop)(LOOP_RUNS);
      uint32_t end_cycle = get_time();
  
      print_hex(LOOP_RUNS);
      ChangedPrint(" runs of 3 instruction loop from took ");
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

      uint32_t *function_destination_ptr = (uint32_t *)test_space_aligned;

      int word;
      for(word = 0; word < timing_loop_size; word++){
        function_destination_ptr[word] = function_copy_ptr[word];
      }
      ChangedPrint("Function copied to test_space.\r\n");
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
      function_destination_ptr[2] = J_FORWARD_BY(CACHE_SIZE-(2*sizeof(uint32_t)));

      function_destination_ptr = (uint32_t *)(test_space_aligned+CACHE_SIZE);
      for(word = 0; word < timing_loop_size; word++){
        function_destination_ptr[word] = function_copy_ptr[word];
      }
      //Overwrite the jump back to the beginning of the loop to a jump
      //backward to the previous conflicting line in the cache.  The
      //function will ping-pong back and forth between these two lines
      //and always cause a conflict miss.
      function_destination_ptr[2] = J_FORWARD_BY(0-(CACHE_SIZE+(2*sizeof(uint32_t))));
    
    
      timing_loop the_timing_loop = (timing_loop)(test_space_aligned);
  
      uint32_t start_cycle = get_time();
      (*the_timing_loop)(LOOP_RUNS);
      uint32_t end_cycle = get_time();
  
      print_hex(LOOP_RUNS);
      ChangedPrint(" runs of cache miss timing loop took ");
      print_hex(end_cycle-start_cycle);
      ChangedPrint(" cycles.\r\n");
    }
#endif //#if RUN_CACHE_MISSES

  }

  return 0;
}


int handle_interrupt(int cause, int epc, int regs[32])
{
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction
    // Nothing implemented yet; just print a debug message and hang.
		ChangedPrint("Unhandled illegal instruction...\r\n");
		for (;;);
	}

	// Handle interrupt
  // Ignore and return for this test
	return epc;
}
