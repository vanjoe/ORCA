#ifndef __BSP_H
#define __BSP_H

#include "sys_clk.h"

#define IMEM_BASE_ADDRESS           0x00000000
#define IMEM_SPAN                   0x00002000

#define DMEM_BASE_ADDRESS           0x00000000
#define DMEM_SPAN                   0x00000800

#define SPI_BASE_ADDRESS            0x02000000
#define LVE_SCRATCHPAD_BASE_ADDRESS 0x04000000
#define GPIO_BASE_ADDRESS           0x06000000

#define ORCA_ENABLE_EXCEPTIONS     0
#define ORCA_ENABLE_EXT_INTERRUPTS 0
#define ORCA_NUM_EXT_INTERRUPTS    1

#endif //#ifndef __BSP_H
