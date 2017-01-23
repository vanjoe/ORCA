#include "uart.h"
#include "system.h"
//////////////////////
//
// UART stuff
//////////////////////
#define  UART_BASE ((volatile int*) UART_ADDR)

volatile int*  UART_DATA=UART_BASE;
volatile int*  UART_LCR=UART_BASE+3;
volatile int*  UART_LSR=UART_BASE+5;

#define UART_LCR_8BIT_DEFAULT 0x03
#define UART_INIT() do{*UART_LCR = UART_LCR_8BIT_DEFAULT;}while(0)
#define UART_PUTC(c) do{*UART_DATA = (c);}while(0)
#define UART_BUSY() (!((*UART_LSR) &0x20))

void mputc(void* p, char c){
	int uninitialized = 1;
	if(uninitialized){
		UART_INIT();
		uninitialized = 0;
	}
	while(UART_BUSY());
	*UART_DATA = c;
}
