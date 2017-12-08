#include "vbx.h"

#define TEST_ATTR static __attribute__((noinline))
int test_2()
{
	vbx_ubyte_t* sp_data = (vbx_ubyte_t*)(SCRATCHPAD_BASE+8*1024);
	vbx_word_t* sp_data_copy = (vbx_word_t*)(SCRATCHPAD_BASE+16*1024);
	vbx_ubyte_t* dummy_buf = (vbx_ubyte_t*)(SCRATCHPAD_BASE+125*1024);
	vbx_ubyte_t* dummy_in = (vbx_ubyte_t*)(SCRATCHPAD_BASE);

	for(int i=0;i<32;i++){
		sp_data[i] = 0;
		dummy_in[i] = 1;
	}

	for(int i=0;i<32;i++){
		dummy_buf[i] = dummy_in[i];
		sp_data_copy[i] = sp_data[i];
	}

	for(int i = 0;i<32;i++){
		if(sp_data_copy[i] != sp_data[i]){
			return 1; //TEST FAIL
		}
	}

	//TEST SUCCESS
	return 0;
}

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
