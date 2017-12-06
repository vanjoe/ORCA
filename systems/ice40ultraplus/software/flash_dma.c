#include "flash_dma.h"
static void __attribute__((unused)) spi_set_bit(volatile uint32_t* pio,uint32_t bit,int val)
{
	uint32_t* rpio=(uint32_t*)pio;
	if(val){
		*pio = *rpio |(bit);
	}else{
		*pio = *rpio& (~bit);
	}
}
static uint8_t __attribute__((unused)) spi_get_bit(volatile uint32_t* pio,uint32_t bit)
{
	return !! (*pio & bit);
}

static uint8_t __attribute__((unused)) spi_xfer_byte(volatile uint32_t* pio,
                                                     uint8_t write)
{
	uint8_t ret=0;
	sleepus(5);
	for(int i=7;i>=0;--i){
		sleepus(5);
		spi_set_bit(pio,SPI_SCLK,0);
		spi_set_bit(pio,SPI_MOSI,write&(1<<i));
		sleepus(5);
		spi_set_bit(pio,SPI_SCLK,1);
		ret |= spi_get_bit(pio,SPI_MISO)<<i;
	}
	sleepus(5);
	spi_set_bit(pio,SPI_SCLK,0);

	return ret;
}
void flash_dma_trans(int flash_address,uint8_t* dest_address,unsigned xfer_length)
{
	spi_set_bit(SCCB_PIO_BASE+PIO_DATA_REGISTER ,SPI_SS,0);
	spi_xfer_byte(SCCB_PIO_BASE+PIO_DATA_REGISTER,FLASH_CMD_READ);
	spi_xfer_byte(SCCB_PIO_BASE+PIO_DATA_REGISTER,(flash_address>>16)&0xFF);
	spi_xfer_byte(SCCB_PIO_BASE+PIO_DATA_REGISTER,(flash_address>>8)&0xFF);
	spi_xfer_byte(SCCB_PIO_BASE+PIO_DATA_REGISTER,(flash_address>>0)&0xFF);
	for(int i=0;i<xfer_length;++i){
		dest_address[i]=	spi_xfer_byte(SCCB_PIO_BASE+PIO_DATA_REGISTER,0);
	}
	spi_set_bit(SCCB_PIO_BASE+PIO_DATA_REGISTER ,SPI_SS,1);

}

 void flash_dma_init()
{

	spi_set_bit(SCCB_PIO_BASE+PIO_DATA_REGISTER ,SPI_SS,1);
	delayus(300);
	spi_set_bit(SCCB_PIO_BASE+PIO_DATA_REGISTER ,SPI_SS,0);
	spi_xfer_byte(SCCB_PIO_BASE+PIO_DATA_REGISTER,FLASH_CMD_WAKEUP);
	spi_xfer_byte(SCCB_PIO_BASE+PIO_DATA_REGISTER,0);
	spi_xfer_byte(SCCB_PIO_BASE+PIO_DATA_REGISTER,0);
	spi_set_bit(SCCB_PIO_BASE+PIO_DATA_REGISTER ,SPI_SS,1);

}
