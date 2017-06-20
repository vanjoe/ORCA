#ifndef TIME_H
#define TIME_H

#include "sys_clk.h"

static inline unsigned get_time()
{
	int tmp;
	asm volatile("csrr %0,time":"=r"(tmp));
	return tmp;
}
static inline void sleepuntil(unsigned int cycle)
{
	asm volatile ("csrw 0x800,%0"::"r"(cycle));
}
static inline void sleepus(unsigned int us)
{
	us*=(SYS_CLK/1000000);
	unsigned start=get_time();
	sleepuntil(start+us);
}
static inline void sleepms(unsigned int ms)
{
	while(ms--){
		sleepus(1000);
	}
}

static inline void delayus(unsigned int us)
{
        unsigned start=get_time();
        us*=(SYS_CLK/1000000);
        while(get_time()-start < us);
}
void delayms( unsigned int ms);

#define cycle2ms(cyc) (((unsigned)(cyc))/(SYS_CLK/1000))
#define ms2cycle(ms) ((ms) * (SYS_CLK/1000))
#endif //TIME_H
