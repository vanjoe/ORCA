



#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN


test_2:
		  li      x1,0xFFFF
		  slli    x3,x1,16
		  sra     x3,x3,16
		  addi    x29,x0,-1
		  addi    x28,x0,2
		  bne     x3,x29,fail

test_3:
		  la      x1, data_3_0
		  la      x2, data_3_1
        lw      x3, 0(x1)
		  lw      x4, 0(x2)
		  addi    x28,x0,3
		  li      x29,0xAAAAAAAA
		  bne     x3,x29,fail
		  li      x29,0xBBBBBBBB
		  bne     x4,x29,fail

		  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

data_3_0:
		  .word 0xAAAAAAAA
data_3_1:
		  .word 0xBBBBBBBB

  TEST_DATA

RVTEST_DATA_END
