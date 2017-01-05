#ifndef TIME_H
#define TIME_H

#define SYS_CLK 16000000

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

#endif //TIME_H
