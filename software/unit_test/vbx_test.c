
#include "vbx.h"

vbx_mxp_t the_mxp;

int test_2()
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

int test_3()
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

//this macro runs the test, and returns the test number on failure
#define do_test(i) do{if ( test_##i () ) return i;}while(0)

int main()
{

  do_test(2);
  do_test(3);
  return 0;

}
