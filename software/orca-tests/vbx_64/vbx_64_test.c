
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
typedef int (*test_func)(void) ;
test_func test_functions[] = {
	test_2,
	(void*)0
};
