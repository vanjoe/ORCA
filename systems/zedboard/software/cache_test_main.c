#include "uart.h"
#include "main.h"
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
#define RUN_UNCACHED_LOOP 1
#define RUN_CACHE_MISSES  1

#define LOOP_RUNS 256

#define CACHE_SIZE      8192
#define CACHE_LINE_SIZE 32

#define TEST_C   1
#define TEST_AUX 1
#define TEST_UC  1

typedef void (*timing_loop)(uint32_t);

#define CSR_XMR_BASE_LAST_STRIDE 8

#define CSR_MAMR0_BASE 0xBD0
#define CSR_MAMR1_BASE (CSR_MAMR0_BASE+1)
#define CSR_MAMR2_BASE (CSR_MAMR0_BASE+2)
#define CSR_MAMR3_BASE (CSR_MAMR0_BASE+3)
#define CSR_MAMR0_LAST (CSR_MAMR0_BASE+0+CSR_XMR_BASE_LAST_STRIDE)
#define CSR_MAMR1_LAST (CSR_MAMR0_BASE+1+CSR_XMR_BASE_LAST_STRIDE)
#define CSR_MAMR2_LAST (CSR_MAMR0_BASE+2+CSR_XMR_BASE_LAST_STRIDE)
#define CSR_MAMR3_LAST (CSR_MAMR0_BASE+3+CSR_XMR_BASE_LAST_STRIDE)
#define CSR_MUMR0_BASE 0xBE0
#define CSR_MUMR1_BASE (CSR_MUMR0_BASE+1)
#define CSR_MUMR2_BASE (CSR_MUMR0_BASE+2)
#define CSR_MUMR3_BASE (CSR_MUMR0_BASE+3)
#define CSR_MUMR0_LAST (CSR_MUMR0_BASE+0+CSR_XMR_BASE_LAST_STRIDE)
#define CSR_MUMR1_LAST (CSR_MUMR0_BASE+1+CSR_XMR_BASE_LAST_STRIDE)
#define CSR_MUMR2_LAST (CSR_MUMR0_BASE+2+CSR_XMR_BASE_LAST_STRIDE)
#define CSR_MUMR3_LAST (CSR_MUMR0_BASE+3+CSR_XMR_BASE_LAST_STRIDE)

#define MSTATUS_MIE_SHIFT  3
#define MSTATUS_MIE_MASK   (1 << MSTATUS_MIE_SHIFT)
#define MSTATUS_MPIE_SHIFT 7
#define MSTATUS_MPIE_MASK  (1 << MSTATUS_MPIE_SHIFT)

#define MCACHE_IEXISTS_SHIFT 0
#define MCACHE_IEXISTS_MASK  (1 << MCACHE_IEXISTS_SHIFT)
#define MCACHE_DEXISTS_SHIFT 0
#define MCACHE_DEXISTS_MASK  (1 << MCACHE_DEXISTS_SHIFT)

//Check for instruction cache
static inline bool orca_has_icache(){
  uint32_t mcache = 0;
  asm volatile("csrr %0, CSR_MCACHE" : "=r"(mcache));
  if(mcache & MCACHE_IEXISTS_MASK){
    return true;
  }
  return false;
}

//Check for data cache
static inline bool orca_has_dcache(){
  uint32_t mcache = 0;
  asm volatile("csrr %0, CSR_MCACHE" : "=r"(mcache));
  if(mcache & MCACHE_DEXISTS_MASK){
    return true;
  }
  return false;
}

//Disable interrupts and return the old MSTATUS value for a future
//restore_interrupts() call.
uint32_t disable_interrupts(){
  uint32_t bits_to_clear    = MSTATUS_MIE_MASK;
  uint32_t previous_mstatus = 0;
  asm volatile("csrrc %0, mstatus, %1" : "=r"(previous_mstatus) : "r"(bits_to_clear));
  return previous_mstatus;
}

//Enable interrupts and return the old MSTATUS value for a future
//restore_interrupts() call.
uint32_t enable_interrupts(){
  uint32_t bits_to_set    = MSTATUS_MIE_MASK;
  uint32_t previous_mstatus = 0;
  asm volatile("csrrs %0, mstatus, %1" : "=r"(previous_mstatus) : "r"(bits_to_set));
  return previous_mstatus;
}

//Restore interrupts based on a previous MSTATUS value.
void restore_interrupts(uint32_t previous_mstatus){
  if(previous_mstatus & MSTATUS_MIE_MASK){
    enable_interrupts();
  } else {
    disable_interrupts();
  }
}

//Return an AMR or UMR bounds in in base/last_ptr
void get_xmr(uint32_t xmr_base_csr_number,
             uint32_t *base_ptr,
             uint32_t *last_ptr){
  uint32_t xmr_last_csr_number = xmr_base_csr_number + 8;

  uint32_t csr_read_value = 0;
  asm volatile("csrr %0, xmr_base_csr_number" : "=r"(csr_read_value));
  *previous_base_ptr = csr_read_value;
  asm volatile("csrr %0, xmr_last_csr_number" : "=r"(csr_read_value));
  *previous_last_ptr = csr_read_value;
}

//Disable an AMR or UMR
//
//Note that if this enables caches on part or all of memory it is the
//programmer's responsibility to have them in a consistent state with
//memory!  Invalidate the cache (or region of memory within the cache)
//being enabled without writing back before running this function if
//unsure.
void disable_xmr(uint32_t xmr_base_csr_number){
  uint32_t xmr_last_csr_number = xmr_base_csr_number + 8;

  uint32_t new_base = 0xFFFFFFFF;
  uint32_t new_last = 0;
  asm volatile("csrw xmr_base_csr_number, %0\n"
               "csrw xmr_last_csr_number, %1\n"
               :: "r"(new_base), "r"(new_last));
}

//Set an AMR or UMR and store the previous values in
//previous_base/last_ptr.
//
//Note that if this enables caches on part or all of memory it is the
//programmer's responsibility to have them in a consistent state with
//memory!  Invalidate the cache (or region of memory within the cache)
//being enabled without writing back before running this function if
//unsure.
//
//Note also that if this disables caches on part or all of memory the
//programmer must handle what happens should the cache be re-enabled.
//An IFENCE is used to make sure the data is written back to memory if
//there is a data cache and a chance of it being disabled, but the
//disabled cache is not invalidated; that is the responsibility of the
//programmer.
void set_xmr(uint32_t xmr_base_csr_number,
             uint32_t new_base,
             uint32_t new_last,
             uint32_t *previous_base_ptr,
             uint32_t *previous_last_ptr){
  bool data_cache_may_be_disabled = false;
  
  //To safely set xMRn we need the following conditions:
  //  If the previous and new regions overlap we must not disable that region while setting the new values
  //    Else if IMEM or DMEM was using them there might be no path to memory
  //  If previous and new regions don't overlap we must not enable the region between them while setting values
  get_xmr(xmr_base_csr_number, previous_base_ptr, previous_last_ptr);
  uint32_t previous_base = *previous_base_ptr;
  uint32_t previous_last = *previous_last_ptr;

  //If previously disabled or new values disable this xMR then set
  //values to the canonical disabed so that setting the new base/last
  //can happen in any order.  Also if the previous and new regions are
  //completely disjoint then disable before enabling.
  if((new_last < new_base) || (previous_last < previous_base) ||
     ((new_last < previous_base) || (previous_last < new_base))){
    disable_xmr(xmr_base_csr_number);
  }

  //If D$ exists, we need to check if it may be disabled by this call.
  //
  //Note that this may not be the case if there are multiple AMRs/UMRs
  //active; it would be possible to check all of them but for now this
  //is conservative and correct.
  if(orca_has_dcache()){
    //D$ may be disabled if this xMR is being enabled and its new
    //region is not contained in the previous region
    if((new_last >= new_base) && ((new_last > previous_last) || (new_base < previous_base))){
      data_cache_may_be_disabled = true;
    }
  }

  //Finally set the values (previous work means they can be set in any order)
  if(data_cache_may_be_disabled){
    //If D$ may be disabled then the D$ must be flushed after the
    //region is modified.  To do so: disable interrupts, set the
    //region, run an IFENCE to flush the D$, then re-enable
    //interrupts.  Interrupts must be disabled so that no memory
    //accesses happen between the last CSR write and the IFENCE.
    uint32_t previous_mstatus = 0;
    disable_interrupts(previous_mstatus);
    asm volatile("csrw xmr_base_csr_number, %0\n"
                 "csrw xmr_last_csr_number, %1\n"
                 "fence.i"
                 :: "r"(new_base), "r"(new_last));
    restore_interrupts(previous_mstatus);

  } else {
    //If not disabling the D$ then it's safe to just set the memory region.
    asm volatile("csrw xmr_base_csr_number, %0\n"
                 "csrw xmr_last_csr_number, %1\n"
                 :: "r"(new_base), "r"(new_last));
  }
}


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
  for(type = 0; type < 2; type++){
    switch(type){
    case 0:
      if(TEST_C){
        ChangedPrint("----------------------------------------\n-- CACHED\n----------------------------------------\n\n");
        
      } else {
        continue;
      }
    default:
      ChangedPrint("Error in type\n");
      continue;
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

#if RUN_UNCACHED_LOOP
  {
    ChangedPrint("Unached loop:\r\n");
    timing_loop the_timing_loop = (timing_loop)((((uintptr_t)(&idram_timing_loop)) & (~MEM_BASE_MASK)) | MEM_UNCACHED_BASE);
  
    uint32_t start_cycle = get_time();
    (*the_timing_loop)(LOOP_RUNS);
    uint32_t end_cycle = get_time();
  
    print_hex(LOOP_RUNS);
    ChangedPrint(" runs of timing loop from uncached memory took ");
    print_hex(end_cycle-start_cycle);
    ChangedPrint(" cycles.\r\n");
  }
#endif //#if RUN_UNCACHED_LOOP

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

  return 0;
}

int handle_interrupt(int cause, int epc, int regs[32])
{
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction.
		ChangedPrint("Illegal Instruction\r\n");
		for (;;);
	}

	// Handle interrupt	
	ChangedPrint("Interrupt\r\n");
	return epc;
}
