#include <stdint.h>

#include "interrupt.h"
#include "samples.h"

#define SYS_CLK 8000000 
#define SAMPLE_RATE 7800 // Hz
#define DISTANCE 140U // mm
#define SPEED_OF_SOUND 343e3 // mm/s
#define SAMPLE_DIFFERENCE ((int) (DISTANCE*SAMPLE_RATE/SPEED_OF_SOUND))

#define MIC1 ((volatile int32_t *) (0x10000000)) // TODO placeholder
#define MIC2 ((volatile int32_t *) (0x10000004)) // TODO placeholder
#define MIC_READY ((volatile int32_t *) (0x10000008)) // TODO placeholder

#define WINDOW_LENGTH 64 
#define NUM_WINDOWS 2
#define BUFFER_LENGTH WINDOW_LENGTH*NUM_WINDOWS 

extern int samples_l[NUM_SAMPLES]; 
extern int samples_r[NUM_SAMPLES];

int main() {

//  volatile int32_t *MIC_LEFT = MIC1;
//  volatile int32_t *MIC_RIGHT = MIC2;
  volatile int32_t mic_buffer_l[BUFFER_LENGTH];
  volatile int32_t mic_buffer_r[BUFFER_LENGTH];
  int32_t temp;

  // TODO Use mics properly
  int sample_count = 0;

  int i;
  int index_l;
  int index_r;
  int buffer_count = 0;
  
  volatile int power_front;
  volatile int power_left;
  volatile int power_right;

  for (i = 0; i < BUFFER_LENGTH; i++) {
    mic_buffer_l[i] = 0;
    mic_buffer_r[i] = 0;
  }


  while(1) {

    // Collect WINDOW_LENGTH samples.
    for (i = 0; i < WINDOW_LENGTH; i++) {
      //while(!(*MIC_READY));
      //mic_buffer_l[buffer_count] = *MIC_LEFT;
      //mic_buffer_r[buffer_count] = *MIC_RIGHT;
      mic_buffer_l[buffer_count] = samples_l[sample_count];
      mic_buffer_r[buffer_count] = samples_r[sample_count];
      sample_count++;

      buffer_count++;

      if (buffer_count == BUFFER_LENGTH) {
        buffer_count = 0; 
      }
    }

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

      asm volatile("csrw mscratch, %0"
        :
        : "r" (i));
      asm volatile("csrw mscratch, %0"
        :
        : "r" (power_front));

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

      asm volatile("csrw mscratch, %0"
        :
        : "r" (i));
      asm volatile("csrw mscratch, %0"
        :
        : "r" (power_left));

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

      asm volatile("csrw mscratch, %0"
        :
        : "r" (i));
      asm volatile("csrw mscratch, %0"
        :
        : "r" (power_right));

      index_l++;
      index_r++;
      if (index_l == BUFFER_LENGTH) {
        index_l = 0;
      }
      if (index_r == BUFFER_LENGTH) {
        index_r = 0;
      }
    }

    asm volatile("csrw mscratch, %0\n csrw mscratch, %1\n csrw mscratch, %2"
      :
      : "r" (power_front), "r" (power_left), "r" (power_right));

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

  }

}

int handle_interrupt(long cause, long epc, long regs[32]) {
  for(;;);
}
