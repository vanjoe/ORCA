#include "uart.h"
#define BIT_BANG_UART 1

#if BIT_BANG_UART

#define UART_BIT (1<<5)
#define UART_DELAY_CYCLES (SYS_CLK/115200)

#include "time.h"
#include "sccb.h"

void mputc(void* p, char c){
	volatile uint32_t *pioRegister = (volatile uint32_t *)SCCB_PIO_BASE;
	uint32_t old_pio = *pioRegister;
	uint32_t uart_low = old_pio | UART_BIT; //Inverted; set bit for low
	uint32_t uart_high = old_pio & (~UART_BIT); //Inverted; clear bit for high

	unsigned end_time = get_time() + UART_DELAY_CYCLES;
	*pioRegister = uart_low;
	int bit;
	for(bit = 0; bit < 8; bit++){
		uint32_t next_pio = uart_low;
		if((c >> bit) & 0x1){
			next_pio = uart_high;
		}
		while(get_time() < end_time){
		}
		*pioRegister = next_pio;
		end_time = end_time + UART_DELAY_CYCLES;
	}
	
	while(get_time() < end_time){
	}
	*pioRegister = uart_high;
	end_time = end_time + UART_DELAY_CYCLES;
	while(get_time() < end_time){
	}
}

#else
//////////////////////
//
// UART stuff
//////////////////////
#define  UART_BASE ((volatile int*) 0x08000000)

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
#endif
