
#include "vbx.h"

vbx_lve_t the_lve;

#define TEST_ATTR static __attribute__((noinline))

TEST_ATTR int test_2()
{
	int vlen=10;
	vbx_set_vl(vlen);
	vbx_set_2D(0,0,0);
  asm volatile (
                "vadd.sewwwuuu %0,%1,x0" :
                :
                "r"(SCRATCHPAD_BASE), "r"(1)
                );
	vbx_sync();
	for( int i=0;i<vlen;i++){
		if (((vbx_word_t*)SCRATCHPAD_BASE)[i] != (i+1)){
			return 1; //TEST FAIL
		}
	}

	// TEST SUCCESS
	return 0;
}

//this macro runs the test, and returns the test number on failure
#define do_test(TEST_NUMBER) do{	  \
		if(test_##TEST_NUMBER()){ \
			asm volatile ("li x28, %0\n" \
			              "fence.i\n" \
			              "ecall\n" \
			              : : "i"(TEST_NUMBER)); \
			return TEST_NUMBER; \
		} \
	} while(0)

#define pass_test() do{	  \
		asm volatile ("addi x28, x0, 1\n" \
		              "fence.i\n" \
		              "ecall\n"); \
		return 0; \
	} while(0)

int main()
{
	do_test(2);
	pass_test();
	return 0;

}

int handle_interrupt(int cause, int epc, int regs[32]) {
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction.
		for (;;);
	}
	return epc;
}
