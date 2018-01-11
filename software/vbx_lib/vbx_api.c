#include "vbx.h"

vbx_lve_t the_lve;

void init_lve(){

	the_lve.sp_ptr=SCRATCHPAD_BASE;
	the_lve.sp_base=SCRATCHPAD_BASE;

	the_lve.init=1;

}
