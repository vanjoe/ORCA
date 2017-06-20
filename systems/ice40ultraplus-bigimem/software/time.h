#ifndef TIME_H
#define TIME_H

#include "sys_clk.h"

static inline unsigned get_time()
{
	int tmp;
	asm volatile("csrr %0,time":"=r"(tmp));
	return tmp;
}

static inline void delayus(unsigned int us)
{
        unsigned start=get_time();
        us*=(SYS_CLK/1000000);
        while(get_time()-start < us);
}
void delayms( unsigned int ms);

#define cycle2ms(cyc) ((cyc)/(SYS_CLK/1000))

#endif //TIME_H
