#include "lve_test.h"

#define SCRATCHPAD_BASE 0x80000000

#define TEST_LENGTH 16

#define ENUM_TEST_MASK      0x0001
#define VL_TEST_MASK        0x0002
#define OVERWRITE_TEST_MASK 0x0004

#define TEST_RUN_MASK       0xFFFF

#define MAX_TOTAL_ERRORS ((1<<15)-1)

#define INCREMENT_TOTAL_ERRORS() do {						\
	total_errors =																\
		(total_errors == MAX_TOTAL_ERRORS) ?				\
		MAX_TOTAL_ERRORS :													\
		total_errors + 1;														\
	} while(0)

#define DONE_MASK 0x80000000

int lve_test() {
	uint16_t failing_tests = 0x0000;
	uint32_t total_errors  = 0;
	int      element;

	//Vectors, manually allocated in scratchpad
	vbx_uword_t *v_a = ((vbx_uword_t *)SCRATCHPAD_BASE) + 0;
	vbx_uword_t *v_b = ((vbx_uword_t *)SCRATCHPAD_BASE) + TEST_LENGTH;
	vbx_uword_t *v_c = ((vbx_uword_t *)SCRATCHPAD_BASE) + (2*TEST_LENGTH);

	//Scalar data, will keep up to data with vector
	vbx_uword_t a[TEST_LENGTH];
	vbx_uword_t b[TEST_LENGTH];
	vbx_uword_t c[TEST_LENGTH];

	//Initialize data with some known values
	for(element = 0; element < TEST_LENGTH; element++){
		v_a[element] = 0xDEADBEEF + element;
		a[element]   = v_a[element];
		v_b[element] = 1;
		b[element]   = v_b[element];
		v_c[element] = TEST_LENGTH - element;
		c[element]   = v_c[element];
	}

#if (TEST_RUN_MASK & ENUM_TEST_MASK)
	//Initialize an enumerated vector
	vbx_set_vl(TEST_LENGTH);
	vbx(SEWU, VADD, v_a, 0, vbx_ENUM);

	for(element = 0; element < TEST_LENGTH; element++){
		a[element] = 0 + element;
	}

	for(element = 0; element < TEST_LENGTH; element++){
		if(a[element] != v_a[element]){
			failing_tests |= ENUM_TEST_MASK;
			INCREMENT_TOTAL_ERRORS();
			v_a[element] = a[element];
		}
	}
#endif //(TEST_RUN_MASK & ENUM_TEST_MASK)

#if (TEST_RUN_MASK & VL_TEST_MASK)
	//Make sure VL is respected properly
	vbx_set_vl(TEST_LENGTH-3);
	vbx(VVWU, VADD, v_a, v_b, v_c);

	for(element = 0; element < TEST_LENGTH-3; element++){
		a[element] = b[element] + c[element];
	}

	for(element = 0; element < TEST_LENGTH; element++){
		if(a[element] != v_a[element]){
			failing_tests |= VL_TEST_MASK;
			INCREMENT_TOTAL_ERRORS();
			v_a[element] = a[element];
		}
	}
#endif //(TEST_RUN_MASK & VL_TEST_MASK)

#if (TEST_RUN_MASK & OVERWRITE_TEST_MASK)
	//Overwrite source location
	vbx_set_vl(TEST_LENGTH);
	vbx(VVWU, VADD, v_a, v_a, v_a);

	for(element = 0; element < TEST_LENGTH; element++){
		a[element] = a[element] + a[element];
	}

	for(element = 0; element < TEST_LENGTH; element++){
		if(a[element] != v_a[element]){
			failing_tests |= OVERWRITE_TEST_MASK;
			INCREMENT_TOTAL_ERRORS();
			v_a[element] = a[element];
		}
	}
#endif //(TEST_RUN_MASK & OVERWRITE_TEST_MASK)

	return DONE_MASK | (total_errors << 16) | failing_tests;
}
