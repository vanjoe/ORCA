#ifndef MACROS_H
#define MACROS_H

#include "vbx_types.h"

extern vbx_mxp_t the_mxp;


#define riscv_vector_asm_(vinstr,src_t,op_sz,dim,acc,sign,sync,vlen,dest,srca,srcb) \
	do{ \
		asm( "vtype."#op_sz sync " %0, %1\n\t" \
		     #vinstr"."#src_t"."#dim"d."#sign acc " %2,%3" ::"r"(srca),"r"(srcb),"r"(dest),"r"(vlen):"memory"); \
	}while(0)
#define riscv_vector_asm(vinstr,src_t,op_sz,dim,acc,sign,sync,vlen,dest,srca,srcb) \
	riscv_vector_asm_(vinstr,src_t,op_sz,dim,acc,sign,sync,vlen,dest,srca,srcb) \

#define vbx_(vmode,vinstr,dest,srca,srcb)	  \
	do{ \
		vbx_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
			riscv_vector_asm(vinstr,vmode##_type,vmode##_size,1,"",vmode##_sign,"",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
	}while(0)
#define vbx_acc_(vmode,vinstr,dest,srca,srcb)	  \
	do{ \
		vbx_acc_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
			riscv_vector_asm(vinstr,vmode##_type,vmode##_size,1,".acc",vmode##_sign,"",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
	}while(0)
#define vbx_acc_sync_(vmode,vinstr,dest,srca,srcb)	  \
	do{ \
		vbx_acc_sync_##vmode##_argument_type_checker(vinstr,dest,srca,srcb) \
			riscv_vector_asm(vinstr,vmode##_type,vmode##_size,1,".acc",vmode##_sign,".sync",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
	}while(0)
#define vbx_sync_(vmode,vinstr,dest,srca,srcb)	  \
	do{ \
		vbx_sync_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
			riscv_vector_asm(vinstr,vmode##_type,vmode##_size,1,"",vmode##_sign,".sync",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
	}while(0)
#define vbx_2D_(vmode,vinstr,dest,srca,srcb)	  \
	do{ \
		vbx_2D_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
			riscv_vector_asm(vinstr,vmode##_type,vmode##_size,2,"",vmode##_sign,"",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
	}while(0)
#define vbx_2D_acc_(vmode,vinstr,dest,srca,srcb)	  \
	do{ \
		vbx_2D_acc_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
			riscv_vector_asm(vinstr,vmode##_type,vmode##_size,2,".acc",vmode##_sign,"",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
	}while(0)
#define vbx_2D_acc_sync_(vmode,vinstr,dest,srca,srcb)	  \
	do{ \
		vbx_2D_acc_sync_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
			riscv_vector_asm(vinstr,vmode##_type,vmode##_size,2,".acc",vmode##_sign,".sync",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
	}while(0)
#define vbx_2D_sync_(vmode,vinstr,dest,srca,srcb)	  \
		do{ \
			vbx_2D_sync_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
				riscv_vector_asm(vinstr,vmode##_type,vmode##_size,2,"",vmode##_sign,".sync",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
		}while(0)
#define vbx_3D_(vmode,vinstr,dest,srca,srcb)	  \
		do{ \
			vbx_3D_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
				riscv_vector_asm(vinstr,vmode##_type,vmode##_size,3,"",vmode##_sign,"",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
		}while(0)
#define vbx_3D_acc_(vmode,vinstr,dest,srca,srcb)	  \
		do{ \
			vbx_3D_acc_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
				riscv_vector_asm(vinstr,vmode##_type,vmode##_size,3,".acc",vmode##_sign,"",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
		}while(0)
#define vbx_3D_acc_sync_(vmode,vinstr,dest,srca,srcb)	  \
		do{ \
			vbx_3D_acc_sync_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
				riscv_vector_asm(vinstr,vmode##_type,vmode##_size,3,".acc",vmode##_sign,".sync",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
		}while(0)
#define vbx_3D_sync_(vmode,vinstr,dest,srca,srcb)	  \
		do{ \
			vbx_3D_sync_##vmode##_argument_type_checker(vinstr,dest,srca,srcb); \
				riscv_vector_asm(vinstr,vmode##_type,vmode##_size,3,"",vmode##_sign,".sync",vbx_get_vl(),dest,srca,get_srcb_##vmode(srcb)); \
		}while(0)

#define vbx(...)             vbx_(__VA_ARGS__)
#define vbx_acc(...)         vbx_acc_(__VA_ARGS__)
#define vbx_acc_sync(...)    vbx_acc_sync_(__VA_ARGS__)
#define vbx_sync(...)        vbx_sync_(__VA_ARGS__)
#define vbx_2D(...)          vbx_2D_(__VA_ARGS__)
#define vbx_2D_acc(...)      vbx_2D_acc_(__VA_ARGS__)
#define vbx_2D_acc_sync(...) vbx_2D_acc_sync_(__VA_ARGS__)
#define vbx_2D_sync(...)     vbx_2D_sync_(__VA_ARGS__)
#define vbx_3D(...)          vbx_3D_(__VA_ARGS__)
#define vbx_3D_acc(...)      vbx_3D_acc_(__VA_ARGS__)
#define vbx_3D_acc_sync(...) vbx_3D_acc_sync_(__VA_ARGS__)
#define vbx_3D_sync(...)     vbx_3D_sync_(__VA_ARGS__)

static inline void vbx_set_vl(unsigned vl){
	the_mxp.vl = vl;
}
static inline int vbx_get_vl(){
	return the_mxp.stride_and_vl;
}

static inline void* vbx_sp_alloc(unsigned sz){
	char* retval=the_mxp.sp_ptr;
	the_mxp.sp_ptr+=sz;
	return (void*)retval;
}

static inline void vbx_sp_free(){
	the_mxp.sp_ptr= the_mxp.sp_base;
}
#endif //MACROS_H
