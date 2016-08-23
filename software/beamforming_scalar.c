#include <stdint.h>

#include "i2s.h"
#include "interrupt.h"
#include "samples.h"
#include "printf.h"
#include "fir.h"

#define SYS_CLK 8000000 
#define SAMPLE_RATE 7800 // Hz
#define DISTANCE 140U // mm
#define SPEED_OF_SOUND 343e3 // mm/s
#define SAMPLE_DIFFERENCE ((int) (DISTANCE*SAMPLE_RATE/SPEED_OF_SOUND))

#define WINDOW_LENGTH 64 
#define NUM_WINDOWS 2
#define BUFFER_LENGTH WINDOW_LENGTH*NUM_WINDOWS 
#define STARTUP_BUFFER 64*1024/2

#define DEBUG 1

#define scratch_write(a) asm volatile ("csrw mscratch, %0"	\
													:							\
													: "r" (a))

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

static inline unsigned get_time() {
  int tmp;       
  asm volatile("csrr %0, time"
    : "=r" (tmp) 
    : );
  return tmp;
}

#if DEBUG
extern int samples_l[NUM_SAMPLES]; 
extern int samples_r[NUM_SAMPLES];
#endif

int main() {

  volatile int32_t mic_buffer_l[BUFFER_LENGTH];
  volatile int32_t mic_buffer_r[BUFFER_LENGTH];
  volatile int32_t temp_l[BUFFER_LENGTH];
  volatile int32_t temp_r[BUFFER_LENGTH];
  int32_t temp;

#if DEBUG
  int sample_count = 0;
#endif

  int i, j;
  int index_l;
  int index_r;
  int buffer_count = 0;

  i2s_data_t mic_data;
  
  volatile int64_t power_front;
  volatile int64_t power_left;
  volatile int64_t power_right;
  volatile int64_t fir_acc_l;
  volatile int64_t fir_acc_r;



#if !DEBUG
  UART_INIT();
  init_printf(0, mputc);
  printf("Hello World\r\n");
  i2s_set_frequency(SYS_CLK, 8000);

  for (i = 0; i < STARTUP_BUFFER; i++) {
    mic_data = i2s_get_data();
    printf("%x %x\r\n", mic_data.left, mic_data.right);
  }
#endif

  for (i = 0; i < BUFFER_LENGTH; i++) {
    mic_buffer_l[i] = 0;
    mic_buffer_r[i] = 0;
    temp_l[i] = 0;
    temp_r[i] = 0;
  }
  buffer_count = 0;

  while(1) {
    unsigned int time;

    scratch_write(0xFFFF);
    time = get_time();

    // Collect WINDOW_LENGTH samples.
    for (i = 0; i < WINDOW_LENGTH; i++) {
      for (j = 0; j < BUFFER_LENGTH-1; j++) {
        temp_l[j] = temp_l[j+1];
        temp_r[j] = temp_r[j+1]; 
      }

#if DEBUG      
      temp_l[BUFFER_LENGTH-1] = samples_l[sample_count];
      temp_r[BUFFER_LENGTH-1] = samples_r[sample_count];
      sample_count++;
      if (sample_count >= NUM_SAMPLES) {
        sample_count = 0;
      }
#else
      mic_data = i2s_get_data();
      temp_l[BUFFER_LENGTH-1] = (int32_t)mic_data.left;
      temp_r[BUFFER_LENGTH-1] = (int32_t)mic_data.right;
#endif

      // Apply the FIR filter.
      fir_acc_l = 0;
      fir_acc_r = 0;
      for (j = 0; j < NUM_TAPS; j++) {
        fir_acc_l += temp_l[BUFFER_LENGTH-NUM_TAPS+j] * fir_taps[j];
        fir_acc_r += temp_r[BUFFER_LENGTH-NUM_TAPS+j] * fir_taps[j];

      }

      mic_buffer_l[buffer_count] = fir_acc_l >> 16;
      mic_buffer_r[buffer_count] = fir_acc_r >> 16;


      buffer_count++;
      if (buffer_count == BUFFER_LENGTH) {
        buffer_count = 0; 
      }

    }

    time = get_time() - time;
    scratch_write(time);

    scratch_write(0xFFFF);
    time = get_time();

    // Calculate the power assuming the sound is coming from the front.
    index_l = buffer_count - WINDOW_LENGTH;
    index_r = buffer_count - WINDOW_LENGTH;
    if (index_l < 0) {
      index_l += BUFFER_LENGTH;
    }
    if (index_r < 0) {
      index_r += BUFFER_LENGTH;
    }

    power_front = 0;
    for (i = 0; i < WINDOW_LENGTH; i++) {
      temp = mic_buffer_l[index_l] + mic_buffer_r[index_r];
      power_front += temp * temp; 


      index_l++;
      index_r++;
      if (index_l == BUFFER_LENGTH) {
        index_l = 0;
      }
      if (index_r == BUFFER_LENGTH) {
        index_r = 0;
      }
    }
    
    // Calculate the power assuming the sound is coming from the left (right microphone is 
    // delayed during sampling, delay left microphone to compensate).
    index_l = buffer_count - WINDOW_LENGTH - SAMPLE_DIFFERENCE;
    index_r = buffer_count - WINDOW_LENGTH;
    if (index_l < 0) {
      index_l += BUFFER_LENGTH;
    }
    if (index_r < 0) {
      index_r += BUFFER_LENGTH;
    }
    
    power_left = 0;
    for (i = 0; i < WINDOW_LENGTH; i++) {
      temp = mic_buffer_l[index_l] + mic_buffer_r[index_r];
      power_left += temp * temp;


      index_l++;
      index_r++;
      if (index_l == BUFFER_LENGTH) {
        index_l = 0;
      }
      if (index_r == BUFFER_LENGTH) {
        index_r = 0;
      }
    }
    
    // Calculate the power assuming the sound is coming from the right (left microphone is 
    // delayed during sampling, delay right microphone to compensate).
    index_l = buffer_count - WINDOW_LENGTH;
    index_r = buffer_count - WINDOW_LENGTH - SAMPLE_DIFFERENCE;
    if (index_l < 0) {
      index_l += BUFFER_LENGTH;
    }
    if (index_r < 0) {
      index_r += BUFFER_LENGTH;
    }

    power_right = 0;
    for (i = 0; i < WINDOW_LENGTH; i++) {
      temp = mic_buffer_l[index_l] + mic_buffer_r[index_r];
      power_right += temp * temp;


      index_l++;
      index_r++;
      if (index_l == BUFFER_LENGTH) {
        index_l = 0;
      }
      if (index_r == BUFFER_LENGTH) {
        index_r = 0;
      }
    }

    scratch_write(get_time() - time);
    scratch_write(0xFFFF);

#if DEBUG
    asm volatile("csrw mscratch, %0\n csrw mscratch, %1\n csrw mscratch, %2"
      :
      : "r" (power_front), "r" (power_left), "r" (power_right));
#endif

#if DEBUG
    if (power_front > power_left) {
      if (power_front > power_right) {
        asm volatile("csrw mscratch, 0"
          :
          : );
      }
      else {
        asm volatile("csrw mscratch, 2"
          :
          : );
      }
    }
    else {
      if (power_left > power_right) {
        asm volatile("csrw mscratch, 1"
          :
          : );
      }
      else {
        asm volatile("csrw mscratch, 2"
          :
          : );
      }
    }

#else
    if (power_front > power_left) {
      if (power_front > power_right) {
        printf("Front\r\n");
      }
      else {
        printf("Right\r\n");
      }
    }
    else {
      if (power_left > power_right) {
        printf("Left\r\n");
      }
      else {
        printf("Right\r\n");
      }
    }
#endif

  }

}

int handle_interrupt(long cause, long epc, long regs[32]) {
  for(;;);
}
