#ifndef MACROS_H
#define MACROS_H

#include "vbx_types.h"

extern vbx_lve_t the_lve;
#define MOD_NONE 0
#define MOD_ACC 1

#define max(a,b) ((a)<(b) ?(b):(a))
#define min(a,b) ((a)>(b) ?(b):(a))

#define vbxasm_(acc,vmode, vinstr,dest,srca,srcb)	  \
	asm volatile(#vinstr "." #vmode acc " %0, %1, %2\n":: "r"(dest),"r"(srca),"r"(srcb))



#define vbxasm(modify,...)    do{\
		if(modify == MOD_ACC){\
			vbxasm_(".acc",__VA_ARGS__); \
		}else{\
			vbxasm_("",__VA_ARGS__); \
		}}while(0)

static inline void vbx_set_vl(unsigned vl,unsigned nrows){
	asm volatile("vbx_set_vl %0, %1, %2"::"r"(vl),"r"(nrows),"r"(1));
}
static inline void vbx_set_2D(int incrd,int incra,int incrb){
	asm volatile("vbx_set_2d %0, %1, %2"::"r"(incrd),"r"(incra),"r"(incrb));
}

#define vbx_set_vl_1(vl) vbx_set_vl(vl,1)
#define vbx_set_vl_2(vl,rows) vbx_set_vl(vl,rows)

#define vbx_set_vl_X(x,A,B,FUNC, ...)  FUNC
#define vbx_set_vl(...) vbx_set_vl_X(,##__VA_ARGS__,      \
                                     vbx_set_vl_2(__VA_ARGS__),\
                                     vbx_set_vl_1(__VA_ARGS__))


typedef enum{
	VBX_STATE_VECTOR_LENGTH=0,
	VBX_STATE_NROWS=1,
	VBX_STATE_INCRD_2D=2,
	VBX_STATE_INCRA_2D=3,
	VBX_STATE_INCRB_2D=4,
	VBX_STATE_NMATS=5,
	VBX_STATE_INCRD_3D=6,
	VBX_STATE_INCRA_3D=7,
	VBX_STATE_INCRB_3D=8
}state_e;
static inline vbx_uword_t vbx_get_state(state_e reg){
	vbx_uword_t ret;
	asm volatile("vbx_get %0, %1":"=r"(ret):"r"(reg));
	return ret;
}

static inline void vbx_sync(){
	asm volatile("vbx_get x0, x0");
}

static inline void vbx_get_vl(unsigned* vl,unsigned *nrows){
	*vl=vbx_get_state(VBX_STATE_VECTOR_LENGTH);
	*nrows=vbx_get_state(VBX_STATE_NROWS);
}
static inline void vbx_get_2D(int *incrd,int* incra,int* incrb){
	*incra=vbx_get_state(VBX_STATE_INCRA_2D);
	*incrb=vbx_get_state(VBX_STATE_INCRB_2D);
	*incrd=vbx_get_state(VBX_STATE_INCRD_2D);
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
