
#include "printf.h"
#include "i2s.h"
#include "interrupt.h"
#include "vbx.h"
#include "flash_dma.h"
#include "time.h"
#include "base64.h"
int do_lve(void* base){
	//initialize the unit stide to be 4 (1 word)
	//note this does not mean you can do un-aligned aaccesses

	the_mxp.stride=1;
	int vlen=20;
	int i;
	int errors=0;
	vbx_word_t* va=base;
	vbx_word_t* vb=va+vlen;
	vbx_byte_t* vc=(vbx_byte_t*)(vb+vlen);
	//debugx(va);
	//debugx(vb);
	//debugx(vc);
	for(i=0;i<vlen;i++){
		((volatile vbx_word_t*)va)[i]=i;
		((volatile vbx_word_t*)vb)[i]=i+3;
	}
	vbx_set_vl(vlen);
	vbx(VVBW,VADD,vc,va,vb);


	printf("vc = \r\n");
	for(i=0;i<vlen;i++){
		int val=(int)(((volatile vbx_byte_t*)vc)[i]);
		printf("%d ",val);
		if (val != ( 3 + i +i )){
			printf("%d != %d\r\n",val,3+ i +i );
			errors++;
		}
	}
	printf("\r\n");

	printf("vc = \r\n");
	for(i=0;i<vlen;i++){
		printf("%08x ",(int)(((volatile vbx_word_t*)vc)[i]));
	}
	printf("\r\n");
	return errors;
}

#define DO_SPRAM_TEST 0

int main()
{

	printf("TEST!\r\n");

	int xfer_size=64*1024;
	volatile char* sp_base=(volatile char*)SCRATCHPAD_BASE;
	int i;
	int spram_errors=0;
	printf("\r\n");
#if DO_SPRAM_TEST
	//SPRAM TEST:
	int spram_test_len=1024;
	for(i=0;i<spram_test_len;i++){
		sp_base[i]=0xAA;
	}
	for(i=0;i<spram_test_len;i++){
		printf("%d %02X \r\n",i,sp_base[i]);
		if(sp_base[i] != 0xAA){
			spram_errors++;
			printf(" spram test failed\r\n");
		}
	}
#endif
	//wait while initializing
	while(FLASH_DMA_BASE[FLASH_DMA_STATUS] & 0x80000000 ){
		printf("waiting for Flash initialization\r\n");
	}


	for(i=0;i<xfer_size;i++){
		sp_base[i]=0xFF;
	}

	int start_time=get_time();
	int flash_address=512*1024;


	flash_dma_trans(flash_address,(void*)sp_base,xfer_size);
	int lve_errors=do_lve(SCRATCHPAD_BASE+xfer_size);
	//wait for transfer done
	while(!flash_dma_done());

	//since the LVE does some printing that can take longer than the
	//dma transfer, the cycle count might not be strictly correct.
	//it should be about 19 cycles per byte, + interference
	printf("%d bytes read in %d cycles\r\n",xfer_size,get_time()-start_time);
	int dma_errors=0;
	for(i=0;i<xfer_size/4;i++){
		int a=i, b=((int*)sp_base)[i];
		if (a!=b){
			dma_errors++;
			printf("%d %d\r\n",a,b);
		}
	}
	printf("\r\n");

	//		print_base64(sp_base,xfer_size);
	int checksum=0;
	for(i=0;i<xfer_size;i++){
		checksum+=sp_base[i];
	}
	printf("DONE!!\r\n");

	if(spram_errors){
		printf("SPRAM ERRORS :(");
	}if(lve_errors){
		printf("LVE ERRORS :(");
	}if(dma_errors){
		printf("DMA ERRORS :(");
	}if(spram_errors + lve_errors + dma_errors == 0){
		printf ("No Errors :)");
	}

	return 0;
}
