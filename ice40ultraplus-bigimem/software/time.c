#include "time.h"

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
