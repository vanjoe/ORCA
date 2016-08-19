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

#define MIC1 ((volatile int32_t *) (0x10000000)) // TODO placeholder
#define MIC2 ((volatile int32_t *) (0x10000004)) // TODO placeholder
#define MIC_READY ((volatile int32_t *) (0x10000008)) // TODO placeholder

#define WINDOW_LENGTH 64 
#define NUM_WINDOWS 2
#define BUFFER_LENGTH WINDOW_LENGTH*NUM_WINDOWS 

#define SCRATCHPAD_BASE ((int32_t *) (0x80000000))

extern int samples_l[NUM_SAMPLES];
extern int samples_r[NUM_SAMPLES];

int main() {
  
  //volatile int32_t *MIC_LEFT = MIC1;
  //volatile int32_t *MIC_RIGHT = MIC2;

  //TODO Use mics properly
  int sample_count = 0;


  int32_t i;
  int32_t buffer_count = 0;
  volatile int32_t power_front = 0;
  volatile int32_t power_left = 0;
  volatile int32_t power_right = 0;
  int32_t transfer_index;

  vbx_word_t *mic_buffer_l = SCRATCHPAD_BASE;
  vbx_word_t *mic_buffer_r = SCRATCHPAD_BASE + BUFFER_LENGTH;
  vbx_word_t *sound_vector_l = mic_buffer_r + BUFFER_LENGTH;
  vbx_word_t *sound_vector_r = sound_vector_l + WINDOW_LENGTH + SAMPLE_DIFFERENCE;
  vbx_word_t *sum_vector = sound_vector_r + WINDOW_LENGTH + SAMPLE_DIFFERENCE;

  vbx_set_vl(BUFFER_LENGTH);
  vbx(SEWS, VADD, mic_buffer_l, 0, vbx_ENUM);
  vbx(SEWS, VADD, mic_buffer_r, 0, vbx_ENUM);
  vbx_set_vl(WINDOW_LENGTH + SAMPLE_DIFFERENCE);
  vbx(SEWS, VADD, sound_vector_l, 0, vbx_ENUM);
  vbx(SEWS, VADD, sound_vector_r, 0, vbx_ENUM);

  while (1) {

    // Collect WINDOW_LENGTH samples.
    for (i = 0; i < WINDOW_LENGTH; i++) {
     // while(!(*MIC_READY));
     // mic_buffer_l[buffer_count] = *MIC_LEFT;
     // mic_buffer_r[buffer_count] = *MIC_RIGHT;
      mic_buffer_l[buffer_count] = samples_l[sample_count];
      mic_buffer_r[buffer_count] = samples_r[sample_count];
      sample_count++;

      buffer_count++;

      if (buffer_count == BUFFER_LENGTH) {
        buffer_count = 0; 
      }
    }

    transfer_index = buffer_count - WINDOW_LENGTH - SAMPLE_DIFFERENCE;
    if (transfer_index < 0) {
     transfer_index += BUFFER_LENGTH; 
    }

    vbx_set_vl(SAMPLE_DIFFERENCE);
    vbx(VVWS, VMOV, sound_vector_l, (mic_buffer_l + transfer_index), 0);
    vbx(VVWS, VMOV, sound_vector_r, (mic_buffer_r + transfer_index), 0);

    transfer_index = buffer_count - WINDOW_LENGTH;
    if (transfer_index < 0) {
      transfer_index += BUFFER_LENGTH;
    }

    vbx_set_vl(WINDOW_LENGTH);
    vbx(VVWS, VMOV, (sound_vector_l + SAMPLE_DIFFERENCE), (mic_buffer_l + transfer_index), 0);
    vbx(VVWS, VMOV, (sound_vector_r + SAMPLE_DIFFERENCE), (mic_buffer_r + transfer_index), 0);

    power_front = 0;
    power_left = 0;
    power_right = 0;

    // Calculate the power assuming the sound is coming from the front.
    vbx(VVWS, VADD, sum_vector, (sound_vector_l + SAMPLE_DIFFERENCE), (sound_vector_r + SAMPLE_DIFFERENCE));
    //vbx_acc(VVWS, VMUL, &power_front, sum_vector, sum_vector);
    vbx_sync();
    for (i = 0; i < WINDOW_LENGTH; i++) {
      power_front += sum_vector[i] * sum_vector[i];
    }

    // Calculate the power assuming the sound is coming from the left (right microphone is 
    // delayed during sampling, so delay left microphone to compensate).
    vbx(VVWS, VADD, sum_vector, sound_vector_l, (sound_vector_r + SAMPLE_DIFFERENCE));
    //vbx_acc(VVWS, VMUL, &power_left, sum_vector, sum_vector);
    vbx_sync();
    for (i = 0; i < WINDOW_LENGTH; i++) {
      power_left += sum_vector[i] * sum_vector[i];
    }
    
    // Calculate the power assuming the sound is coming from the right (left microphone is delayed
    // during sampling, so delay right microphone to compensate).
    vbx(VVWS, VADD, sum_vector, (sound_vector_l + SAMPLE_DIFFERENCE), sound_vector_r);
    //vbx_acc(VVWS, VMUL, &power_right, sum_vector, sum_vector); 
    vbx_sync();
    for (i = 0; i < WINDOW_LENGTH; i++) {
      power_right += sum_vector[i] * sum_vector[i];
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
