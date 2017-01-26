

#include "printf.h"
#include "flash_dma.h"
#include "time.h"
#include "base64.h"
#include "system.h"

int main()
{
	printf("TEST!\r\n");

	int xfer_size=1024;
	volatile unsigned char sp_base[32*1024];
	int i;

	printf("\r\n");
	//wait while initializing
	while(	FLASH_DMA_BASE[FLASH_DMA_STATUS] & 0x80000000 ){
		printf("waiting for initialization\r\n");
	}

	for(i=0;i<xfer_size;i++){
		sp_base[i]=0xAA;
	}
	for(i=0;i<xfer_size;i++){
		if(sp_base[i] !=0xAA){
			printf("%d: %x != %x\r\n",i,sp_base[i],0xAA);
		}
	}

	while(1){
		for(i=0;i<xfer_size;i++){
			sp_base[i]=0;
		}


		int start_time=get_time();
		int flash_address=0;

		flash_dma_trans(flash_address,(void*)sp_base,xfer_size);

		//wait for transfer done
		while(!flash_dma_done());

		printf("%d bytes read in %d cycles\r\n",xfer_size,get_time()-start_time);
		for(i=0;i<xfer_size;i++){
			printf("%02X ",sp_base[i]);
		}
		printf("\r\n");

		printf("DONE!!\r\n");
		delayms(3000);
	}
	return 0;


}
