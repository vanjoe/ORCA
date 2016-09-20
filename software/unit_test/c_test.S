



#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

c_begin:
		  la sp, ( data_begin + 2048)
		  jal main
		  mv x28 , a0
		  bnez a0,fail
		  li x28 , 1
		  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

data_begin:
		  .word 00000
TEST_DATA

RVTEST_DATA_END
