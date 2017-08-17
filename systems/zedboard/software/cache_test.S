/* For this test, the cache size should be set to 256 bytes,

        * the cache line size should be set to 16 bytes, as well as the TCRAM size should 
 * be set to 64 bytes.
 * In the future, consider automating this by using rdtime as a cycle count to 
 * ensure single cycle accesses are performed at the correct times.
 */

.section .text
.globl cache_test
.type cache_test, @function

.align 8
cache_test:
  // This will first test a miss on invalid data, then consecutive hits. 
  li a0, 9
  li a1, 1
  li a2, 1 
  addi a1, a1, 0
  bne a1, a2, fail1

  // This will test consecutive misses.
  j jump_1
  j fail2
  j fail2
  j fail2

jump_1:
  li a1, 2
  li a3, 1
  beq a1, a2, fail3
  beq a1, a3, fail3

  // This will test cache block eviction.
  // This section should evict the first block with a new tag.
  j jump_2

.align 8 
jump_2:
  li a1, 3
  li a2, 3
  beq a1, a3, fail4
  beq a2, a3, fail4

  // This will test consecutive hits from multiple cache lines.
  j jump_3

.align 8 
jump_3:
  j jump_5
jump_4:
  li a4, 4 
  addi a1, a1, 0
  bne a1, a4, fail5
jump_5:
  li a1, 4
  bne a1, a4, jump_4 
  addi a1, a1, 0
  addi a1, a1, 0

  li a0, 0
  ret 

fail1:
  li a0, 1
  ret
fail2:
  li a0, 2
  ret
fail3:
  li a0, 3
  ret
fail4:
  li a0, 4
  ret
fail5:
  li a0, 5
  ret
fail:
  li a0, 8
  ret

.globl idram_timing_loop
.type idram_timing_loop, @function
        
//These get copied into cacheable/uncacheable memory for testing timing
idram_timing_loop:
  beq  a0, x0, idram_timing_loop_ret
  addi a0, a0, -1
  jal  x0, idram_timing_loop
idram_timing_loop_ret:
  ret

.globl idram_timing_loop_end
.type idram_timing_loop_end, @object
idram_timing_loop_end:
.word 0
