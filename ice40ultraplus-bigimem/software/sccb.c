#include "sccb.h"
#include "time.h"

//Note that though the SCCB spec has a totem-pole drive scheme with conflict
//protection resistors the board is layed out as I2C style open collector
//with pull-ups.  This code does not drive 1's, and there is no difference
//between 1 and a high-Z.

const unsigned int DELAY_CYCLES = (SYS_CLK/8000000)*20;//Too high and writes fail...

static inline void delay_cycles(unsigned int cycles)
{
	unsigned start_cycle = get_time();
	unsigned end_cycle = start_cycle + cycles;
	while(get_time() < end_cycle);
}

static inline void pio_enable(void *pioBase, uint32_t data){
	volatile uint32_t *pioRegister = (volatile uint32_t *)pioBase;
	pioRegister[PIO_ENABLE_REGISTER] = data;
	delay_cycles(DELAY_CYCLES);
}

static inline void pio_write(void *pioBase, uint32_t data){
	volatile uint32_t *pioRegister = (volatile uint32_t *)pioBase;
	pioRegister[PIO_DATA_REGISTER] = data;
	delay_cycles(DELAY_CYCLES);
}

static inline uint32_t pio_read(void *pioBase){
	volatile uint32_t *pioRegister = (volatile uint32_t *)pioBase;
	uint32_t readData = pioRegister[PIO_DATA_REGISTER];
	delay_cycles(DELAY_CYCLES);
	return readData;
}

void sccb_init(void *pioBase){
	pio_enable(pioBase, 0);
	pio_write(pioBase, 0);
}

static void sccb_start(void *pioBase){
	pio_enable(pioBase, PIO_SDA_MASK);                //data <= 0
	pio_enable(pioBase, PIO_SDA_MASK | PIO_SCL_MASK); //clk  <= 0
}

static void sccb_stop(void *pioBase){
	pio_enable(pioBase, PIO_SDA_MASK | PIO_SCL_MASK); //data <= 0 (clk already 0)
	pio_enable(pioBase, PIO_SDA_MASK);                //clk  <= 1
	delay_cycles(DELAY_CYCLES);
	pio_enable(pioBase, 0);                           //data <= 1
}

static void sccb_write_phase(void *pioBase, uint8_t data){
	int bit;
	for(bit = 7; bit >= 0; bit--){
		if(data & (1 << bit)){
			pio_enable(pioBase, PIO_SCL_MASK); //data <= 1
			pio_enable(pioBase, 0);            //clk  <= 1
			delay_cycles(DELAY_CYCLES);
			pio_enable(pioBase, PIO_SCL_MASK); //clk  <= 0
		} else {
			pio_enable(pioBase, PIO_SDA_MASK | PIO_SCL_MASK); //data <= 0
			pio_enable(pioBase, PIO_SDA_MASK);                //clk  <= 1
			delay_cycles(DELAY_CYCLES);
			pio_enable(pioBase, PIO_SDA_MASK | PIO_SCL_MASK); //clk  <= 0
		}
	}
	pio_enable(pioBase, PIO_SCL_MASK); //data <= Z
	pio_enable(pioBase, 0);            //clk  <= 1
	delay_cycles(DELAY_CYCLES);
	pio_enable(pioBase, PIO_SCL_MASK); //clk  <= 0
}

void sccb_write(void *pioBase, uint8_t slaveAddress, uint8_t subAddress, uint8_t data){
	sccb_init(pioBase); //Should already be, but just for safety's sake

	sccb_start(pioBase);
	sccb_write_phase(pioBase, slaveAddress);
	sccb_write_phase(pioBase, subAddress);
	sccb_write_phase(pioBase, data);

	sccb_stop(pioBase);
	delay_cycles(DELAY_CYCLES*3);
}

uint8_t sccb_read(void *pioBase, uint8_t slaveAddress, uint8_t subAddress){
	sccb_init(pioBase); //Should already be, but just for safety's sake

	uint8_t readData = 0xA5;

	//Write the subaddress
	sccb_start(pioBase);
	sccb_write_phase(pioBase, slaveAddress);
	sccb_write_phase(pioBase, subAddress);
	sccb_stop(pioBase);

	delay_cycles(DELAY_CYCLES*3);

	//Now read
	sccb_start(pioBase);
	sccb_write_phase(pioBase, slaveAddress | 0x01); //Set read bit
	int bit;
	for(bit = 7; bit >= 0; bit--){
		readData = readData << 1;
		pio_enable(pioBase, 0);            //clk  <= 1
		delay_cycles(DELAY_CYCLES);
		readData = readData | ((pio_read(pioBase) & PIO_SDA_MASK) >> PIO_SDA_BIT);
		pio_enable(pioBase, PIO_SCL_MASK); //clk  <= 0
	}
	pio_enable(pioBase, PIO_SCL_MASK); //data <= 1
	pio_enable(pioBase, 0);            //clk  <= 1
	delay_cycles(DELAY_CYCLES);
	pio_enable(pioBase, PIO_SCL_MASK); //clk  <= 0

	sccb_stop(pioBase);
	delay_cycles(DELAY_CYCLES*3);

	return readData;
}
