#include "i2s.h"
int i2s_put_data_pointer;


void i2s_set_frequency(int system_clk_freq,int i2s_frequency){
  //how many clock cycles are necessary between flipping the i2s clock (1/2 a wavelengt)?
  //for each sample there are 2 channels,each channel has 16 bits for 32 bits per sample
  //each bit has two clock transitions (rising/falling)

  //so the clock divider is set to the following:
  int clk_divider=system_clk_freq/(i2s_frequency*(2*32));

  RX_I2S_BASE[RX_I2S_CLOCK_DIV_OFFSET]=clk_divider;

  short tx_config=(clk_divider <<8) | 0x01;
  *TX_I2S_CONFIG = tx_config;

}
