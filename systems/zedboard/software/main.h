#ifndef __MAIN_H
#define __MAIN_H

#include <stdint.h>

#define SYS_CLK 66666667
static inline uint32_t get_time() {
  uint32_t tmp;
  asm volatile("csrr %0,time":"=r"(tmp));
  return tmp;
}
static inline void delayms(uint32_t ms) {
  uint32_t start = get_time();
  ms*=(SYS_CLK/1000);
  while(((uint32_t)(get_time()-start)) < ms);
}
static inline void delayus(uint32_t us) {
  uint32_t start = get_time();
  us*=(SYS_CLK/1000000);
  while(((uint32_t)(get_time()-start)) < us);
}

#endif //__MAIN_H
