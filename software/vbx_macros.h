#ifndef MACROS_H
#define MACROS_H

#include "vbx_types.h"

extern vbx_lve_t the_lve;
#define MOD_NONE 0
#define MOD_ACC 1

#define max(a,b) ((a)<(b) ?(b):(a))
#define min(a,b) ((a)>(b) ?(b):(a))
#define riscv_vector_asm_(vinstr,src_t,op_sz,dim,acc,sign,sync,vlen,dest,srca,srcb) \
	do{ \
		asm( "vtype."#op_sz sync " %0, %1\n\t" \
		     #vinstr"."#src_t"."#dim"d."#sign acc " %2,%3" ::,"r"(vlen):"memory"); \
	}while(0)
#define riscv_vector_asm(vinstr,src_t,op_sz,dim,acc,sign,sync,vlen,dest,srca,srcb) \
	riscv_vector_asm_(vinstr,src_t,op_sz,dim,acc,sign,sync,vlen,dest,srca,srcb) \

#define vbxasm_(acc,vmode, vinstr,dest,srca,srcb)	  \
	asm(#vinstr "." #vmode acc " %2, %0, %1\n":: "r"(srca),"r"(srcb),"r"(dest))



#define vbxasm(modify,...)    do{\
		if(modify == MOD_ACC){\
			vbxasm_(".acc",__VA_ARGS__); \
		}else{\
			vbxasm_("",__VA_ARGS__); \
		}}while(0)

static inline void vbx_set_vl(unsigned vl){
	the_lve.vl = vl;
}
static inline int vbx_get_vl(){
	return the_lve.stride_and_vl;
}

static inline void* vbx_sp_alloc(unsigned sz){
	char* retval=the_lve.sp_ptr;
	the_lve.sp_ptr += (sz+3) & (~0x3); //Align to words since LVE doesn't support arbitary alignments
	return (void*)retval;
}

static inline void vbx_sp_free(){
	the_lve.sp_ptr= the_lve.sp_base;
}
#endif //MACROS_H
