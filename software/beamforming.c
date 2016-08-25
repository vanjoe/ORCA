#include "macros.h"
#include "vbx_cproto.h"
#include "interrupt.h"
#include "samples.h"
#include "fir.h"
#include "printf.h"
#include "i2s.h"

#include <stddef.h>

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

  
static inline unsigned get_time() {
  int tmp;       
  asm volatile("csrr %0, time"
    : "=r" (tmp));
  return tmp;
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
#define PRESCALE_MUL 1 << (32 - PRESCALE)

#define SCRATCHPAD_BASE ((int32_t *) (0x80000000))

extern int samples_l[NUM_SAMPLES];
extern int samples_r[NUM_SAMPLES];

extern int fir_taps[NUM_TAPS];

#define scratch_write(a) asm volatile ("csrw mscratch, %0"	\
													:							\
													: "r" (a))
                        
static char *scratchpad_base;

void sp_malloc_init(char *base_address) {
  scratchpad_base = base_address; 
}

vbx_void_t *vbx_lattice_sp_malloc(size_t num_bytes) {
  vbx_void_t * old_sp = scratchpad_base;

  if (num_bytes & 0x00000003) {
    num_bytes &= ~(0x00000003);
    num_bytes += sizeof(vbx_word_t);
  }

  scratchpad_base += num_bytes;
  return old_sp; 
}


#define USE_PRINT 0
#define USE_MICS  0
#define TRACK_TIME 1

int main() {

#if USE_PRINT
  UART_INIT();
  init_printf(0,mputc);
  printf("HELLO UART!!\r\n");
#endif

#if USE_MICS
  i2s_set_frequency(SYS_CLK, 8000);
#endif
  int sample_count = 0;

  vbx_word_t *v_filtered_l;
  vbx_word_t *v_filtered_r;
  vbx_word_t *sound_vector_l;
  vbx_word_t *sound_vector_r;
  vbx_word_t *sum_vector;
  vbx_word_t *v_fir_taps;
  vbx_word_t *mic_buffer_l;
  vbx_word_t *mic_buffer_r;

  vbx_word_t *power_center;
  vbx_word_t *power_left;
  vbx_word_t *power_right;
  vbx_word_t *fir_acc_l;
  vbx_word_t *fir_acc_r;

  int32_t i;
  int32_t buffer_count = 0;
  int32_t transfer_offset;

  sp_malloc_init((char *)SCRATCHPAD_BASE);

  v_filtered_l = (vbx_word_t *) vbx_lattice_sp_malloc(BUFFER_LENGTH * sizeof(vbx_word_t));
  v_filtered_r = (vbx_word_t *) vbx_lattice_sp_malloc(BUFFER_LENGTH * sizeof(vbx_word_t)); 
  sound_vector_l = (vbx_word_t *) vbx_lattice_sp_malloc((WINDOW_LENGTH + SAMPLE_DIFFERENCE) * sizeof(vbx_word_t));
  sound_vector_r = (vbx_word_t *) vbx_lattice_sp_malloc((WINDOW_LENGTH + SAMPLE_DIFFERENCE) * sizeof(vbx_word_t));
  sum_vector = (vbx_word_t *) vbx_lattice_sp_malloc((WINDOW_LENGTH) * sizeof(vbx_word_t));
  v_fir_taps = (vbx_word_t *) vbx_lattice_sp_malloc((NUM_TAPS) * sizeof(vbx_word_t));  
  mic_buffer_l = (vbx_word_t *) vbx_lattice_sp_malloc(BUFFER_LENGTH * sizeof(vbx_word_t));
  mic_buffer_r = (vbx_word_t *) vbx_lattice_sp_malloc(BUFFER_LENGTH * sizeof(vbx_word_t));
  power_center = (vbx_word_t *) vbx_lattice_sp_malloc(sizeof(vbx_word_t));
  power_left = (vbx_word_t *) vbx_lattice_sp_malloc(sizeof(vbx_word_t));
  power_right = (vbx_word_t *) vbx_lattice_sp_malloc(sizeof(vbx_word_t)); 
  fir_acc_l = (vbx_word_t *) vbx_lattice_sp_malloc(sizeof(vbx_word_t));
  fir_acc_r = (vbx_word_t *) vbx_lattice_sp_malloc(sizeof(vbx_word_t));

  vbx_set_vl(BUFFER_LENGTH);
  vbx(SEWS, VAND, v_filtered_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, v_filtered_r, 0, vbx_ENUM);
  vbx(SEWS, VAND, mic_buffer_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, mic_buffer_r, 0, vbx_ENUM);
  vbx_set_vl(WINDOW_LENGTH + SAMPLE_DIFFERENCE);
  vbx(SEWS, VAND, sound_vector_l, 0, vbx_ENUM);
  vbx(SEWS, VAND, sound_vector_r, 0, vbx_ENUM);

  // Initialize FIR vector.
  for (i = 0; i < NUM_TAPS; i++) {
    v_fir_taps[i] = fir_taps[i];
  }

#if USE_PRINT
  printf("entering loop\r\n");
#endif

  #include "fragment_ring.c"

  return 0;
}

int handle_interrupt(long cause, long epc, long regs[32]) {
  for(;;);
  return 0;
}
