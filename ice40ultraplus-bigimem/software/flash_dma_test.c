
#include "printf.h"
#include "flash_dma.h"
#include "time.h"
#include "base64.h"

#define DMEM_SPRAM 0x08000000

int main()
{
	mputc(0,'J');
	mputc(0,'O');
	mputc(0,'E');
	printf("TEST!\r\n");

	int xfer_size=1024;
	volatile char* sp_base=(volatile char*)DMEM_SPRAM;
	int i;

	printf("\r\n");
	//wait while initializing
	while(	FLASH_DMA_BASE[FLASH_DMA_STATUS] & 0x80000000 ){
		printf("waiting for initialization\r\n");
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

		//since the LVE does some printing that can take longer than the
		//dma transfer, the cycle count might not be strictly correct.
		//it should be about 19 cycles per byte, + interference
		printf("%d bytes read in %d cycles\r\n",xfer_size,get_time()-start_time);
		for(i=0;i<xfer_size;i++){
			printf("%02X ",sp_base[i]);
		}
		printf("\r\n");

		//print_base64(sp_base,xfer_size);
		int checksum=0;
		for(i=0;i<xfer_size;i++){
		  checksum+=sp_base[i];
		}
		printf("DONE!!\r\n");
		delayms(3000);
	}
	return 0;


}
