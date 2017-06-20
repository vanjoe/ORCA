#include "printf.h"
#include "spi.h"
#include "flash.h"
#include "arrow_zl380tw.h"
#include "arrow_zl380tw_firmware.h"
#include "arrow_zl380tw_config.h"
#include "main.h"

#define SIMULATION 0
#define IRAM_TEST 1
#define SPAD_TEST 1
#define SPI_TEST 1
#define I2S_TEST 1
#define FLASH_TEST 1
#define UART_TEST 1
#define MXP_TEST 1

static int array[8] = {'0', '1', '2', '3', '4', '5', '6', '7'};


//////////////////////
//
// UART stuff
//////////////////////
#define UART_BASE  ((volatile int*) (0x30000000))
#define UART_DATA UART_BASE
#define UART_LSR   ((volatile int*) (0x30000010))

//#define UART_INIT() do{*UART_LCR = UART_LCR_8BIT_DEFAULT;}while(0)
#define UART_PUTC(c) do{*UART_DATA = (c);}while(0)
#define UART_BUSY() (!((*UART_LSR) & 0x01))
void mputc (void* p, char c)
{
//  delayms(1);
	while(UART_BUSY());
	*UART_DATA = c;
}

#define DRAM1 ((volatile int*) (0x10000100))
#define DRAM2 ((volatile int*) (0x10000200))
#define I2S           ((volatile int*) (0x50000000))
#define I2S_VERSION   ((volatile int*) (0x50000000))
#define I2S_CLOCK_DIV ((volatile int*) (0x50000004))
#define I2S_DATA      ((volatile int*) (0x50000008))
#define SPEAKER           ((volatile int*) (0x70000000))
#define SPEAKER_VERSION   ((volatile int*) (0x70000000))
#define SPEAKER_CLOCK_DIV ((volatile int*) (0x70000004))
#define SPEAKER_DATA      ((volatile int*) (0x70000008))

int main(void)
{
  volatile register uint32_t test asm ("a5");
  volatile int *address1 = DRAM1;
  volatile int *address2 = DRAM2;
  volatile int *flash_data;
  volatile int temp; 
  int i;

#if SIMULATION
  *SPEAKER_DATA = *I2S_DATA;
#endif

  // Test DPRAM and printf
  init_printf(0, mputc);
//  printf("Hello World\r\n");

#if FLASH_TEST
  flash_data = FLASH_ENDRAM;
  for(i = 0; i < 100; i++) {
    asm volatile("mv %0,sp" :"=r"(temp) :); 
    printf("sp : %0x ", temp);
    printf("%0x : ", (int)flash_data);
    temp = *(flash_data++);
    printf("%0x\r\n", temp);
  }

  volatile int data[128];
  for(i = 0; i < 128; i++) {
    data[i] = i;
  }
  data[77] = 0xDEADBEEF;
  for(i = 0; i < 128; i++) {
    printf(".data test: %0x : %0x\r\n", i, data[i]);
  }

#endif

// Test SPI
#if SPI_TEST
  uint16_t read_data[1];
  uint16_t write_data[1];

  // Chip takes 3 ms to boot after reset.
  delayms(3);
  // Initialize the chip with firmware and config. 
  zl380tw_init();
  zl380tw_configure_codec(ZL380TW_STEREO_BYPASS);
  zl380tw_hbi_mwords_rd(0x2B0, read_data, 1);
  printf("Microphones before: %0x\r\n", read_data[0]);
  write_data[0] = 0x0003;
  zl380tw_hbi_mwords_wr(0x2B0, write_data, 1);  

  zl380tw_reset(VPROC_RST_SOFTWARE);
  zl380tw_hbi_mwords_rd(0x2B0, read_data, 1);
  printf("Microphones after: %0x\r\n", read_data[0]);

  zl380tw_hbi_mwords_rd(ZL380TW_PRODUCT_CODE_REG, read_data, 1);
  printf("PRODUCT CODE: %0x\r\n", read_data[0]);

#endif

#if I2S_TEST
#define SAMPLE_RATE 8000
#define TONE_FREQ 600
#define MAX_VOLUME 0x7FF0
#define SECTION_LENGTH (SAMPLE_RATE/TONE_FREQ/2)

// Test I2S - Triangular Wave (test to see if bits are being dropped)
  int j, k;
  int16_t max_volume = 0x7FF0;
  int16_t volume_step = max_volume / SECTION_LENGTH * 2;
  int16_t volume;

//  printf("Initial volume: %0x\r\n", volume);
//  printf("Max volume: %0x\r\n", max_volume);
//  printf("Section length : %0x\r\n", SECTION_LENGTH);
//  volume_step = max_volume / SECTION_LENGTH;
//  printf("Volume step: %0x\r\n", volume_step);
//  volume_step = volume_step * 2;
//  printf("Volume step: %0x\r\n", volume_step);

  printf("Microphone Direct to Speaker\r\n");
  for (k = 0; k < 8000; k++) {
    *SPEAKER_DATA = *I2S_DATA;
  }

  int sample_count;
  printf("I2S Test\r\n");
  k = 0;
  do {
    volume = -max_volume;
    printf("Triangle Wave\r\n");
    for (j = 0; j < 20000; j += sample_count)  {
      sample_count = 0;
      for (i = 0; i < SECTION_LENGTH; i++) {
        *SPEAKER_DATA = volume>>4;
        if (j == 0) {
          printf("volume_1 = %0x\r\n", volume);
        }
        sample_count++;
        volume += volume_step;
      }
      for (i = 0; i < SECTION_LENGTH; i++) {
        *SPEAKER_DATA = volume>>4;
        if (j == 0) {
          printf("volume_2 = %0x\r\n", volume);
        }
        sample_count++;
        volume -= volume_step;
      }
    }
    // Square Wave
    printf("Square Wave\r\n");
    for (j = 0; j < 20000; j += sample_count) {
      volume = 0x3000;
      for (i = 0; i < SECTION_LENGTH; i++) {
        *SPEAKER_DATA = volume>>4;
      }
      volume = ~volume + 1;
      for (i = 0; i < SECTION_LENGTH; i++) {
        *SPEAKER_DATA = volume>>4;
      }
    }
    k++;
  } while(k < 2);

#endif

#if IRAM_TEST 
// Test IRAM reads
  for (i = 0; i < 8; i++) {
    UART_PUTC((char)array[i]);
  }
  UART_PUTC('\r');
  UART_PUTC('\n');
  delayms(1000);
#endif

#if UART_TEST
// Test UART
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

#if SPAD_TEST
// Test data mem and LEDs 
  *address1 = 'A';
  *address2 = 'B';

  address1 = DRAM1;
  while(1) {
    *address1+=1;
    *address2+=1;
    test = *address1;
    asm volatile("csrw mtohost,%0"
      :
      :"r" (test));
    UART_PUTC((char)(*address1));
    delayms(1000);
    
    test = *address2;
    asm volatile("csrw mtohost,%0"
      :
      :"r" (test));
    UART_PUTC((char)(*address2));
    delayms(1000);
  }
#endif

  return 1;
}


int handle_trap(long cause,long epc, long regs[32])
{
	//spin forever
	for(;;);
}
