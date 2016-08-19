#include "lve_test.h"

#define SCRATCHPAD_BASE 0x80000000

#define TEST_LENGTH 16

#define LW_TEST_MASK        0x0001
#define ENUM_TEST_MASK      0x0002
#define VL_TEST_MASK        0x0004
#define OVERWRITE_TEST_MASK 0x0008
#define MULTIPLY_TEST_MASK  0x0010
#define ACCUM_TEST_MASK     0x0020

//#define TEST_RUN_MASK       0xFFFF
#define TEST_RUN_MASK       0x20

#define MAX_TOTAL_ERRORS ((1<<15)-1)

#define INCREMENT_TOTAL_ERRORS() do {				\
	 total_errors =										\
		(total_errors == MAX_TOTAL_ERRORS) ?		\
		MAX_TOTAL_ERRORS :								\
		total_errors + 1;									\
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
	 v_b[element] = 2;
	 b[element]   = v_b[element];
	 v_c[element] = TEST_LENGTH - element;
	 c[element]   = v_c[element];
  }

  //Should be moved into a different test;
  //just running here to make sure I'm not breaking the LSU
  //with my LVE changes. -Aaron
#if (TEST_RUN_MASK & LW_TEST_MASK)
  volatile register uint32_t  lw_result   = 1;
  volatile register uint32_t *lw_source   = (uint32_t *)a;
  volatile register uint32_t  add_result  = 2;
  volatile register uint32_t  add_source0 = 3;
  volatile register uint32_t  add_source1 = 4;
  asm volatile
	 ("lw  t0, 0(%2)\n"
	  "add t1, %3, %4\n"
	  "mv  %0, t0\n"
	  "mv  %1, t1\n"
	  : "=r"(lw_result), "=r"(add_result)
	  : "r"(lw_source), "r"(add_source0), "r"(add_source1)
	  : "t0", "t1"
	  );
  if(lw_result != a[0]){
	 v_a[0] = lw_result;
	 a[0]   = v_a[0];
	 failing_tests |= LW_TEST_MASK;
	 INCREMENT_TOTAL_ERRORS();
  }
  if(add_result != 7){
	 v_a[0] = add_result;
	 a[0]   = v_a[0];
	 failing_tests |= LW_TEST_MASK;
	 INCREMENT_TOTAL_ERRORS();
  }
#endif //(TEST_RUN_MASK & LW_TEST_MASK)

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

#if (TEST_RUN_MASK & MULTIPLY_TEST_MASK)
  //Overwrite source location
  vbx_set_vl(TEST_LENGTH);
  vbx(VVWU, VMUL, v_a, v_b, v_c);

  for(element = 0; element < TEST_LENGTH; element++){
	 a[element] = b[element] * c[element];
  }

  for(element = 0; element < TEST_LENGTH; element++){
	 if(a[element] != v_a[element]){
		failing_tests |= MULTIPLY_TEST_MASK;
		INCREMENT_TOTAL_ERRORS();
		v_a[element] = a[element];
	 }
  }
#endif //(TEST_RUN_MASK & MULTIPLY_TEST_MASK)

#if (TEST_RUN_MASK & ACCUM_TEST_MASK)

  vbx_set_vl(TEST_LENGTH);
  //SET VA to all 1s
  vbx(SVWU,VAND,v_a,0,v_a);
  vbx(SVWU,VOR,v_a,1,v_a);

  for(element = 0 ; element < TEST_LENGTH; element++){
	 scalar_accum+=v_a[element];
  }

  vbx_acc(SVWU,VMUL,v_a,0,v_a);
  if( scalar_accum != v_a[0]){
	 INCREMENT_TOTAL_ERRORS();
  }
#endif // (TEST_RUN_MASK & ACCUM_TEST_MASK)
  return DONE_MASK | (total_errors << 16) | failing_tests;
}
