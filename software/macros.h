#ifndef MACROS_H
#define MACROS_H

#include <stdint.h>

typedef uint32_t vbx_uword_t; ///< 4-byte word, unsigned
typedef uint16_t vbx_uhalf_t; ///< 2-byte half, unsigned
typedef uint8_t vbx_ubyte_t;  ///< byte, unsigned
typedef int32_t vbx_word_t;   ///< 4-byte word
typedef int16_t vbx_half_t;   ///< 2-byte half
typedef int8_t vbx_byte_t;    ///< byte
typedef void vbx_void_t;      ///< void, used for generic pointers
typedef struct{} vbx_enum_t; ///< Enumerated type, used for type checking c/cpp
static vbx_enum_t vbx_ENUM __attribute__((unused));
//

typedef
enum {
	VMOV,  ///< Moves src operand to dst
	VAND,  ///< Bitwise AND of two src operands
	VOR,   ///< Bitwise OR of two src operands
	VXOR,  ///< Bitwise XOR of two src operands
	VADD,  ///< Adds the two src operands, carry flag generated
	VSUB,  ///< Subtracts the two src operands, borrow flag generated
	VADDC, ///< Adds the two src operands, performs
	VSUBB, ///< Subtracts the two src operands, performs
	VMUL,  ///< Multiplies the two src operands, saves lower result to dst
	VMULLO=VMUL, ///< Multiplies the two src operands, saves lower result to dst
	VMULHI, ///< Multiplies the two src operands, saves upper result to dst
	VMULFXP,///< Fix-point multiply, where the number of fractional bits is set at compile time
	VSHL,  ///< Shifts src operand to left by given amount
	VSHR,  ///< Shifts src operand to right by given amount
	VROTL, ///< Rotates src operand to left by given amount
	VROTR, ///< Rotates src operand to right by given amount
	VCMV_LEZ, ///< Moves src operand to dst if <= 0
	VCMV_GTZ, ///< Moves src operand to dst if >  0
	VCMV_LTZ, ///< Moves src operand to dst if < 0
	VCMV_FS=VCMV_LTZ,
	VCMV_GEZ, ///< Moves src operand to dst if >= 0
	VCMV_FC=VCMV_GEZ,
	VCMV_Z, ///< Moves src operand to dst if == 0
	VCMV_NZ, ///< Moves src operand to dst if != 0
	VABSDIFF, ///< Calculates the absolute difference between the two src operands
	VSLTU,
	VSLT,
	VSRA,
	VSRL,
	VSLL,
	VMULH,
	VCUSTOM0, ///<
	VCUSTOM=VCUSTOM0, ///<
	VCUSTOM1, ///<
	VCUSTOM2, ///<
	VCUSTOM3, ///<
	VCUSTOM4, ///<
	VCUSTOM5, ///<
	VCUSTOM6, ///<
	VCUSTOM7, ///<
	VCUSTOM8, ///<
	VCUSTOM9, ///<
	VCUSTOM10, ///<
	VCUSTOM11, ///<
	VCUSTOM12, ///<
	VCUSTOM13, ///<
	VCUSTOM14, ///<
	VCUSTOM15, ///<

	MAX_INSTR_VAL=VCUSTOM15
} vinstr_t;


/** MXP processor state*/
/* most things are removed to save size, because they are not used.*/
typedef struct {

	/* Fixed MXP CPU characteristics */
	/* vbx_void_t  *scratchpad_addr; ///< Start address of the scratchpad memory */
	/* vbx_void_t  *scratchpad_end; ///< End address of the scratchpad memory */
	/* vbx_void_t  *instr_port_addr; */
	/* uint32_t    *instr_p; */
	/* int         scratchpad_size; ///< Size of the scratchpad memory */

	/* int         core_freq; ///< MXP processor frequency */
	/* short       dma_alignment_bytes; */
	/* short       scratchpad_alignment_bytes; */
	/* short       vector_lanes; ///< Num of 32-bit vector lanes */
	/* short       vcustom0_lanes; ///<Num of lanes on VCUSTOM0 */
	/* short       vcustom1_lanes; ///<Num of lanes on VCUSTOM1 */
	/* short       vcustom2_lanes; ///<Num of lanes on VCUSTOM2 */
	/* short       vcustom3_lanes; ///<Num of lanes on VCUSTOM3 */
	/* short       vcustom4_lanes; ///<Num of lanes on VCUSTOM4 */
	/* short       vcustom5_lanes; ///<Num of lanes on VCUSTOM5 */
	/* short       vcustom6_lanes; ///<Num of lanes on VCUSTOM6 */
	/* short       vcustom7_lanes; ///<Num of lanes on VCUSTOM7 */
	/* short       vcustom8_lanes; ///<Num of lanes on VCUSTOM8 */
	/* short       vcustom9_lanes; ///<Num of lanes on VCUSTOM9 */
	/* short       vcustom10_lanes; ///<Num of lanes on VCUSTOM10 */
	/* short       vcustom11_lanes; ///<Num of lanes on VCUSTOM11 */
	/* short       vcustom12_lanes; ///<Num of lanes on VCUSTOM12 */
	/* short       vcustom13_lanes; ///<Num of lanes on VCUSTOM13 */
	/* short       vcustom14_lanes; ///<Num of lanes on VCUSTOM14 */
	/* short       vcustom15_lanes; ///<Num of lanes on VCUSTOM15 */
	/* int         max_masked_vector_length; ///<Maximum masked vector length */
	/* short       mask_partitions; ///<Partitioning/granularity of masked instructions */
	/* char        vector_custom_instructions; //Number of VCIs hooked up */
	/* char        fxp_word_frac_bits; ///< Num of fractional bit used with @ref vbx_word_t or @ref vbx_uword_t data types */
	/* char        fxp_half_frac_bits; ///< Num of fractional bit used with @ref vbx_half_t or @ref vbx_uhalf_t data types */
	/* char        fxp_byte_frac_bits; ///< Num of fractional bit used with vbx_byte_t or f vbx_ubyte_t data types */

	int current_vl;

	/* MXP flags */
	char        init;

	/* MXP run-time state */
/* 	vbx_void_t  *sp; ///< Current location of scratchpad pointer */
/* #if VBX_STATIC_ALLOCATE_SP */
/* 	vbx_void_t  *spstack[VBX_STATIC_SP_SIZE]; */
/* #else */
/* 	vbx_void_t  **spstack; */
/* #endif */
/* 	int         spstack_top; */
/* 	int         spstack_max; */


} vbx_mxp_t;

extern vbx_mxp_t the_mxp;


#define riscv_vector_asm_(vinstr,src_t,op_sz,dim,acc,sign,sync,vlen,dest,srca,srcb) \
	do{\
		asm( "vtype."#op_sz sync " %0, %1\n\t"\
		     #vinstr"."#src_t"."#dim"d."#sign acc " %2,%3" ::"r"(srca),"r"(srcb),"r"(dest),"r"(vlen):); \
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
	  vbx_acc_sync_##vmode##_argument_type_checker(vinstr,dest,srca,srcb)\
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


static inline void vbx_set_vl(int vl){
	 the_mxp.current_vl = vl;
}
static inline int vbx_get_vl(){
	return the_mxp.current_vl;
}


#endif //MACROS_H
