#include "orca_printf.h"
#include "orca_csrs.h"
#include "orca_memory.h"
#include "orca_malloc.h"
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
#define RUN_RW_TEST              1
#define RUN_3_INSTRUCTION_LOOP   1
#define RUN_6_INSTRUCTION_LOOP   1
#define RUN_BTB_MISSES           1
#define RUN_CACHE_MISSES         1
#define RUN_CACHE_AND_BTB_MISSES 1

#define LOOP_RUNS 1000

#define CACHE_SIZE      8192
#define CACHE_LINE_SIZE 32
#define BTB_SIZE        64

//Heap in PS memory.  Don't start at 0 to avoid NULL pointer checks.
#define HEAP_ADDRESS 0x00100000
#define HEAP_SIZE    0x00100000

#define TEST_C_STACK   1
#define TEST_C_HEAP    1
#define TEST_UC_STACK  1
#define TEST_UC_HEAP   1
#define TEST_AUX_STACK 1
#define TEST_AUX_HEAP  0

//Some peripherals are only mapped to UC; when fiddling with xMRs make
//sure that UC peripherals (like UART) are still accesible
#define UC_MIN_MEMORY_BASE 0xC0000000

typedef void (*timing_loop)(uint32_t);

uint32_t rw_test(void *mem_base, uint32_t mem_size, uint32_t cache_size, uint32_t cache_line_size){
  int *test_space32 = (int *)mem_base;

  //Test back-to-back reads and writes that hit in the same line
  for(int run = 0; run < 10; run++){
    test_space32[0] = 1;
    test_space32[1] = 2;
    test_space32[2] = 3;
    test_space32[3] = 4;
    
    int r1 = 5;
    int r2 = 6;
    int r3 = 7;
    int r4 = 8;
    asm volatile
      ("lw %0, 0(%4)\n"
       "sw %2, 4(%4)\n"
       "lw %1, 8(%4)\n"
       "sw %3, 12(%4)\n"
       : "=r"(r1), "=r"(r3) : "r"(r2), "r"(r4), "r"(test_space32) : "memory" );
    if(test_space32[0] != 1){
      printf("Run %d same line error with test_space32[0]; expected %d got %d\r\n", run, 1, test_space32[0]);
      return 1;
    }
    if(test_space32[1] != 6){
      printf("Run %d same line error with test_space32[1]; expected %d got %d\r\n", run, 6, test_space32[1]);
      return 2;
    }
    if(test_space32[2] != 3){
      printf("Run %d same line error with test_space32[2]; expected %d got %d\r\n", run, 3, test_space32[2]);
      return 3;
    }
    if(test_space32[3] != 8){
      printf("Run %d same line error with test_space32[3]; expected %d got %d\r\n", run, 8, test_space32[3]);
      return 4;
    }
    if(r1 != 1){
      printf("Run %d same line error with r1; expected %d got %d\r\n", run, 1, r1);
      return 5;
    }
    if(r2 != 6){
      printf("Run %d same line error with r2; expected %d got %d\r\n", run, 6, r2);
      return 6;
    }
    if(r3 != 3){
      printf("Run %d same line error with r3; expected %d got %d\r\n", run, 3, r3);
      return 7;
    }
    if(r4 != 8){
      printf("Run %d same line error with r4; expected %d got %d\r\n", run, 8, r4);
      return 8;
    }
  }

  //Test back-to-back write/read in different lines
  for(int run = 0; run < 10; run++){
    test_space32[0]  = 1;
    test_space32[17] = 2;
    test_space32[34] = 3;
    test_space32[51] = 4;
    
    int r1 = 5;
    int r2 = 6;
    int r3 = 7;
    int r4 = 8;
    asm volatile
      ("lw %0, 0(%4)\n"
       "sw %2, 68(%4)\n"
       "lw %1, 136(%4)\n"
       "sw %3, 204(%4)\n"
       : "=r"(r1), "=r"(r3) : "r"(r2), "r"(r4), "r"(test_space32) : "memory" );
    if(test_space32[0] != 1){
      printf("Run %d different line error with test_space32[0]; expected %d got %d\r\n", run, 1, test_space32[0]);
      return 1;
    }
    if(test_space32[1] != 6){
      printf("Run %d different line error with test_space32[1]; expected %d got %d\r\n", run, 6, test_space32[1]);
      return 2;
    }
    if(test_space32[2] != 3){
      printf("Run %d different line error with test_space32[2]; expected %d got %d\r\n", run, 3, test_space32[2]);
      return 3;
    }
    if(test_space32[3] != 8){
      printf("Run %d different line error with test_space32[3]; expected %d got %d\r\n", run, 8, test_space32[3]);
      return 4;
    }
    if(r1 != 1){
      printf("Run %d different line error with r1; expected %d got %d\r\n", run, 1, r1);
      return 5;
    }
    if(r2 != 6){
      printf("Run %d different line error with r2; expected %d got %d\r\n", run, 6, r2);
      return 6;
    }
    if(r3 != 3){
      printf("Run %d different line error with r3; expected %d got %d\r\n", run, 3, r3);
      return 7;
    }
    if(r4 != 8){
      printf("Run %d different line error with r4; expected %d got %d\r\n", run, 8, r4);
      return 8;
    }
  }
  
  //Regression for bug found in cache write misses
  for(int run = 0; run < 10; run++){
    test_space32[0]                      = 0x11111111;
    test_space32[cache_size/sizeof(int)] = 0x22222222;
    int return_value = 0;
    asm volatile
      ("mv   t0, %1    \n"
       "mv   t1, %2    \n"
       "lw   t0, 0(t0) \n"
       "sw   t1, 0(t1) \n"
       "lw   %0, 0(%1) \n"
       : "=r"(return_value) : "r"(test_space32), "r"(test_space32+(cache_size/sizeof(int))) : "t0", "t1", "memory" );
    if(return_value != 0x11111111){
      printf("Run %d regression 1 error with return value; expected %d got %d\r\n", run, 0x11111111, return_value);
      return 1;
    }
    if(test_space32[0] != 0x11111111){
      printf("Run %d regression 1 error with test_space32[0]; expected %d got %d\r\n", run, 0x22222222, test_space32[0]);
      return 2;
    }
    if(test_space32[cache_size/sizeof(int)] != ((int)(test_space32+(cache_size/sizeof(int))))){
      printf("Run %d regression 1 error with test_space32[cache_size/sizeof(int)]; expected %d got %d\r\n", run, ((int)(test_space32+(cache_size/sizeof(int)))), test_space32[cache_size/sizeof(int)]);
      return 3;
    }
  }
  
  return 0;
}

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
      bool error_found = false;
      for(word = 0; word < timing_loop_size; word++){
        if(first_loop_ptr[word] != function_copy_ptr[word]){
          printf("Error copying function at word 0x%08X expected 0x%08X got 0x%08X\r\n", word, (unsigned)(function_copy_ptr[word]), (unsigned)(first_loop_ptr[word]));
          error_found = true;
        }
      }
      if(error_found){
        return 0;
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

  uint8_t test_space_stack[3*CACHE_SIZE];  //After alignment will have > 2*CACHE_SIZE to work in
  init_malloc((void *)HEAP_ADDRESS, HEAP_SIZE, CACHE_SIZE);
  uint8_t *test_space_heap = (uint8_t *)malloc(2*CACHE_SIZE);
  

  uint32_t previous_amr0_addr_base = 0;
  uint32_t previous_amr0_addr_last = 0;
  uint32_t previous_umr0_addr_base = 0;
  uint32_t previous_umr0_addr_last = 0;

  int type = 0;
  for(type = 0; type < 6; type++){
    switch(type){
    case 0:
      if(!TEST_C_STACK){
        continue;
      }
    case 1:
      if((type == 1) && (!TEST_C_HEAP)){
        continue;
      }
      printf("\r\n----------------------------------------\r\n-- CACHED\r\n");
      //Disable the AUX interface
      disable_xmr(false, 0);
      //Change the UC interface to be only the peripherals
      set_xmr(true, 0, UC_MIN_MEMORY_BASE, 0xFFFFFFFF, &previous_umr0_addr_base, &previous_umr0_addr_last);
      break;
    case 2:
      if(!TEST_UC_STACK){
        continue;
      }
    case 3:
      if((type == 3) && (!TEST_UC_HEAP)){
        continue;
      }
      printf("\r\n----------------------------------------\r\n-- UNCACHED\r\n");
      //Change the UC interface to be everything (besides the AMRs which take priority)
      set_xmr(true, 0, 0x00000000, 0xFFFFFFFF, &previous_umr0_addr_base, &previous_umr0_addr_last);
      //Disable the AUX interface
      disable_xmr(false, 0);
      break;
    case 4:
      if(!TEST_AUX_STACK){
        continue;
      }
    case 5:
      if((type == 5) && (!TEST_AUX_HEAP)){
        continue;
      }
      printf("\r\n----------------------------------------\r\n-- AUX\r\n");
      //Set the AUX memory interface to the non-UC addresses
      set_xmr(false, 0, 0x00000000, UC_MIN_MEMORY_BASE-1, &previous_amr0_addr_base, &previous_amr0_addr_last);
      //Change the UC interface to be only the peripherals
      set_xmr(true, 0, UC_MIN_MEMORY_BASE, 0xFFFFFFFF, &previous_umr0_addr_base, &previous_umr0_addr_last);
      break;
    default:
      printf("\r\nError in type\r\n");
      continue;
      break;
    }

    uint8_t *test_space_aligned = NULL;
    if(type & 0x01){
      test_space_aligned = test_space_heap;
      printf("-- HEAP\r\n");
    } else {
      test_space_aligned = (uint8_t *)((((uintptr_t)test_space_stack) + (CACHE_SIZE-1)) & (~(CACHE_SIZE-1)));
      printf("-- STACK\r\n");
    }
    printf("----------------------------------------\r\n");
    
    
    
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
  
#if RUN_RW_TEST
    {
      printf("RW test: ");

      int result = rw_test((void *)test_space_aligned, 2*CACHE_SIZE, CACHE_SIZE, CACHE_LINE_SIZE);
      if(result){
        printf("RW test failed with error code 0x%08X\r\n", result);
      } else {
        printf("RW test passed\r\n");
      }
    }
#endif //#if RUN_ASM_TEST
  
#if RUN_3_INSTRUCTION_LOOP
    {
      printf("3 instruction loop:\r\n");
  
      uint32_t run_cycles = timing_test(((uint32_t *)test_space_aligned)+1, 0);
      
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
