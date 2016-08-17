#include "lve_test.h"

int lve_test() {
  int retval = 0;
  vbx_uword_t* scratchpad_base = (vbx_uword_t*)0x80000000;

	vbx_uword_t* a=scratchpad_base+0;
	vbx_uword_t* b=scratchpad_base+6;
	vbx_uword_t* c=scratchpad_base+12;
  
	b[0]=3;
	b[1]=3;
	b[2]=3;
	b[3]=3;
	b[4]=3;
	b[5]=3;

	c[0]=10;
	c[1]=9;
	c[2]=8;
	c[3]=7;
	c[4]=6;
	c[5]=5;

	vbx_set_vl(6);
	vbx(SEWU,VADD,a,0,vbx_ENUM);
	vbx_set_vl(4);
	vbx(VVWU,VADD,a,b,c);

  if (a[0] != 13)
    retval |= 0x1;
  if (a[1] != 12)
    retval |= 0x2;
  if (a[2] != 11)
    retval |= 0x4;
  if (a[3] != 10)
    retval |= 0x8;
  if (a[4] != 4)
    retval |= 0x10;
  if (a[5] != 5)
    retval |= 0x20;

	retval |= 0x80000000;

  return retval;
}
