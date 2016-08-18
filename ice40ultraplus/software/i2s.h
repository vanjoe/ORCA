
#include <stdint.h>
#include "printf.h"

/********************/
/* I2S INPUT (MICS) */
/********************/
static uint32_t volatile * const  RX_I2S_BASE=( uint32_t volatile * const)0x00010000;
static const int RX_I2S_VERSION_OFFSET=0;
static const int RX_I2S_CLOCK_DIV_OFFSET=1;
static const int RX_I2S_DATA_OFFSET=2;

typedef struct {
  int16_t left;
  int16_t right;
}i2s_data_t;
union i2s_union{
  i2s_data_t as_struct;
  int32_t as_int;
};

static inline i2s_data_t i2s_get_data(){
  union i2s_union data;
  data.as_int = RX_I2S_BASE[RX_I2S_DATA_OFFSET];
  return data.as_struct;
}

static  void i2s_set_frequency(int system_clk_freq,int i2s_frequency){
  //how many clock cycles are necessary between flipping the i2s clock (1/2 a wavelengt)?
  //for each sample there are 2 channels,each channel has 16 bits for 32 bits per sample
  //each bit has two clock transitions (rising/falling)

  //so the clock divider is set to the following:
  int clk_divider=system_clk_freq/(i2s_frequency*(2*32));

  RX_I2S_BASE[RX_I2S_CLOCK_DIV_OFFSET]=clk_divider;

}


/*********************/
/* I2S OUTPUT (JACK) */
/*********************/

#define I2S_BUFFER_SIZE 0x100
#define I2S_VERSION     ((volatile unsigned short *)0x00040000)
#define I2S_CONFIG      ((volatile unsigned short *)0x00040002)
#define I2S_INT_MASK    ((volatile unsigned short *)0x00040004)
#define I2S_INT_STAT    ((volatile unsigned short *)0x00040006)
#define I2S_WORD0       ((volatile short *)(0x00040000 + (I2S_BUFFER_SIZE<<1)))

#define I2S_WORD(NUM) ((I2S_WORD0)+(NUM))
