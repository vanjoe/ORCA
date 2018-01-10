#ifndef __BSP_H
#define __BSP_H

#include <stdint.h>

#define ORCA_CLK 100000000

#define GPIO_DATA ((volatile uint32_t*)0x00010000)
#define LEDR      ((volatile uint32_t*)0x01000010)
#define LEDG      ((volatile uint32_t*)0x01000020)
#define HEX0      ((volatile uint32_t*)0x01000030)
#define HEX1      ((volatile uint32_t*)0x01000040)
#define HEX2      ((volatile uint32_t*)0x01000050)
#define HEX3      ((volatile uint32_t*)0x01000060)
#define UART_BASE ((volatile uint32_t*)0x01000070)
#define MIC_READY ((volatile uint32_t*)0x01000100)
#define MIC_DATA  ((volatile uint32_t*)0x01000108)

#endif //#ifndef __BSP_H
