#include "printf.h"
#include "base64.h"
#include "flash_dma.h"
#include "vbx.h"
int main()
{

	int flash_address=0;
	int flash_len=3124;
	char* temp_space = SCRATCHPAD_BASE;
	printf("STARTING\r\n");
	flash_dma_trans(flash_address,temp_space,flash_len);
	while(!flash_dma_done());

	debugx(temp_space[0]);
	debugx(temp_space[1]);
	debugx(temp_space[2]);


	printf("\n\n\n\r");
	print_base64(temp_space,flash_len);
	printf("\n\n\n\r");
	return 0;



}
