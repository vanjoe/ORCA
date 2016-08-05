#ifndef INTERRUPT_H
#define INTERRUPT_H

#define MTIMECMP_L       ((volatile int*) 0x00000000)
#define MTIMECMP_H       ((volatile int*) 0x00000004)
#define MSOFTWARE_I      ((volatile int*) 0x00000008)
#define EDGE_SENS_VECTOR ((volatile int*) 0x0000000C)
#define INTRPT_CLAIM     ((volatile int*) 0x00000010)
#define INTRPT_COMPLETE  ((volatile int*) 0x00000014)

#define MSTATUS_IE_MASK 0x00000008
#define MIE_MEIE_MASK   0x00000800
#define MIE_MTIE_MASK   0x00000080
#define MIE_MSIE_MASK   0x00000008

#define M_SOFTWARE_INTERRUPT 0x3
#define M_TIMER_INTERRUPT    0x7
#define M_EXTERNAL_INTERRUPT 0xB

inline void enable_interrupts(void) {
  asm volatile("csrs mstatus,%0"
    :
    : "r" ((int) MSTATUS_IE_MASK)); 
}

inline void disable_interrupts(void) {
  asm volatile("csrc mstatus,%0"
    :
    : "r" ((int) MSTATUS_IE_MASK)); 
}

inline void enable_external_interrupts(void) {
  asm volatile("csrs mie,%0"
    :
    : "r" ((int) (MIE_MEIE_MASK)));
}

inline void disable_external_interrupts(void) {
  asm volatile("csrc mie,%0"
    :
    : "r" ((int) (MIE_MEIE_MASK)));
}

inline void enable_software_interrupts(void) {
  asm volatile("csrs mie,%0"
    :
    : "r" ((int) (MIE_MSIE_MASK)));
}

inline void disable_software_interrupts(void) {
  asm volatile("csrc mie,%0"
    :
    : "r" ((int) (MIE_MSIE_MASK)));
}

inline void enable_timer_interrupts(void) {
  asm volatile("csrs mie,%0"
    :
    : "r" ((int) (MIE_MTIE_MASK)));
}

inline void disable_timer_interrupts(void) {
  asm volatile("csrc mie,%0"
    :
    : "r" ((int) (MIE_MTIE_MASK)));
}

inline void trigger_software_interrupt(void) {
  asm volatile("sw %0,0(%1)"
    :
    : "r" ((int) 0x1), "r" (MSOFTWARE_I));
}

inline void clear_software_interrupt(void) {
  asm volatile("lw t0,0(%0)"
    :
    : "r" (MSOFTWARE_I)); 
}

inline void claim_external_interrupt(int *plic_claim_address) {
  *plic_claim_address = *INTRPT_CLAIM;
}

inline void complete_external_interrupt(int plic_claim) {
  *INTRPT_COMPLETE = plic_claim;
}

long handle_trap(long cause, long epc, long regs[32]);
void set_timer_interrupt_cycles(int cycles);  
void clear_timer_interrupt_cycles(void);  

#endif
