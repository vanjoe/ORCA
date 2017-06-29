#include "printf.h"
#include "flash.h"
#include "main.h"

#define SIMULATION 0
#define IRAM_TEST 0
#define SPAD_TEST 0
#define SPI_TEST 0
#define I2S_TEST 0
#define FLASH_TEST 0
#define UART_TEST 0
#define MXP_TEST 1

#define UART_BASE  ((volatile int*) (0x30000000))
#define UART_DATA UART_BASE
#define UART_LSR   ((volatile int*) (0x30000010))

#define UART_PUTC(c) do{*UART_DATA = (c);}while(0)
#define UART_BUSY() (!((*UART_LSR) & 0x01))
void mputc (void* p, char c)
{
#if SIMULATION
  asm volatile("csrw mscratch, %0" : : "r" (c));
#else
  delayms(1);
	while(UART_BUSY());
	*UART_DATA = c;
#endif
}


int main(void) {
  init_printf(0, mputc);

#if UART_TEST
  int val;
  val = 0xDEADBEEF;
  printf("\r\n%x = DEADBEEF\r\n", val);
  printf("Hello World\r\n");

  char c;
  for (c = 'A'; c <= 'z'; c++) {
    UART_PUTC(c);
    delayms(100);
  }
#endif

#if MXP_TEST
  printf("\r\n\n\n----MXP TEST----\r\n\n\n");
  int errors = mxp_test();
  printf("MXP errors: %d\r\n", errors);
  printf("\r\n\n\n----END MXP TEST----\r\n\n\n");
#endif

  return 1;
}


int handle_trap(long cause,long epc, long regs[32])
{
	//spin forever
	for(;;);
}
