#ifndef __UART_H_
#define __UART_H_

//ice40ultraplus UART (bit-banged or RD1042)
#include "bsp.h"
#include <stdbool.h>
#include "orca_utils.h"

#ifndef UART_BASE_ADDRESS
#define BIT_BANG_UART 1
#define DEFAULT_PUTP ((void *)GPIO_BASE_ADDRESS)
#else //#ifndef UART_BASE_ADDRESS
#define BIT_BANG_UART 0
#define DEFAULT_PUTP ((void *)UART_BASE_ADDRESS)
#endif //#else //#ifndef UART_BASE_ADDRESS


void mputc(void* p, char c);

//Used by printf.c if printf is uninitialized
static inline void default_putf(void *base_address, char data){
	mputc(base_address, data);
}



#endif //def __UART_H_
