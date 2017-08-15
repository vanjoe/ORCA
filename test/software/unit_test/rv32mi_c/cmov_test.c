#include "printf.h"
#include "uart.h"
#include "test_passfail.h"
#include "handle_interrupt.h"
#include "vbx.h"

vbx_lve_t the_lve;

#define TEST_ATTR static __attribute__((noinline))

TEST_ATTR int test_2()
{
	int vlen=10;
	vbx_set_vl(vlen);
	vbx_word_t* va=(vbx_word_t*)SCRATCHPAD_BASE;
	vbx_word_t* vb=va+vlen;
	vbx_word_t check[]={1,2,3,4,10,10,10,10,10,10};
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
#define do_test(i) do { if ( test_##i () ) { test_fail(); return i; } } while(0)

int main()
{
	the_lve.stride = 1;

	do_test(2);
	
	test_pass();

	return 0;
}

