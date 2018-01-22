#ifndef __TIME_H
#define __TIME_H

#include "orca_time.h"

static inline void sleepuntil(unsigned int cycle)
{
	asm volatile ("csrw 0x800,%0"::"r"(cycle));
}
static inline void sleepus(unsigned int us)
{
	us*=(ORCA_CLK/1000000);
	unsigned start=get_time();
	sleepuntil(start+us);
}
static inline void sleepms(unsigned int ms)
{
	while(ms--){
		sleepus(1000);
	}
}

#define cycle2ms(cyc) (((unsigned)(cyc))/(ORCA_CLK/1000))
#define ms2cycle(ms) ((ms) * (ORCA_CLK/1000))
#endif //#ifndef __TIME_H
