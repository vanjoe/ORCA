#include "orca_printf.h"
#include "orca_csrs.h"
#include "orca_memory.h"
#include "orca_time.h"
#include "cache_test.h"

//Assembler macro to create a jump instruction
#define J_FORWARD_BY(BYTES)                     \
  ((((BYTES) << 11) & 0x80000000) |             \
   (((BYTES) << 20) & 0x7FE00000) |             \
   (((BYTES) << 9)  & 0x00100000) |             \
   (((BYTES) << 0)  & 0x000FF000) |             \
   0x6F);

#define WAIT_SECONDS_BEFORE_START 0

#define RUN_ASM_TEST             1
#define RUN_3_INSTRUCTION_LOOP   1
#define RUN_6_INSTRUCTION_LOOP   1
#define RUN_BTB_MISSES           1
#define RUN_CACHE_MISSES         1
#define RUN_CACHE_AND_BTB_MISSES 1

#define LOOP_RUNS 1000

#define CACHE_SIZE      8192
#define CACHE_LINE_SIZE 32
#define BTB_SIZE        64

#define TEST_C   1
#define TEST_AUX 1
#define TEST_UC  1

//Some peripherals are only mapped to UC; when fiddling with xMRs make
//sure that UC peripherals (like UART) are still accesible
#define UC_MIN_MEMORY_BASE 0xC0000000

typedef void (*timing_loop)(uint32_t);

//Creates a 6 instruction timing loop (2 jumps) for testing timing
uint32_t timing_test(uint32_t *first_loop_ptr,
                     uint32_t jump_size_bytes){
      uint32_t *function_copy_ptr = (uint32_t *)(&idram_timing_loop);
      uint32_t *function_copy_end = &idram_timing_loop_end;
      uint32_t timing_loop_size   = (uint32_t)(function_copy_end-function_copy_ptr);

      int word;
      for(word = 0; word < timing_loop_size; word++){
        first_loop_ptr[word] = function_copy_ptr[word];
      }
      for(word = 0; word < timing_loop_size; word++){
        if(first_loop_ptr[word] != function_copy_ptr[word]){
          printf("Error copying function at word 0x%08X expected 0x%08X got 0x%08X", word, (unsigned)(function_copy_ptr[word]), (unsigned)(first_loop_ptr[word]));
        }
      }
      //Overwrite the jump back to the beginning of the loop to a jump
      //forward to the next loop.
      first_loop_ptr[2] = J_FORWARD_BY(jump_size_bytes-(2*sizeof(uint32_t)));

      uint32_t *second_loop_ptr = (uint32_t *)(((uintptr_t)first_loop_ptr)+jump_size_bytes);
      for(word = 0; word < timing_loop_size; word++){
        second_loop_ptr[word] = function_copy_ptr[word];
      }
      //Overwrite the jump back to the beginning of the loop to a jump
      //backward to the previous loop.  The function will ping-pong
      //back and forth between these two loops.
      second_loop_ptr[2] = J_FORWARD_BY(0-(jump_size_bytes+(2*sizeof(uint32_t))));

      //IFENCE to make sure instruction cache gets the correct values
      asm volatile("fence.i");
    
      timing_loop the_timing_loop = (timing_loop)(first_loop_ptr);
  
      uint32_t start_cycle = get_time();
      (*the_timing_loop)(LOOP_RUNS);
      uint32_t end_cycle = get_time();

      return end_cycle-start_cycle;
}

int main(void){
  if(WAIT_SECONDS_BEFORE_START){
    for(int i = 0; i < WAIT_SECONDS_BEFORE_START; i++){
      printf("%d... ", i);
      delayms(1000);
    }
  }

  printf("\r\n\r\n\r\n");

  uint8_t test_space[3*CACHE_SIZE];  //After alignment will have > 2*CACHE_SIZE to work in
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
        printf("\r\n----------------------------------------\r\n-- CACHED\r\n----------------------------------------\r\n");
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
        printf("\r\n----------------------------------------\r\n-- AUX\r\n----------------------------------------\r\n");
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
        printf("\r\n----------------------------------------\r\n-- UNCACHED\r\n----------------------------------------\r\n");
        //Change the UC interface to be everything (besides the AMRs which take priority)
        set_xmr(true, 0, 0x00000000, 0xFFFFFFFF, &previous_umr0_addr_base, &previous_umr0_addr_last);
        //Disable the AUX interface
        disable_xmr(false, 0);
      } else {
        continue;
      }
      break;
    default:
      printf("\r\nError in type\r\n");
      continue;
      break;
    }
  
#if RUN_ASM_TEST
    {
      printf("ASM test: ");

      int result = cache_test((void *)test_space_aligned, 2*CACHE_SIZE, CACHE_SIZE, CACHE_LINE_SIZE);
      if(result){
        printf("ASM test failed with error code 0x%08X\r\n", result);
      } else {
        printf("ASM test passed\r\n");
      }
    }
#endif //#if RUN_ASM_TEST
  
#if RUN_3_INSTRUCTION_LOOP
    {
      printf("3 instruction loop:\r\n");
      timing_loop the_timing_loop = &idram_timing_loop;
  
      uint32_t start_cycle = get_time();
      (*the_timing_loop)(LOOP_RUNS);
      uint32_t end_cycle = get_time();

      uint32_t run_cycles = end_cycle - start_cycle;
  
      printf("%9d cycles for %d runs of 3 instruction loop.\r\n", (int)run_cycles, LOOP_RUNS);
    }
#endif //#if RUN_3_INSTRUCTION_LOOP

#if RUN_6_INSTRUCTION_LOOP
    {
      printf("3 instruction loop (jumping between two copies):\r\n");

      uint32_t timing_loop_size = (uint32_t)(((uintptr_t)(&idram_timing_loop_end))-((uintptr_t)(&idram_timing_loop)));

      uint32_t run_cycles = timing_test((uint32_t *)test_space_aligned, timing_loop_size);
      
      printf("%9d cycles for %d runs of 3 instruction (2 copy) loop.\r\n", (int)run_cycles, LOOP_RUNS);
    }
#endif //#if RUN_6_INSTRUCTION_LOOP

#if RUN_BTB_MISSES
    {
      printf("BTB misses:\r\n");

      uint32_t run_cycles = timing_test((uint32_t *)test_space_aligned, (BTB_SIZE*sizeof(uint32_t)));
  
      printf("%9d cycles for %d runs of 3 instruction (2 copy) loop.\r\n", (int)run_cycles, LOOP_RUNS);
    }
#endif //#if RUN_BTB_MISSES

#if RUN_CACHE_MISSES
    {
      printf("Cache misses:\r\n");

      //Increment by CACHE_SIZE + one word; this gives the same cache
      //line for both timing loops but a different BTB entry (assuming
      //more than one BTB entry)
      uint32_t run_cycles = timing_test((uint32_t *)test_space_aligned, (CACHE_SIZE+sizeof(uint32_t)));
  
      printf("%9d cycles for %d runs of 3 instruction (2 copy) loop.\r\n", (int)run_cycles, LOOP_RUNS);
    }
#endif //#if RUN_CACHE_MISSES

#if RUN_CACHE_AND_BTB_MISSES
    {
      printf("Cache and BTB misses:\r\n");

      uint32_t run_cycles = timing_test((uint32_t *)test_space_aligned, CACHE_SIZE);
  
      printf("%9d cycles for %d runs of 3 instruction (2 copy) loop.\r\n", (int)run_cycles, LOOP_RUNS);
    }
#endif //#if RUN_CACHE_AND_BTB_MISSES

  }

  return 1;
}
