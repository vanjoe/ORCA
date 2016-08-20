#include "macros.h"
#include "vbx_cproto.h"
#include "interrupt.h"
#include "samples.h"

#include <stdint.h>

#define SYS_CLK 8000000 
#define SAMPLE_RATE 7800 // Hz
#define DISTANCE 140U // mm
#define SPEED_OF_SOUND 343e3 // mm/s
#define SAMPLE_DIFFERENCE ((int) (DISTANCE*SAMPLE_RATE/SPEED_OF_SOUND))

#define WINDOW_LENGTH 64 
#define NUM_WINDOWS 2
#define BUFFER_LENGTH WINDOW_LENGTH*NUM_WINDOWS 

#define SCRATCHPAD_BASE ((int32_t *) (0x80000000))

extern int samples_l[NUM_SAMPLES];
extern int samples_r[NUM_SAMPLES];

//extern int fir_taps[NUM_TAPS];
#define cause_write(a) asm volatile ("csrw mscratch, %0"	\
				     :				\
				     : "r" (a))
int main() {
  
  //TODO Use mics properly
  int sample_count = 0;

  vbx_word_t *mic_buffer_l = SCRATCHPAD_BASE;
  vbx_word_t *mic_buffer_r = SCRATCHPAD_BASE + BUFFER_LENGTH;
  vbx_word_t *sound_vector_l = mic_buffer_r + BUFFER_LENGTH;
  vbx_word_t *sound_vector_r = sound_vector_l + WINDOW_LENGTH + SAMPLE_DIFFERENCE;
  vbx_word_t *sum_vector = sound_vector_r + WINDOW_LENGTH + SAMPLE_DIFFERENCE;

  int32_t i;
  int32_t buffer_count = 0;
  int32_t *power_front = sum_vector + WINDOW_LENGTH;
  int32_t *power_left = power_front + 1;
  int32_t *power_right = power_left + 1;
  int32_t transfer_offset;
  cause_write(power_front);
  cause_write(power_left );
  cause_write(power_right);

  vbx_set_vl(BUFFER_LENGTH);
  vbx(SEWS, VAND, mic_buffer_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, mic_buffer_r, 0, vbx_ENUM);
  vbx_set_vl(WINDOW_LENGTH + SAMPLE_DIFFERENCE);
  vbx(SEWS, VAND, sound_vector_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, sound_vector_r, 0, vbx_ENUM);

  cause_write(mic_buffer_l[0]);
  for(i = 0; i < BUFFER_LENGTH; i++) {
    cause_write(i);
    cause_write(mic_buffer_l[i]);
    cause_write(mic_buffer_r[i]);
  }


  while (1) {

    // Collect WINDOW_LENGTH samples.
    for (i = 0; i < WINDOW_LENGTH; i++) {
      mic_buffer_l[buffer_count] = samples_l[sample_count];
      mic_buffer_r[buffer_count] = samples_r[sample_count];
      sample_count++;

      buffer_count++;

      if (buffer_count == BUFFER_LENGTH) {
        buffer_count = 0; 
      }
    }

    transfer_offset = buffer_count - WINDOW_LENGTH - SAMPLE_DIFFERENCE;
    if (transfer_offset < 0) {
     transfer_offset += BUFFER_LENGTH; 
    }

    vbx_set_vl(SAMPLE_DIFFERENCE);
    vbx(VVWS, VMOV, sound_vector_l, (mic_buffer_l + transfer_offset), 0);
    vbx(VVWS, VMOV, sound_vector_r, (mic_buffer_r + transfer_offset), 0);

    transfer_offset = buffer_count - WINDOW_LENGTH;
    if (transfer_offset < 0) {
      transfer_offset += BUFFER_LENGTH;
    }

    vbx_set_vl(WINDOW_LENGTH);
    vbx(VVWS, VMOV, (sound_vector_l + SAMPLE_DIFFERENCE), (mic_buffer_l + transfer_offset), 0);
    vbx(VVWS, VMOV, (sound_vector_r + SAMPLE_DIFFERENCE), (mic_buffer_r + transfer_offset), 0);

    // Calculate the power assuming the sound is coming from the front.
    vbx(VVWS, VADD, sum_vector, (sound_vector_l + SAMPLE_DIFFERENCE), (sound_vector_r + SAMPLE_DIFFERENCE));
    vbx_acc(VVWS, VMUL, power_front, sum_vector, sum_vector);
    for(i = 0; i < WINDOW_LENGTH; i++) {
      cause_write(i);
      cause_write(sum_vector[i]); 
    }

    // Calculate the power assuming the sound is coming from the left (right microphone is 
    // delayed during sampling, so delay left microphone to compensate).
    vbx(VVWS, VADD, sum_vector, sound_vector_l, (sound_vector_r + SAMPLE_DIFFERENCE));
    vbx_acc(VVWS, VMUL, power_left, sum_vector, sum_vector);
    for(i = 0; i < WINDOW_LENGTH; i++) {
      cause_write(i);
      cause_write(sum_vector[i]); 
    }
    
    // Calculate the power assuming the sound is coming from the right (left microphone is delayed
    // during sampling, so delay right microphone to compensate).
    vbx(VVWS, VADD, sum_vector, (sound_vector_l + SAMPLE_DIFFERENCE), sound_vector_r);
    vbx_acc(VVWS, VMUL, power_right, sum_vector, sum_vector); 
    for(i = 0; i < WINDOW_LENGTH; i++) {
      cause_write(i);
      cause_write(sum_vector[i]); 
    }

    asm volatile("csrw mscratch, %0\n csrw mscratch, %1\n csrw mscratch, %2"
      :
      : "r" (*power_front), "r" (*power_left), "r" (*power_right));
    

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
  return 0;
}
