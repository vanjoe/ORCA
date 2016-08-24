



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

		  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
