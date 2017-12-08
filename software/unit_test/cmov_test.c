
#include "vbx.h"

vbx_lve_t the_lve;

#define TEST_ATTR static __attribute__((noinline))

TEST_ATTR int test_2()
{
	int vlen=10;
	vbx_set_vl(vlen);
	vbx_word_t* va=(vbx_word_t*)SCRATCHPAD_BASE;
	vbx_word_t* vb=va+vlen;
	static const vbx_word_t check[]={1,2,3,4,10,10,10,10,10,10};
	vbx(SEW,VADD,va,1,vbx_ENUM);
	vbx(SVW,VSLT,vb,4,va);
	vbx(SVW,VCMV_NZ,va,10,vb);

	for( int i=0;i<vlen;i++){
		if(va[i] != check[i])
			return 1; //TEST FAIL
	}

	// TEST SUCCESS
	return 0;
}




//this macro runs the test, and returns the test number on failure
#define do_test(TEST_NUMBER) do{                \
    if(test_##TEST_NUMBER()){                   \
      asm volatile ("slli x28, %0,  1\n"        \
                    "ori  x28, x28, 1\n"        \
                    "fence.i\n"                 \
                    "ecall\n"                   \
                    : : "r"(TEST_NUMBER));      \
        return TEST_NUMBER;                     \
    }                                           \
  } while(0)

#define pass_test() do{                         \
    asm volatile ("addi x28, x0, 1\n"           \
                  "fence.i\n"                   \
                  "ecall\n");                   \
    return 0;                                   \
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
