#include "lve_test.h"
#include "printf.h"

#define TEST_LENGTH 16

#define LW_TEST_MASK        0x0001
#define ENUM_TEST_MASK      0x0002
#define VL_TEST_MASK        0x0004
#define OVERWRITE_TEST_MASK 0x0008
#define MULTIPLY_TEST_MASK  0x0010
#define ACCUM_TEST_MASK     0x0020
#define CI_TEST_MASK        0x0040
#define CI_WB_MASK          0x0080
#define CI_CONV_MASK        0x0100
#define TEST_RUN_MASK       CI_CONV_MASK

#define VCI0 VCMV_GTZ
#define VCI1 VCMV_LTZ
#define VCI2 VCMV_GEZ

int lve_test(unsigned int *failing_tests_ptr){
  int errors  = 0;
  int element;

  *failing_tests_ptr = 0;

	//Vectors, manually allocated in scratchpad
	vbx_uword_t *v_a = ((vbx_uword_t *)SCRATCHPAD_BASE) + 0;
	vbx_uword_t *v_b = ((vbx_uword_t *)SCRATCHPAD_BASE) + TEST_LENGTH;
	vbx_uword_t *v_c = ((vbx_uword_t *)SCRATCHPAD_BASE) + (2*TEST_LENGTH);
	vbx_ubyte_t *v_c_byte = (vbx_ubyte_t *)v_c;

	//Scalar data, will keep up to data with vector
	vbx_uword_t a[TEST_LENGTH];
	vbx_uword_t b[TEST_LENGTH];
	vbx_uword_t c[TEST_LENGTH];
	vbx_ubyte_t c_byte[TEST_LENGTH];

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
		*failing_tests_ptr |= LW_TEST_MASK;
		errors++;
  }
  if(add_result != 7){
		v_a[0] = add_result;
		a[0]   = v_a[0];
		*failing_tests_ptr |= LW_TEST_MASK;
		errors++;
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
			*failing_tests_ptr |= ENUM_TEST_MASK;
			errors++;
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
			*failing_tests_ptr |= VL_TEST_MASK;
			errors++;
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
			*failing_tests_ptr |= OVERWRITE_TEST_MASK;
			errors++;
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
			*failing_tests_ptr |= MULTIPLY_TEST_MASK;
			errors++;
			v_a[element] = a[element];
		}
  }
#endif //(TEST_RUN_MASK & MULTIPLY_TEST_MASK)

#if (TEST_RUN_MASK & ACCUM_TEST_MASK)
  vbx_set_vl(TEST_LENGTH);
  //SET VA to all 1s
  vbx(SVWU,VAND,v_a,0,v_a);
  vbx(SVWU,VOR,v_a,1,v_a);

	int scalar_accum = 0;
  for(element = 0 ; element < TEST_LENGTH; element++){
		scalar_accum+=v_a[element];
  }

  vbx_acc(SVWU,VADD,v_a,0,v_a);
  if( scalar_accum != v_a[0]){
		*failing_tests_ptr |= ACCUM_TEST_MASK;
		errors++;
  }
#endif // (TEST_RUN_MASK & ACCUM_TEST_MASK)

#if (TEST_RUN_MASK & CI_TEST_MASK)
  //Initialize data with some known values
  for(element = 0; element < TEST_LENGTH; element++){
		v_a[element] = 0xDEADBEEF + element;
		a[element]   = v_a[element];
		v_b[element] = 2;
		b[element]   = v_b[element];
		v_c[element] = TEST_LENGTH - element;
		c[element]   = v_c[element];
  }

  vbx_set_vl(TEST_LENGTH-3);
  vbx(VVWU, VCI0, v_a, v_b, v_c);

  for(element = 0; element < TEST_LENGTH-3; element++){
		a[element] = b[element] & (~c[element]);
  }

  for(element = 0; element < TEST_LENGTH; element++){
		if(a[element] != v_a[element]){
			*failing_tests_ptr |= CI_TEST_MASK;
			errors++;
			v_a[element] = a[element];
		}
  }

  vbx_set_vl(TEST_LENGTH-3);
  vbx(VVWU, VCI1, v_a, v_b, v_c);

  for(element = 0; element < TEST_LENGTH-3; element++){
		a[element] = c[element] & (~b[element]);
  }

  for(element = 0; element < TEST_LENGTH; element++){
		if(a[element] != v_a[element]){
			*failing_tests_ptr |= CI_TEST_MASK;
			errors++;
			v_a[element] = a[element];
		}
  }
#endif // (TEST_RUN_MASK & CI_TEST_MASK)


#if (TEST_RUN_MASK & CI_WB_MASK)
	//Initialize data with some known values
	for(element = 0; element < TEST_LENGTH; element++){
		v_a[element] = ((element&1)?element: -element)<<5;

		a[element]   = v_a[element];

		if(((signed)a[element]) > 127){
			c_byte[element] = 127;
		}else if(((signed)a[element]) < -128 ){
			c_byte[element] = -128;
		}else{
			c_byte[element] = a[element];
		}

	}
	vbx_set_vl(TEST_LENGTH);
	vbx(VVBWU,VCUSTOM0,v_c_byte,v_a,0);
	for(element = 0; element < TEST_LENGTH; element++){
		if(v_c_byte[element]!= c_byte[element]){
			*failing_tests_ptr |= CI_WB_MASK;
			errors ++;

		}

	}
#endif // (TEST_RUN_MASK & CI_WB_MASK)

#if (TEST_RUN_MASK & CI_WB_MASK)
	//Initialize data with some known values
	for(element = 0; element < TEST_LENGTH; element++){
		v_a[element] = ((element&1)?element: -element)<<5;

		a[element]   = v_a[element];

		if(((signed)a[element]) > 127){
			c_byte[element] = 127;
		}else if(((signed)a[element]) < -128 ){
			c_byte[element] = -128;
		}else{
			c_byte[element] = a[element];
		}

	}
	vbx_set_vl(TEST_LENGTH);
	vbx(VVBWU,VCUSTOM0,v_c_byte,v_a,0);
	for(element = 0; element < TEST_LENGTH; element++){
		if(v_c_byte[element]!= c_byte[element]){
			*failing_tests_ptr |= CI_WB_MASK;
			errors ++;

		}

	}
#endif // (TEST_RUN_MASK & CI_WB_MASK)

#if (TEST_RUN_MASK & CI_CONV_MASK)
	//Initialize data with some known values

	for(element = 0; element < TEST_LENGTH; element++){
		v_c[element]=0x01010101;

	}
	vbx_set_vl(1);
	vbx(SEW,VCUSTOM1,0,0x2,vbx_ENUM);
	vbx_set_vl(3);
	the_mxp.stride=2;
	vbx(VVWWU,VCUSTOM2,v_a,v_c,v_c+1);
	debugx(v_a[2]);

#endif // (TEST_RUN_MASK & CI_CONV_MASK)




	return errors;
}
