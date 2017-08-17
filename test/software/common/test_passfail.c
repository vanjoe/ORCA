#include "test_passfail.h"
#include "printf.h"
#include "uart.h"

#define ALTERA 0
#define XILINX 0
#define MICROSEMI 0
#define LATTICE 0

// UART I/O is family specific.
// Edit the family above in to reflect the family
// being tested.

#if ALTERA
#define SYS_CLK 50000000 // Hz
volatile int *uart = (volatile int*) 0x01000070;
#define UART_INIT() ((void)0)
#define UART_PUTC(c) do {*((char*)uart) = (c);} while(0)
#define UART_BUSY() ((uart[1]&0xFFFF0000) == 0)
#define orca_printf printf
#endif

#if XILINX
#define SYS_CLK 25000000 // Hz
#define UART_INIT() ((void)0)
#define UART_PUTC(c) do {print_char(c);} while(0) 
#define UART_BUSY() 0 
#define orca_printf ChangedPrint

#endif

#if MICROSEMI
#endif

#if LATTICE
#endif

static inline unsigned get_time() {
	int tmp;
	asm volatile("csrr %0, time":"=r"(tmp));
	return tmp;
}

static void delayus(int us) {
	unsigned start = get_time();
	us *= (SYS_CLK/1000000); // Cycles per us
	while(get_time()-start < us);
}

void mputc(void *p, char c) {
	while(UART_BUSY());
	UART_PUTC(c);
}

void test_pass(void) {
	init_printf(0, mputc);
	while (1) {
		orca_printf("\r\nTest passed!\r\n");
		mputc(0, 4);
		delayus(1E6);
	}
}

void test_fail(void) {
	init_printf(0, mputc);
	while (1) {
		// The risc-v tests fail immediately once an
		// error has occured, so there will never be
		// more than one error at a time.
		orca_printf("\r\nTest failed with 1 error.\r\n");	
		mputc(0, 4);
		delayus(1E6);
	}
}
