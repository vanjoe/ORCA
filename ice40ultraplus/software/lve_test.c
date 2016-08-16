#include "lve_test.h"

int lve_test() {
  int retval = 0;
  vbx_uhalf_t* scratchpad_base = (vbx_uhalf_t*)0x80000000;

	vbx_uhalf_t* a=scratchpad_base+0;
	vbx_uhalf_t* b=scratchpad_base+6;
	vbx_uhalf_t* c=scratchpad_base+12;
  
	b[0]=3;
	b[1]=3;
	b[2]=3;
	b[3]=3;
	b[4]=3;
	b[5]=3;

	c[0]=4;
	c[1]=4;
	c[2]=4;
	c[3]=4;
	c[4]=4;
	c[5]=4;

	vbx_set_vl(6);
	vbx(SEHU,VADD,a,0,vbx_ENUM);
	vbx_set_vl(4);
	vbx(VVHU,VADD,a,b,c);

  if (a[0] != 7)
    retval |= 0x1;
  if (a[1] != 7)
    retval |= 0x2;
  if (a[2] != 7)
    retval |= 0x4;
  if (a[3] != 7)
    retval |= 0x8;
  if (a[4] != 0)
    retval |= 0x10;
  if (a[5] != 0)
    retval |= 0x20;

  return retval;
}
