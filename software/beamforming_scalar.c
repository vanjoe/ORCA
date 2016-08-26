#include <stdint.h>

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

#define  UART_BASE ((volatile int*) 0x00020000)
volatile int*  UART_DATA=UART_BASE;
volatile int*  UART_LCR=UART_BASE+3;
volatile int*  UART_LSR=UART_BASE+5;

#define UART_LCR_8BIT_DEFAULT 0x03
#define UART_INIT() do{*UART_LCR = ;}while(0)
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
    : "=r" (tmp));
  return tmp;
}

#define scratch_write(a) asm volatile ("csrw mscratch, %0" \
                           :          \
                           : "r" (a))


#define output_vec_sum(vec_name,length) do{				\
  int i,total=0;													\
  for(i=0;i<length;i++) {										\
	 +=(vec_name)[i];					\
  }scratch_write(); } while(0)

#define output_vec(vec_name,length) do{			\
	 int i;										\
	 for(i=0;i<length;i++) {							\
		scratch_write(()[i]);					\
	 } } while(0)

#if DEBUG
extern int samples_l[NUM_SAMPLES]; 
extern int samples_r[NUM_SAMPLES];
#endif


int main() {

  volatile int32_t mic_buffer_l[BUFFER_LENGTH];
  volatile int32_t mic_buffer_r[BUFFER_LENGTH];
  volatile int32_t filtered_l[BUFFER_LENGTH];
  volatile int32_t filtered_r[BUFFER_LENGTH];

#if !USE_MICS 
  int sample_count = 0;
#else
  i2s_data_t mic_data;
#endif

  int i, j, k;
  int index_l;
  int index_r;
  int buffer_count = 0;

  volatile int64_t power_center;
  volatile int64_t power_left;
  volatile int64_t power_right;
  volatile int64_t power_temp;
  volatile int64_t fir_acc_l;
  volatile int64_t fir_acc_r;

  // These counters add hysteresis to the system, improving output stability 
  int center_count = 0;
  int left_count = 0;
  int right_count = 0;
  int window_count = 0;

#define USE_PRINT 0
#define USE_MICS 0
#define TRACK_TIME 1


#if USE_MICS 
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
    filtered_l[i] = 0;
    filtered_r[i] = 0;
  }
  buffer_count = 0;

  while (1) {
   
#if TRACK_TIME
   int time;
#endif

#if TRACK_TIME
  scratch_write(0xFFFF);
  time = get_time();
#endif
    
    // Collect WINDOW_LENGTH samples, and calculate the power.
    power_center = 0;
    power_left = 0;
    power_right = 0; 

    for (i = 0; i < WINDOW_LENGTH; i++) {
    
#if !USE_MICS      
      mic_buffer_l[buffer_count] = samples_l[sample_count];
      mic_buffer_r[buffer_count] = samples_r[sample_count];
              
      sample_count++;
      if (sample_count >= NUM_SAMPLES) {
        sample_count = 0;
      }
#else
      mic_data = i2s_get_data();
      mic_buffer_l[buffer_count] = (int32_t)mic_data.left;
      mic_buffer_r[buffer_count] = (int32_t)mic_data.right;
#endif

      // Apply the FIR filter.
      // Initialize k to the start point to apply the FIR filter.
      fir_acc_l = 0;
      fir_acc_r = 0;
      k = buffer_count - (NUM_TAPS - 1);
      if (k < 0) {
        k += BUFFER_LENGTH;
      }

      for (j = 0; j < NUM_TAPS; j++) {
        fir_acc_l += mic_buffer_l[k] * fir_taps[j];
        fir_acc_r += mic_buffer_r[k] * fir_taps[j];         
        k++;
        if (k == BUFFER_LENGTH) {
          k = 0;
        }
      }

      filtered_l[buffer_count] = fir_acc_l >> 16;
      filtered_r[buffer_count] = fir_acc_r >> 16;

      // Accumulate the powers.
      index_l = buffer_count;
      index_r = buffer_count;

      power_temp = filtered_l[index_l] + filtered_r[index_r];
      power_center += power_temp * power_temp;

      index_l -= SAMPLE_DIFFERENCE;
      if (index_l < 0 ) {
        index_l += BUFFER_LENGTH;
      }
      power_temp = filtered_l[index_l] + filtered_r[index_r];
      power_left += power_temp * power_temp;

      index_l = buffer_count;
      index_r -= SAMPLE_DIFFERENCE;
      if (index_r < 0) {
        index_r += BUFFER_LENGTH;
      }
      power_temp = filtered_l[index_l] + filtered_r[index_r];
      power_right += power_temp * power_temp;



      buffer_count++;
      if (buffer_count == BUFFER_LENGTH) {
        buffer_count = 0; 
      }
    }

#if TRACK_TIME
    time = get_time() - time;
    scratch_write(time); 
#endif

#if !USE_PRINT
    scratch_write(power_center >> 8);
    scratch_write(power_left >> 8);
    scratch_write(power_right >> 8);
#endif

#if USE_PRINT
    char* position_str[3] = { " C \r\n",
                              "  R\r\n",
                              "L  \r\n"};
#endif

    int position;
    window_count++;

    if (power_center > power_left) {
      if (power_center > power_right) {
        center_count++;
#if !USE_PRINT
        scratch_write(0);
#endif
      }
      else {
        right_count++;
#if !USE_PRINT
        scratch_write(1);
#endif
      }
    }
    else {
      if (power_left > power_right) {
        left_count++;
#if !USE_PRINT
        scratch_write(2);
#endif
      }
      else {
        right_count++;
#if !USE_PRINT
        scratch_write(1);
#endif
      }
    }

#define WINDOWS_PER_QUARTERSECOND SAMPLE_RATE / 4 / WINDOW_LENGTH 
    if (window_count == WINDOWS_PER_QUARTERSECOND) {
      window_count = 0;
      if (center_count > left_count) {
        if (center_count > right_count) {
          position = 0;
        }
        else {
          position = 1;
        }
      }
      else {
        if (left_count > right_count) {
          position = 2;
        }
        else {
          position = 1;
        }
      }
      center_count >>= 2;
      left_count >>= 2;
      right_count >>= 2;
#if USE_PRINT
      printf(position_str[position]);
#endif
    }
  }
}

int handle_interrupt(long cause, long epc, long regs[32]) {
  for(;;);
}
