#ifndef TIME_H
#define TIME_H

#define SYS_CLK 8000000

static inline unsigned get_time()

{int tmp;       asm volatile("csrr %0,time":"=r"(tmp));return tmp;}

void delayus(unsigned int us)
{
        unsigned start=get_time();
        us*=(SYS_CLK/1000000);
        while(get_time()-start < us);
}
void delayms( unsigned int ms)
{
        unsigned long long us = ((unsigned long long)ms)*1000;

        unsigned long long max_us=0x7FFFFFFF;
        while(1){
                if(us > max_us){
                        delayus((unsigned int)max_us);
                        us-=max_us;
                }else{
                        delayus((unsigned int)us);
                        break;
                }
        }
}

#endif //TIME_H
