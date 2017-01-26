#include "vbx.h"

vbx_mxp_t the_mxp;

void init_mxp(){
	the_mxp.stride=1;
	the_mxp.sp_ptr=SCRATCHPAD_BASE;
	the_mxp.sp_base=SCRATCHPAD_BASE;

	the_mxp.init=1;

}
