
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

	the_lve.stride=1;
	int vlen=20;
	int i;
	int errors=0;
	vbx_word_t* va=base;
	vbx_word_t* vb=va+vlen;
	vbx_byte_t* vc=(vbx_byte_t*)(vb+vlen);

	for(i=0;i<vlen;i++){
		((volatile vbx_word_t*)va)[i]=i;
		((volatile vbx_word_t*)vb)[i]=i+3;
	}
	vbx_set_vl(vlen);
	vbx(VVBW,VADD,vc,va,vb);

	for(i=0;i<vlen;i++){
		int val=(int)(((volatile vbx_byte_t*)vc)[i]);

		if (val != ( 3 + i +i )){
			printf("Error @ %d:%d != %d\r\n",i,val,3+ i +i );
			errors++;
		}
	}
	return errors;
}

#define DO_SPRAM_TEST 1
#define TEST_RUNS     14
#define MAX_XFER_SIZE (64*1024)

extern const int      golden_size;
extern const uint16_t golden_BSD_checksums[];

uint16_t bsd_checksum(char *data, int bytes){
	int byte;
	uint16_t checksum = 0;
	//From https://en.wikipedia.org/wiki/BSD_checksum
	for(byte = 0; byte < bytes; byte++){
		checksum = (checksum >> 1) + ((checksum & 1) << 15);
		checksum += data[byte];
		checksum &= 0xffff;
	}
	return checksum;
}

int main()
{

	printf("TEST!\r\n");

	volatile char* sp_base = (volatile char*)SCRATCHPAD_BASE;
	int i;
	int spram_errors = 0;
	printf("\r\n");

#if DO_SPRAM_TEST
	//SPRAM TEST:
	int spram_test_len=1024;
	for(i=0;i<spram_test_len;i++){
		sp_base[i]=0xAA;
	}
	for(i=0;i<spram_test_len;i++){
		int val=sp_base[i];
		if(val != 0xAA){
			spram_errors++;
			printf("spram test failed %x != 0xAA \r\n",val);
		}
	}
#endif
	//wait while initializing
	while(FLASH_DMA_BASE[FLASH_DMA_STATUS] & 0x80000000){
		printf("waiting for Flash initialization\r\n");
	}

	int flash_address=0*1024;

	int checksum_errors=0;
	int lve_errors=0;
	uint32_t run;
	for(run = 0; run < TEST_RUNS; run++){
		printf("Run %u\r\n", (unsigned int)run);

		int xfer_size = MAX_XFER_SIZE;
		int chunk = 0;

		for(flash_address = 0; flash_address < golden_size; flash_address += xfer_size){
			if(flash_address + xfer_size > golden_size){
				xfer_size = golden_size - flash_address;
			}
			for(i=0;i<xfer_size;i++){
				sp_base[i]=0xAA;
			}
			{
				printf("First 16 bytes cleared:");
				int byte = 0;
				for(byte = 0; byte < 16; byte++){
					if(!(byte & 0x1)){
						printf(" ");
					}
					printf("%02X", sp_base[byte]);
				}
				printf("\r\n");
			}
			printf("Chunk %d: Transferring %d bytes starting at %d\r\n", chunk, xfer_size, flash_address);

			uint32_t internal_xfer_size = 1 << (((run+1) & 0xF)+1);
			if(internal_xfer_size < 4){
				internal_xfer_size = 4;
			}
			if(internal_xfer_size > xfer_size){
				internal_xfer_size = xfer_size;
			}
			printf("Using %u byte sub-transfers\r\n", (unsigned int)internal_xfer_size);
			
			int start_time = get_time();
			uint32_t xfer_start = 0;
			for(xfer_start = 0; xfer_start < xfer_size; xfer_start += internal_xfer_size){
				if(xfer_start + internal_xfer_size > xfer_size){
					internal_xfer_size = xfer_size - xfer_start;
					internal_xfer_size += 4 - (internal_xfer_size & 0x3);
				}
				while(!flash_dma_done()){
				}
				flash_dma_trans(flash_address+xfer_start, (void *)(sp_base+xfer_start), internal_xfer_size);
			}
			int local_lve_errors = do_lve(SCRATCHPAD_BASE + MAX_XFER_SIZE);
			//wait for transfer done
			while(!flash_dma_done()){
			}
			int end_time = get_time();

			//since the LVE does some printing that can take longer than the
			//dma transfer, the cycle count might not be strictly correct.
			//it should be about 19 cycles per byte, + interference
			printf("%d bytes read in %d cycles (%d lve errors)\r\n", xfer_size, end_time-start_time, local_lve_errors);

			uint16_t chunk_BSD_checksum = bsd_checksum((char *)sp_base, xfer_size);
			if(chunk_BSD_checksum != golden_BSD_checksums[chunk]){
				checksum_errors++;
				printf("Checksum error: expected %u got %u\r\n", golden_BSD_checksums[chunk], chunk_BSD_checksum);
				printf("First 16 bytes read:");
				int byte = 0;
				for(byte = 0; byte < 16; byte++){
					if(!(byte & 0x1)){
						printf(" ");
					}
					printf("%02X", sp_base[byte]);
				}
				printf("\r\n");
			}

			printf("\r\n");
			lve_errors += local_lve_errors;
			chunk++;
		}

		printf("Running total errors: LVE %d DMA %d\r\n\r\n\r\n", lve_errors, checksum_errors);
	}

	printf("DONE!!\r\n");

	if(spram_errors){
		printf("SPRAM ERRORS :(\r\n");
	}if(lve_errors){
		printf("LVE ERRORS :(\r\n");
	}if(checksum_errors){
		printf("DMA ERRORS :( (Assuming you initialized the flash properly with golden.bin)\r\n");
	}if(spram_errors + lve_errors + checksum_errors == 0){
		printf ("No Errors :)\r\n");
	}

	return 0;
}
