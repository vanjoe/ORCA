#include "printf.h"
#include "sccb.h"
#include "ovm7692.h"

int main(){
	int errors = 0;
	printf("\r\nTesting SCCB\r\n");

	sccb_init(SCCB_PIO_BASE);

	//Read product ID
	uint8_t pidh = sccb_read(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_PIDH);
	uint8_t pidl = sccb_read(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_PIDL);

	printf("OVM7692 PID reads 0x%02X%02X, expected 0x%02X%02X", pidh, pidl, OVM7692_EXPECTED_PIDH, OVM7692_EXPECTED_PIDL);
	if((pidh != OVM7692_DEFAULT_PIDH) || (pidh != OVM7692_DEFAULT_PIDH)){
		printf(" -- ERROR");
		errors++;
	}
	printf("\r\n");

	//Test that writing to different addresses works
	sccb_write(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_RGAIN, 0x00);
	sccb_write(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_GGAIN, 0x55);
	sccb_write(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_BGAIN, 0xFF);
	uint8_t rgain = sccb_read(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_RGAIN);
	uint8_t ggain = sccb_read(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_GGAIN);
	uint8_t bgain = sccb_read(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_BGAIN);
	printf("Wrote 0x00, 0x55, 0xFF to RGAIN/GGAIN/BGAIN, got 0x%02X, 0x%02X, 0x%02X", rgain, ggain, bgain);
	if((rgain != 0x00) || (ggain != 0x55) || (bgain != 0xFF)){
		printf(" -- ERROR");
		errors++;
	}
	printf("\r\n");

	sccb_write(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_RGAIN, OVM7692_DEFAULT_RGAIN);
	sccb_write(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_GGAIN, OVM7692_DEFAULT_GGAIN);
	sccb_write(SCCB_PIO_BASE, OVM7692_ADDRESS, OVM7692_SUBADDRESS_BGAIN, OVM7692_DEFAULT_BGAIN);

	if(errors){
		printf("SCCB test failed with %d errors :(\r\n", errors);
	} else {
		printf("SCCB test passed :)\r\n");
	}
													 
	return 0;
}
