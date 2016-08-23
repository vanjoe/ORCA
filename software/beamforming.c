#include "macros.h"
#include "vbx_cproto.h"
#include "interrupt.h"
#include "samples.h"
#include "fir.h"
#include "printf.h"
#include "i2s.h"

//////////////////////
//
// UART stuff
//////////////////////
#define  UART_BASE ((volatile int*) 0x00020000)
volatile int*  UART_DATA=UART_BASE;
volatile int*  UART_LCR=UART_BASE+3;
volatile int*  UART_LSR=UART_BASE+5;

#define UART_LCR_8BIT_DEFAULT 0x03
#define UART_INIT() do{*UART_LCR = UART_LCR_8BIT_DEFAULT;}while(0)
#define UART_PUTC(c) do{*UART_DATA = (c);}while(0)
#define UART_BUSY() (!((*UART_LSR) &0x20))
void mputc ( void* p, char c)
{
        while(UART_BUSY());
        *UART_DATA = c;
}



#include <stdint.h>

#define SYS_CLK 8000000
#define SAMPLE_RATE 7800 // Hz
#define DISTANCE 140U // mm
#define SPEED_OF_SOUND 343e3 // mm/s
#define SAMPLE_DIFFERENCE ((int) (DISTANCE*SAMPLE_RATE/SPEED_OF_SOUND))

#define WINDOW_LENGTH 64
#define NUM_WINDOWS 2
#define BUFFER_LENGTH WINDOW_LENGTH*NUM_WINDOWS

#define PRESCALE 4

#define SCRATCHPAD_BASE ((int32_t *) (0x80000000))

extern int samples_l[NUM_SAMPLES];
extern int samples_r[NUM_SAMPLES];

extern int fir_taps[NUM_TAPS];

#define scratch_write(a) asm volatile ("csrw mscratch, %0"	\
													:							\
													: "r" (a))



int main() {

  UART_INIT();
  init_printf(0,mputc);
  printf("HELLO UART!!\r\n");
  //TODO Use mics properly
  i2s_set_frequency(SYS_CLK,8000);
  int sample_count = 0;

  vbx_word_t *mic_buffer_l = SCRATCHPAD_BASE;
  vbx_word_t *mic_buffer_r = SCRATCHPAD_BASE + BUFFER_LENGTH;
  vbx_word_t *sound_vector_l = mic_buffer_r + BUFFER_LENGTH;
  vbx_word_t *sound_vector_r = sound_vector_l + WINDOW_LENGTH + SAMPLE_DIFFERENCE;
  vbx_word_t *sum_vector = sound_vector_r + WINDOW_LENGTH + SAMPLE_DIFFERENCE;
  vbx_word_t *fir_vector = sum_vector + WINDOW_LENGTH;
  vbx_word_t *temp_l = fir_vector + NUM_TAPS;
  vbx_word_t *temp_r = temp_l + BUFFER_LENGTH;

  int32_t i, j;
  int32_t buffer_count = 0;
  int32_t *power_center = temp_r + BUFFER_LENGTH;
  int32_t *power_left = power_center + 1;
  int32_t *power_right = power_left + 1;
  int32_t *fir_acc_l = power_right + 1;
  int32_t *fir_acc_r = fir_acc_l + 1;
  int32_t transfer_offset;

  vbx_set_vl(BUFFER_LENGTH);
  vbx(SEWS, VAND, mic_buffer_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, mic_buffer_r, 0, vbx_ENUM);
  vbx(SEWS, VAND, temp_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, temp_r, 0, vbx_ENUM);
  vbx_set_vl(WINDOW_LENGTH + SAMPLE_DIFFERENCE);
  vbx(SEWS, VAND, sound_vector_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, sound_vector_r, 0, vbx_ENUM);

  // Initialize FIR vector.
  for (i = 0; i < NUM_TAPS; i++) {
    fir_vector[i] = fir_taps[i];
  }

#define output_vec_sum(vec_name,length) do{				\
  int i,total=0;													\
  for(i=0;i<length;i++) {										\
	 total+=(vec_name)[i];					\
  }scratch_write(total); } while(0)

  printf("entering loop\r\n");
  int k=0;

  #include "fragment.c"

  return 0;
}

int handle_interrupt(long cause, long epc, long regs[32]) {
  for(;;);
  return 0;
}
