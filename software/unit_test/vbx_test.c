
#include "../vbx.h"

vbx_lve_t the_lve;

#define TEST_ATTR static __attribute__((noinline))

TEST_ATTR int test_2()
{
	int vlen=10;
	vbx_set_vl(vlen);
	vbx_set_2D(0,0,0);
	vbx(SEW,VADD,(vbx_word_t*)SCRATCHPAD_BASE,1,vbx_ENUM);
	for( int i=0;i<vlen;i++){
		if (((vbx_word_t*)SCRATCHPAD_BASE)[i] != (i+1)){
			return 1; //TEST FAIL
		}
	}

	// TEST SUCCESS
	return 0;
}

TEST_ATTR int test_3()
{
	int vlen=10;
	vbx_set_vl(vlen);
	vbx_set_2D(0,0,0);
	vbx_word_t* a=((vbx_word_t*)SCRATCHPAD_BASE);
	vbx_word_t* b=a+vlen;
	vbx_word_t* c=b+vlen;
	for( int i=0;i<vlen;i++){
		a[i]= 3+i;
	}
	for( int i=0;i<vlen;i++){
		b[i] = 6+i;
	}

	vbx(VVW,VADD,c,b,a);
	for( int i=0;i<vlen;i++){
		if (c[i] != (9 + 2*i) ){
			return 1; //TEST FAIL
		}
	}

	// TEST SUCCESS
	return 0;
}

TEST_ATTR int test_4()
{
	int vlen=10;
	vbx_set_vl(vlen);
	vbx_word_t* dest=((vbx_word_t*)SCRATCHPAD_BASE);
	dest[0]=1;
	//TEST a load word right before a vector instruction

	asm volatile("\n	  \
   mv a0,%0\n									\
	lw a0,  0(a0)\n										\
   vadd.sewwwsss %0, a0,zero \n	  \
": : "r"(dest) : "a0","memory");

	for( int i=0;i<vlen;i++){
		if ( dest[i] != (i+1) ){
			return 1; //TEST FAIL
		}
	}
	return 0;

}

TEST_ATTR int test_5()
{
	int vlen=10;
	vbx_set_vl(vlen);
	vbx_word_t* a=((vbx_word_t*)SCRATCHPAD_BASE);
	vbx_word_t* b=a+vlen;
	vbx_word_t* c=b+vlen;
	for( int i=0;i<vlen;i++){
		a[i]= 3+i;
	}
	for( int i=0;i<vlen;i++){
		b[i] = 6+i;
	}

	vbx_acc(VVW,VADD,c,b,a);
	if (c[0] != 180){
		return 1; //TEST FAIL
	}

	// TEST SUCCESS
	return 0;

}

TEST_ATTR int test_6()
{
	//test storeing word when bit 27 is set in instruction
	vbx_word_t* a =(vbx_word_t*)SCRATCHPAD_BASE;
	vbx_word_t b=15 ;
	asm volatile("sw %1 , 128(%0)"::"r"(a),"r"(b):"memory");
	if(a[128/4] != b)
		return 1;

	// TEST SUCCESS
	return 0;

}



TEST_ATTR int test_7()
{
	//test 0 and 1 length vector instructions
	vbx_word_t* a =(vbx_word_t*)SCRATCHPAD_BASE;
	vbx_word_t b[] ={1,2,3};
	for(int vlen=3;vlen>=0;vlen--){
		vbx_set_vl(vlen);
		vbx(SEW,VAND,a,0,vbx_ENUM);
		vbx(SVW,VADD,a,vlen,a);
	}
	for(int i=0;i<3;i++){
		if(b[i] != a[i]){
			return 1;
		}

	}

	// TEST SUCCESS
	return 0;

}

TEST_ATTR int test_8()
{
	//2d instruction test
	int test_length=10;
	vbx_half_t* v_input=SCRATCHPAD_BASE;
	vbx_word_t* v_output=(vbx_word_t*)(v_input+test_length);
	int i,errors=0;
	for(i=0;i<test_length;i++){
		v_input[i]=i;
	}

	vbx_set_vl(1,test_length/2);
	vbx_set_2D(8,0,4);
	vbx(SVW,VAND, v_output,0xFFFF,   (vbx_word_t*)v_input);
	vbx(SVW,VMULH,v_output+1,(1<<16),(vbx_word_t*)v_input);

	for(i=0;i<test_length;i++){
		if(v_output[i]!=i){
			return 1;
		}
	}

	return errors;
}
TEST_ATTR int test_9()
{
  int vlen=10;
  vbx_set_vl(vlen);
  vbx_word_t* a=((vbx_word_t*)SCRATCHPAD_BASE);
  vbx_word_t* b=a+vlen;
  vbx_word_t* c=b+vlen;
  int acc_check=0;
  for( int i=0;i<vlen;i++){
	a[i]= 3+i;
  }
  for( int i=0;i<vlen;i++){
	b[i] = 6+i;
	acc_check+=b[i]*a[i];
  }

  vbx_acc(VVW,VMUL,c,b,a);
  if (c[0] != acc_check){
	 return 1; //TEST FAIL
  }

  // TEST SUCCESS
  return 0;

}

TEST_ATTR int test_10()
{
  int vlen=10;
  vbx_word_t* a=((vbx_word_t*)SCRATCHPAD_BASE);
  //force load word right before vbx instruction
  vbx_word_t* volatile d=a+vlen;
  int acc_check=0;
  for( int i=0;i<vlen;i++){
	a[i]= 3+i;
  }
  vbx_set_vl(vlen);
  vbx(VVW,VMOV,d,a,0);
  for( int i=0;i<vlen;i++){
  if (d[i] != a[i]){
	 return 1; //TEST FAIL
  }
  }
  // TEST SUCCESS
  return 0;

}


//this macro runs the test, and returns the test number on failure
#define do_test(i) do{if ( test_##i () ) return i;}while(0)

int main()
{
	do_test(2);
	do_test(3);
	do_test(4);
	do_test(5);
	do_test(6);
	do_test(7);
	do_test(8);
	do_test(9);
	do_test(10);
	return 0;

}

int handle_interrupt(int cause, int epc, int regs[32]) {
	if (!((cause >> 31) & 0x1)) {
		// Handle illegal instruction.
		for (;;);
	}
	return epc;
}
