#ifndef ORCA_TIME_H
#define ORCA_TIME_H

#include <stdint.h>

#ifndef ORCA_CLK
#error "ORCA_CLK must be defined (ORCA core clock in Hz) before including orca_time.h"
#endif

//Get time in cycles
static inline uint32_t get_time(){
  int tmp;
  asm volatile("csrr %0,time":"=r"(tmp));
  return tmp;
}

//Delay for a specific number of milliseconds
static inline void delayms(uint32_t ms){
  uint32_t start_time = get_time();
  uint32_t delay      = ms * (ORCA_CLK/1000);
  while((get_time() - start_time) < delay){
  }
}

//Delay for a specific number of microseconds
static inline void delayus(uint32_t us) {
  uint32_t start_time = get_time();
  uint32_t delay      = us * (ORCA_CLK/1000000);
  while((get_time() - start_time) < delay){
  }
}

#endif //#ifndef ORCA_TIME_H
