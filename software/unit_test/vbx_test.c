
#include "vbx.h"

vbx_mxp_t the_mxp;

#define TEST_ATTR static __attribute__((noinline))

TEST_ATTR int test_2()
{
  int vlen=10;
  vbx_set_vl(vlen);
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
  vbx_word_t* a=((vbx_word_t*)SCRATCHPAD_BASE);
  vbx_word_t* b=a+vlen;
  vbx_word_t* c=b+vlen;
  for( int i=0;i<vlen;i++){
	a[i]= 3;
  }
  for( int i=0;i<vlen;i++){
	b[i] = 6;
  }

  vbx(VVW,VMUL,c,b,a);
  for( int i=0;i<vlen;i++){
	 if (c[i] != 18){
		return 1; //TEST FAIL
	 }
  }

  // TEST SUCCESS
  return 0;
}

TEST_ATTR int test_4()
{
  int vlen=10;
  vbx_word_t* dest=((vbx_word_t*)SCRATCHPAD_BASE);
  dest[0]=1;
  //TEST a load word right before a vector instruction
  asm volatile("\n\
   li a0,0x80000000\n									\
	lw a0,  0(a0)\n										\
   vtype.www	a0,x0\n										\
   vadd.se.1d.sss	%0,%1\n									\
": : "r"(dest),"r"(vlen) : "a0","memory");

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
	a[i]= 3;
  }
  for( int i=0;i<vlen;i++){
	b[i] = 6;
  }

  vbx_acc(VVW,VMUL,c,b,a);
  if (c[0] != 180){
	 return 1; //TEST FAIL
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
  return 0;

}
