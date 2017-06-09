/* For this test, the cache size should be set to 256 bytes,
 * the cache line size should be set to 12 bytes, as well as the TCRAM size should 
 * be set to 64 bytes.
 */

.section .text
.globl cache_test
.type cache_test, @function

.section .cache_test_1
cache_test:
  // This will first test a miss on invalid data, then consecutive hits. 
  li x1, 1
  li x2, 1 
  bne x1, x2, FAIL

  // This will test consecutive misses.
  j jump_1
  j FAIL
  j FAIL

jump_1:
  li x1, 2
  li x2, 2
  bne x1, x2, FAIL

  // This will test cache block eviction.
  // This section should evict the first block with a new tag.
  j jump_2

.section .cache_test_2
jump_2:
  li x1, 3
  li x2, 3
  bne x1, x2, FAIL

  // This will test consecutive hits from multiple cache lines.
  j jump_3

.section .cache_test_3
jump_3

  ret 




FAIL:
  csrc mstatus, 0x00000008
  fence
  li t3, -1
  fence
fail_ecall:
  ecall
  j fail_ecall
