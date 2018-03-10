
#include "vbx.h"
#include "orca_csrs.h"
vbx_lve_t the_lve;

#define TEST_ATTR static __attribute__((noinline))
#define VCP_SUPPORT() 	do{ \
	int isa_spec; \
	csrr(misa,isa_spec); \
	if(!(isa_spec & (1<<23))){return 0;} \
	}while(0)


TEST_ATTR int test_2()
{
	VCP_SUPPORT();
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
