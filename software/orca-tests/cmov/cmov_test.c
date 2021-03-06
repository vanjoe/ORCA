
#include "vbx.h"

vbx_lve_t the_lve;


#include "orca_csrs.h"
#define VCP_SUPPORT() 	do{ \
	int isa_spec; \
	csrr(misa,isa_spec); \
	if(!(isa_spec & (1<<23))){return 0;} \
	}while(0)


int test_2()
{
	VCP_SUPPORT();
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

typedef int (*test_func)(void) ;
test_func test_functions[] = {
	test_2,
	(void*)0
};
