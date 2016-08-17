#define SYS_CLK 50000000
#include "macros.h"
#include "vbx_cproto.h"
#include "interrupt.h"
#include "printf.h"

#include <stdint.h>

#define SAMPLE_RATE 48e3 // Hz
#define DISTANCE 100 // mm
#define SPEED_OF_SOUND 343e3 // mm/s
#define SAMPLE_DIFFERENCE DISTANCE*SAMPLE_RATE/SPEED_OF_SOUND

#define MIC1 ((volatile int32_t *) (0x10000000)) // TODO placeholder
#define MIC2 ((volatile int32_t *) (0x10000004)) // TODO placeholder
#define MIC_READY ((volatile int32_t *) (0x10000008)) // TODO placeholder
#define BUFFER_LENGTH 256
#define WINDOW_LENGTH 128

#define SCRATCHPAD_BASE ((volatile int32_t *) (0x80000000))


int main() {
  
  volatile int32_t *MIC_LEFT = MIC1;
  volatile int32_t *MIC_RIGHT = MIC2;
  volatile int32_t *mic_buffer_l[BUFFER_LENGTH];
  volatile int32_t *mic_buffer_r[BUFFER_LENGTH];

  int i;
  int buffer_count = 0;
  int power_front;
  int power_left;
  int power_right;
  int transfer_count;

  vbx_word_t *sound_vector_l = SCRATCHPAD_BASE;
  vbx_word_t *sound_vector_r = SCRATCHPAD_BASE + WINDOW_LENGTH + SAMPLE_DIFFERENCE;

  vbx_set_vl(WINDOW_LENGTH);

  while (1) {

    // Collect WINDOW_LENGTH samples.
    for (i = 0; i < WINDOW_LENGTH; i++) {
      while(!(*MIC_READY));
      mic_buffer_l[buffer_count] = *MIC_LEFT;
      mic_buffer_r[buffer_count] = *MIC_RIGHT;
      buffer_count++;

      if (buffer_count == BUFFER_LENGTH) {
        buffer_count = 0; 
      }
    }

    // Copy over WINDOW_LENGTH + SAMPLE_DIFFERENCE samples to scratchpad.
    transfer_count = buffer_count - (WINDOW_LENGTH + SAMPLE_DIFFERENCE);
    if (transfer_count < 0) {
      transfer_count += BUFFER_LENGTH;
    }
    for (i = 0; i < (WINDOW_LENGTH + SAMPLE_DIFFERENCE); i++) {
      sound_vector_l[i] = mic_buffer_l[transfer_count];
      sound_vector_r[i] = mic_buffer_r[transfer_count];

      transfer_count++;
      if (transfer_count = BUFFER_LENGTH) {
        transfer_count = 0;
      }
    }
  
    // Calculate the power assuming the sound is coming from the front.
    vbx_acc(VVWS, VMUL, power_front, (sound_vector_l + SAMPLE_DIFFERENCE), (sound_vector_r + SAMPLE_DIFFERENCE));
    
    // Calculate the power assuming the sound is coming from the left (right microphone is delayed).
    vbx_acc(VVWS, VMUL, power_left, (sound_vector_l + SAMPLE_DIFFERENCE), sound_vector_r);
    
    // Calculate the power assuming the sound is coming from the right (left microphone is delayed).
    vbx_acc(VVWS, VMUL, power_right, sound_vector_l, (sound_vector_r + SAMPLE_DIFFERENCE)); 

    if (power_front > power_left) {
      if (power_front > power_right) {
        printf("Front\n");
      }
      else {
        printf("Right\n");
      }
    }
    else {
      if (power_left > power_right) {
        printf("Left\n");
      }
      else {
        printf("Right\n");
      }
    }

  }
}


int handle_interrupt(long cause, long epc, long regs[32]) {
  for(;;);
}
