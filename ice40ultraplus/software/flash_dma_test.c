
#include "printf.h"
#include "i2s.h"
#include "interrupt.h"
#include "vbx.h"

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

#define FLASH_DMA_BASE ((volatile int*) 0x00010000)
#define FLASH_DMA_RADDR (0x0 >>2)
#define FLASH_DMA_WADDR (0x4 >>2)
#define FLASH_DMA_LEN   (0x8 >>2)
#define FLASH_DMA_STATUS (0xC >>2)

int main()
{
	printf("TEST!\r\n");
	int xfer_size=1020;
	volatile char* sp_base=(volatile char*)SCRATCHPAD_BASE;
	int i;
	for(i=0;i<xfer_size;i++){
		sp_base[i]=0;
	}

	/* for(i=0;i<xfer_size;i++){ */
	/* 	printf("%02X ",sp_base[i]); */
	/* } */
	printf("\r\n");
	//wait while initializing
	while(	FLASH_DMA_BASE[FLASH_DMA_STATUS] & 0x80000000 ){
		printf("waiting for initialization\r\n");
	}
	int start_tiem=get_time();
	FLASH_DMA_BASE[FLASH_DMA_RADDR]=4;
	FLASH_DMA_BASE[FLASH_DMA_WADDR]=(int)sp_base;
	FLASH_DMA_BASE[FLASH_DMA_LEN]=xfer_size;
	//wait for transfer done
	while(	FLASH_DMA_BASE[FLASH_DMA_STATUS] );
	printf("%d bytes read in %d cycles\r\n",xfer_size,get_time()-start_tiem);
	for(i=0;i<xfer_size;i++){
		printf("%02X ",sp_base[i]);
	}
	printf("\r\n");

	printf("DONE!!\r\n");




}
