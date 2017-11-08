#ifndef FLASH_DMA_H
#define FLASH_DMA_H

#define BITBANG 1

#if BITBANG

#include "sccb.h"
#include "time.h"
#include "printf.h"
#define SPI_MOSI (1<<7 )
#define SPI_MISO (1<<8 )
#define SPI_SCLK (1<<9 )
#define SPI_SS   (1<<10)

#define FLASH_CMD_WAKEUP 0xAB
#define FLASH_CMD_READ 0x03
void  flash_dma_trans(int flash_address,uint8_t* dest_address,unsigned xfer_length);

static int __attribute__((unused)) flash_dma_done()
{
	return 1;
}

void  flash_dma_init();

#else

#define FLASH_DMA_BASE ((volatile int*) 0x02000000)
#define FLASH_DMA_RADDR (0x0 >>2)
#define FLASH_DMA_WADDR (0x4 >>2)
#define FLASH_DMA_LEN   (0x8 >>2)
#define FLASH_DMA_STATUS (0xC >>2)

static void __attribute__((unused)) flash_dma_trans(int flash_address,void* dest_address,unsigned xfer_length)
{
	FLASH_DMA_BASE[FLASH_DMA_RADDR]=flash_address;
	FLASH_DMA_BASE[FLASH_DMA_WADDR]=(int)dest_address;
	FLASH_DMA_BASE[FLASH_DMA_LEN]=xfer_length;
}

static int __attribute__((unused)) flash_dma_done()
{
	return ! (FLASH_DMA_BASE[FLASH_DMA_STATUS]);
}

static void __attribute__((unused)) flash_dma_init()
{
	while(FLASH_DMA_BASE[FLASH_DMA_STATUS] & 0x80000000);
}

#endif
#endif //FLASH_DMA_H
