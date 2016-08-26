#define output_vec_sum(vec_name,length) do{				\
  int i,total=0;													\
  for(i=0;i<length;i++) {										\
	 total+=(vec_name)[i];					\
  }debug(total); } while(0)

#define output_vec(vec_name,length) do{			\
	 int i;										\
	 for(i=0;i<length;i++) {							\
		debug((vec_name)[i]);					\
	 } } while(0)


// These counters add hysteresis to the system, improving output stability 
int center_count = 0;
int left_count = 0;
int right_count = 0;
int window_count = 0;

// This is a temp variable used when breaking up vector instructions.
int fir_acc_l_temp = 0;
int fir_acc_r_temp = 0; 

int position;


while (1) {

#if TRACK_TIME
  int time; 
#endif
  // Collect WINDOW_LENGTH samples.
  // Apply the FIR filter after acquiring each sample.
  // FIR filter is symmetric, applying cross-correlation is simpler than
  // convolution (no need for array flipping).

  // Empty fifo of possibly old data.
#if USE_MICS
  for(i = 0; i < 32; i++){
	 i2s_get_data();
  }
#endif

#if TRACK_TIME
  scratch_write(0xFFFF);
  time = get_time();
#endif

  for (i = 0; i < WINDOW_LENGTH; i++) {
    // Insert new sample into the ring buffer.
#if USE_MICS
	  i2s_data_t mic_data;
	  mic_data=i2s_get_data();
	  mic_buffer_l[buffer_count] = mic_data.left;
	  mic_buffer_r[buffer_count] = mic_data.right;
#else
	  mic_buffer_l[buffer_count] = samples_l[sample_count];
	  mic_buffer_r[buffer_count] = samples_r[sample_count];

 	  sample_count++;
 	  if (sample_count >= NUM_SAMPLES) {
 	   sample_count = 0;
 	  }
#endif

    // Check if vector instructions need to be broken up.
    if ((buffer_count + 1) - NUM_TAPS < 0) {
      int taps_offset = NUM_TAPS - (buffer_count + 1);
      vbx_word_t *v_fir_taps_end = v_fir_taps + taps_offset;
      vbx_word_t *mic_buffer_end_l = mic_buffer_l + BUFFER_LENGTH - taps_offset;
      vbx_word_t *mic_buffer_end_r = mic_buffer_r + BUFFER_LENGTH - taps_offset;
       
      vbx_set_vl(buffer_count + 1);
      vbx_acc(VVWS, VMUL, fir_acc_l, mic_buffer_l, v_fir_taps_end);
      fir_acc_l_temp = *fir_acc_l;
      vbx_acc(VVWS, VMUL, fir_acc_r, mic_buffer_r, v_fir_taps_end);
      fir_acc_r_temp = *fir_acc_r;

      vbx_set_vl(taps_offset);
      vbx_acc(VVWS, VMUL, fir_acc_l, mic_buffer_end_l, v_fir_taps);
      *fir_acc_l += fir_acc_l_temp;
      vbx_acc(VVWS, VMUL, fir_acc_r, mic_buffer_end_r, v_fir_taps);
      *fir_acc_r += fir_acc_r_temp;
    }
    
    else {
      int buffer_offset = buffer_count - (NUM_TAPS - 1);
      vbx_set_vl(NUM_TAPS);
      vbx_acc(VVWS, VMUL, fir_acc_l, mic_buffer_l + buffer_offset, v_fir_taps);
      vbx_acc(VVWS, VMUL, fir_acc_r, mic_buffer_r + buffer_offset, v_fir_taps);
    }
    
    v_filtered_l[buffer_count] = (*fir_acc_l) >> FIR_PRECISION;
    v_filtered_r[buffer_count] = (*fir_acc_r) >> FIR_PRECISION;

 	  buffer_count++;
 	  if (buffer_count >= BUFFER_LENGTH) {
      buffer_count = 0;
 	  }
  }

#if TRACK_TIME
  time = get_time() - time;
  scratch_write(time);
  scratch_write(0xFFFF);

  time = get_time();
#endif

  transfer_offset = buffer_count - WINDOW_LENGTH - SAMPLE_DIFFERENCE;
  if (transfer_offset < 0) {
	 transfer_offset += BUFFER_LENGTH;
  }

  vbx_set_vl(SAMPLE_DIFFERENCE);
  vbx(SVWS, VADD, sound_vector_l, 0, (v_filtered_l + transfer_offset));
  vbx(SVWS, VADD, sound_vector_r, 0, (v_filtered_r + transfer_offset));

  transfer_offset = buffer_count - WINDOW_LENGTH;
  if (transfer_offset < 0) {
	 transfer_offset += BUFFER_LENGTH;
  }

  // MOV mic_buffer to sound_vector
  vbx_set_vl(WINDOW_LENGTH);
  vbx(SVWS, VADD, (sound_vector_l + SAMPLE_DIFFERENCE), 0, (v_filtered_l + transfer_offset));
  vbx(SVWS, VADD, (sound_vector_r + SAMPLE_DIFFERENCE), 0, (v_filtered_r + transfer_offset));

  // Calculate the power assuming the sound is coming from the center.
  vbx(VVWS, VADD, sum_vector, (sound_vector_l + SAMPLE_DIFFERENCE), (sound_vector_r + SAMPLE_DIFFERENCE));
  vbx(SVWS, VMULH, sum_vector, PRESCALE_MUL, sum_vector);
  vbx_acc(VVWS, VMUL, power_center, sum_vector, sum_vector);

  // Calculate the power assuming the sound is coming from the left (right microphone is
  // delayed during sampling, so delay left microphone to compensate).
  vbx(VVWS, VADD, sum_vector, sound_vector_l, (sound_vector_r + SAMPLE_DIFFERENCE));
  vbx(SVWS, VMULH, sum_vector, PRESCALE_MUL, sum_vector);
  vbx_acc(VVWS, VMUL, power_left, sum_vector, sum_vector);

  // Calculate the power assuming the sound is coming from the right (left microphone is delayed
  // during sampling, so delay right microphone to compensate).
  vbx(VVWS, VADD, sum_vector, (sound_vector_l + SAMPLE_DIFFERENCE), sound_vector_r);
  vbx(SVWS, VMULH, sum_vector, PRESCALE_MUL, sum_vector);
  vbx_acc(VVWS, VMUL, power_right, sum_vector, sum_vector);

#if TRACK_TIME
  time = get_time() - time;
  scratch_write(time);
#endif
    
#if !USE_PRINT
  scratch_write(*power_center); 
  scratch_write(*power_right); 
  scratch_write(*power_left); 
#endif

#if USE_PRINT
  char* position_str[3] = { " C \r\n",
									          "  R\r\n",
									          "L  \r\n"};
#endif

  window_count++;

  if (*power_center > *power_left) {
	  if (*power_center > *power_right) {
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
	  if (*power_left > *power_right) {
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
