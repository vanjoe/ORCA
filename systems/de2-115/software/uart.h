#ifndef __UART_H
#define __UART_H

#include "bsp.h"

#define UART_PUTC(c) do{*((volatile char*)UART_BASE) = (c);}while(0)
#define UART_BUSY() ((UART_BASE[1]&0xFFFF0000) == 0)

static inline void mputc(void* p, char c){
	while(UART_BUSY());
	UART_PUTC(c);
}

#endif //#ifndef __UART_H
