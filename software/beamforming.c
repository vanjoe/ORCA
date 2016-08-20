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
#define scratch_write(a) asm volatile ("csrw mscratch, %0"	\
													:							\
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

  vbx_set_vl(BUFFER_LENGTH);
  vbx(SEWS, VAND, mic_buffer_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, mic_buffer_r, 0, vbx_ENUM);
  vbx_set_vl(WINDOW_LENGTH + SAMPLE_DIFFERENCE);
  vbx(SEWS, VAND, sound_vector_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, sound_vector_r, 0, vbx_ENUM);

#define output_vec_sum(vec_name,length) do{				\
  int i,total=0;													\
  for(i=0;i<length;i++) {										\
	 total+=(vec_name)[i];					\
  }scratch_write(total); } while(0)

#define output_vec(vec_name,length) do{			\
	 int i;										\
	 for(i=0;i<length;i++) {							\
		scratch_write((vec_name)[i]);					\
	 } } while(0)


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
  vbx(SVWS, VADD, sound_vector_l, 0, (mic_buffer_l + transfer_offset));
  vbx(SVWS, VADD, sound_vector_r, 0, (mic_buffer_r + transfer_offset));

  transfer_offset = buffer_count - WINDOW_LENGTH;
  if (transfer_offset < 0) {
	 transfer_offset += BUFFER_LENGTH;
  }
  //MOV mic_buffer to sound_vector_l
  vbx_set_vl(WINDOW_LENGTH);
  vbx(SVWS, VADD, (sound_vector_l + SAMPLE_DIFFERENCE),0, (mic_buffer_l + transfer_offset));
  vbx(SVWS, VADD, (sound_vector_r + SAMPLE_DIFFERENCE),0, (mic_buffer_r + transfer_offset));

  output_vec_sum( (sound_vector_l + SAMPLE_DIFFERENCE),WINDOW_LENGTH);
  output_vec_sum( (sound_vector_r + SAMPLE_DIFFERENCE),WINDOW_LENGTH);

  // Calculate the power assuming the sound is coming from the front.
  vbx(VVWS, VADD, sum_vector, (sound_vector_l + SAMPLE_DIFFERENCE), (sound_vector_r + SAMPLE_DIFFERENCE));
  vbx_acc(VVWS, VMUL, power_front, sum_vector, sum_vector);


  // Calculate the power assuming the sound is coming from the left (right microphone is
  // delayed during sampling, so delay left microphone to compensate).
  vbx(VVWS, VADD, sum_vector, sound_vector_l, (sound_vector_r + SAMPLE_DIFFERENCE));
  vbx_acc(VVWS, VMUL, power_left, sum_vector, sum_vector);

  // Calculate the power assuming the sound is coming from the right (left microphone is delayed
  // during sampling, so delay right microphone to compensate).
  vbx(VVWS, VADD, sum_vector, (sound_vector_l + SAMPLE_DIFFERENCE), sound_vector_r);
  vbx_acc(VVWS, VMUL, power_right, sum_vector, sum_vector);

  scratch_write(*power_front);
  scratch_write(*power_right);
  scratch_write(*power_left);



  if (*power_front > *power_left) {
	 if (*power_front > *power_right) {
		scratch_write(0);
	 }
	 else {
		scratch_write(2);
	 }
  }
  else {
	 if (*power_left > *power_right) {
		scratch_write(1);
	 }
	 else {
		scratch_write(2);
	 }
  }
  return 0;
 }

}


int handle_interrupt(long cause, long epc, long regs[32]) {
  for(;;);
  return 0;
}
