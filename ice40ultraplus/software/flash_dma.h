#ifndef FLASH_DMA_H
#define FLASH_DMA_H


#define FLASH_DMA_BASE ((volatile int*) 0x02000000)
#define FLASH_DMA_RADDR (0x0 >>2)
#define FLASH_DMA_WADDR (0x4 >>2)
#define FLASH_DMA_LEN   (0x8 >>2)
#define FLASH_DMA_STATUS (0xC >>2)


static void flash_dma_trans(int flash_address,void* dest_address,unsigned xfer_length)
{
	FLASH_DMA_BASE[FLASH_DMA_RADDR]=flash_address;
	FLASH_DMA_BASE[FLASH_DMA_WADDR]=(int)dest_address;
	FLASH_DMA_BASE[FLASH_DMA_LEN]=xfer_length;
}

static int flash_dma_done()
{
	return ! (FLASH_DMA_BASE[FLASH_DMA_STATUS]);
}

#endif //FLASH_DMA_H
