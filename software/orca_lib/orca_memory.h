#ifndef __ORCA_MEMORY_H
#define __ORCA_MEMORY_H

#include <stdbool.h>
#include <stdint.h>

//Check for instruction cache
bool orca_has_icache();

//Check for data cache
bool orca_has_dcache();

//Writeback data in D$ to memory.
//
//Note that if the stack is in the address range any updates to it
//during this call may not be written out to memory (the contents of
//the stack from before the call are guranteed to be written out
//though).
void orca_writeback_dcache_range(void *base_address, void *last_address);

//Flush (writeback to memory then invalidate) data in D$.  
//
//It is not recommended to use this for data on the stack.  Not only
//do the caveats from orca_writeback_data_cache_range() apply but also
//data from the stack may be read back in to cache during the function
//call but after the actual flush command.
void orca_flush_dcache_range(void *base_address, void *last_address);

//Invalidate data in D$.
//
//Data in the region may or may not be written back but will be not be
//valid in cache after this call.  The same caveats as for
//orca_flush_dcache_range() apply if using this for data on the stack.
void orca_invalidate_dcache_range(void *base_address, void *last_address);

//Return an AMR or UMR bounds in in base/last_ptr
void get_xmr(bool umr_not_amr,
             uint8_t xmr_number,
             uint32_t *base_ptr,
             uint32_t *last_ptr);

//Disable an AMR or UMR
//
//Note that if this enables caches on part or all of memory it is the
//programmer's responsibility to have them in a consistent state with
//memory!  Invalidate the cache (or region of memory within the cache)
//being enabled without writing back before running this function if
//unsure.
void disable_xmr(bool umr_not_amr,
                 uint8_t xmr_number);

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
void set_xmr(bool umr_not_amr,
             uint8_t xmr_number,
             uint32_t new_base,
             uint32_t new_last,
             uint32_t *previous_base_ptr,
             uint32_t *previous_last_ptr);

#endif //#ifndef __ORCA_MEMORY_H
