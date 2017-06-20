#include "uart.h"
#include "system.h"
//////////////////////
//
// UART stuff
//////////////////////
#define  UART_BASE ((volatile int*) UART_ADDR)

static volatile int* const UART_DATA=UART_BASE;
static volatile int* const UART_LCR =UART_BASE+3;
static volatile int* const UART_LSR =UART_BASE+5;

#define UART_LCR_8BIT_DEFAULT 0x03
#define UART_INIT() do{*UART_LCR = UART_LCR_8BIT_DEFAULT;}while(0)
#define UART_PUTC(c) do{*UART_DATA = (c);}while(0)
#define UART_BUSY() (!((*UART_LSR) &0x20))

//this function is put in the .init section
//so that the boot loader can make use of it.
void  mputc(void* p, char c){

	UART_INIT();
	while(UART_BUSY());
	*UART_DATA = c;
}
