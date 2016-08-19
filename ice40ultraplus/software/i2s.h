
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




/*********************/
/* I2S OUTPUT (JACK) */
/*********************/

#define TX_I2S_BUFFER_SIZE 0x100
#define TX_I2S_VERSION     ((volatile unsigned short *)0x00040000)
#define TX_I2S_CONFIG      ((volatile unsigned short *)0x00040002)
#define TX_I2S_INT_MASK    ((volatile unsigned short *)0x00040004)
#define TX_I2S_INT_STAT    ((volatile unsigned short *)0x00040006)
#define TX_I2S_BUFFER       ((volatile short *)(0x00040000 + (TX_I2S_BUFFER_SIZE<<1)))

extern int i2s_put_data_pointer;
static inline void i2s_put_data(short left,short right)
{
  //NOT THREADSAFE......
  TX_I2S_BUFFER[i2s_put_data_pointer++]=left;
  TX_I2S_BUFFER[i2s_put_data_pointer++]=right;

  //MODULO BUFFER size
  i2s_put_data_pointer &= TX_I2S_BUFFER_SIZE-1;
}




//This function sets the frequency for both the input and the output
void i2s_set_frequency(int system_clk_freq,int i2s_frequency);
