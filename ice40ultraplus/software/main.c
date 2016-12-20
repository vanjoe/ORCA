#include "printf.h"
#include "i2s.h"
#include "interrupt.h"
#include "lve_test.h"

#define SYS_CLK 8000000
static inline unsigned get_time()
{int tmp;       asm volatile("csrr %0,time":"=r"(tmp));return tmp;}

void delayus(unsigned int us)
{
	unsigned start=get_time();
	us*=(SYS_CLK/1000000);
	while(get_time()-start < us);
}
void delayms( unsigned int ms)
{
	unsigned long long us = ((unsigned long long)ms)*1000;

	unsigned long long max_us=0x7FFFFFFF;
	while(1){
		if(us > max_us){
			delayus((unsigned int)max_us);
			us-=max_us;
		}else{
			delayus((unsigned int)us);
			break;
		}
	}
}
//////////////////////
//
// UART stuff
//////////////////////
#define  UART_BASE ((volatile int*) 0x00020000)
volatile int*  UART_DATA=UART_BASE;
volatile int*  UART_LCR=UART_BASE+3;
volatile int*  UART_LSR=UART_BASE+5;

#define UART_LCR_8BIT_DEFAULT 0x03
#define UART_INIT() do{*UART_LCR = UART_LCR_8BIT_DEFAULT;}while(0)
#define UART_PUTC(c) do{*UART_DATA = (c);}while(0)
#define UART_BUSY() (!((*UART_LSR) &0x20))
void mputc ( void* p, char c)
{
	while(UART_BUSY());
	*UART_DATA = c;
}
#define debug(var) printf("%s:%d  %s = %d \r\n",__FILE__,__LINE__,#var,(signed)(var))
#define debugx(var) printf("%s:%d  %s = %08X \r\n",__FILE__,__LINE__,#var,(unsigned)(var))

#define bit(n) (1<<n)
#define SPI_BASE ((volatile int*)0x10000)
#define SPICR0   0x8 //1000 SPI Control Register 0 Read/Write
#define SPICR1   0x9 //1001 SPI Control Register 1 Read/Write
#define SPICR2   0xA //1010 SPI Control Register 2 Read/Write
#define SPIBR    0xB //1011 SPI Baud Rate Register Read/Write
#define SPITXDR  0xD //1101 SPI Transmit Data Register Read/Write
#define SPIRXDR  0xE //1110 SPI Receive Data Register Read
#define SPICSR   0xF //1111 SPI Chip Select Mask
#define SPISR    0xC //1100 SPI Status Register Read
#define SPIINTSR 0x6 //0110 SPI Interrupt Status Register
#define SPIINTCR 0x7 //0111 SPI Interrupt Control Register


#define SPISR_TRDY bit(4)
#define SPISR_RRDY bit(3)
#define SPISR_TIP bit(7)

static inline void wait_for_trdy(){
	while( !(SPI_BASE[SPISR] & SPISR_TRDY));
}
static inline void wait_for_rrdy(){
	while( !(SPI_BASE[SPISR] & SPISR_RRDY));
}
static inline void wait_for_not_tip(){
	while( (SPI_BASE[SPISR] & SPISR_TIP));
}


char spi_read_write(char write)
{
	//assume Slave select has already been set
	SPI_BASE[0] = write;
	while(SPI_BASE[2] == 0);
	return (char)SPI_BASE[0];
}

void __attribute__((noinline)) spi_run_cmd(char* cmd,char* resp,int cmd_len,int resp_len)
{

	int dummy_data=0;

	debugx(*cmd);
	SPI_BASE[1] = 0;
	int i;
	for(i=0;i<cmd_len;i++){
		spi_read_write(cmd[i]);
	}

	for(i=0;i<resp_len;i++){
		resp[i]=spi_read_write(dummy_data);
	}

	SPI_BASE[1] = (~0);
}

void __attribute__((noinline)) spi_read_data(char* data,unsigned address,unsigned length)
{
	int dummy_data = 0;

	//Slave Select
	SPI_BASE[1] = 0;
	//data read cmd
	spi_read_write(0x03);
	//address (3 bytes)

	spi_read_write((address>> 16) &0xFF);
	spi_read_write((address>> 8 ) &0xFF);
	spi_read_write((address>> 0 ) &0xFF);

	int i;
	for(i=0;i<length;i++){
		data[i]=spi_read_write(dummy_data);
	}
	//Slave Select
	SPI_BASE[1] = (~0);
}

char read_data[1024];

int main()
{
	UART_INIT();
	init_printf(0,mputc);
	int i=0;

	char cmd_resp[20]={0};
	char cmd=0xAB;
#if 1
	while(cmd_resp[10]!=0x13){
#else
	while(1){
#endif
		spi_run_cmd(&cmd,cmd_resp,sizeof(cmd),sizeof(cmd_resp));
		printf("release form power down = ");

		for(i=0;i<sizeof(cmd_resp);i++){
			printf(" 0x%x",cmd_resp[i]);
		}
		printf("\r\n");
	}
	cmd=0x9f;
	spi_run_cmd(&cmd,cmd_resp,sizeof(cmd),sizeof(cmd_resp));
	printf("id_str = ");
	for(i=0;i<sizeof(cmd_resp);i++){
		printf(" 0x%x",cmd_resp[i]);
	}
	printf("\r\n");


	int read_address=0x10;
	while(1){
		unsigned time=get_time();
		spi_read_data(read_data,read_address,sizeof(read_data));
		time = get_time()-time;
		printf("%d bytes read in %d cycles\r\n",sizeof(read_data),time);
		for(i=0;i<sizeof(read_data);i+=16){
			printf("%08x:",read_address+i);
			int j;
			for(j=0;j<16;j++){
				printf(" 0x%02x",read_data[i+j]);
			}printf("\r\n");
		}
		delayms(1000);
	}

	return 0;
}

int handle_interrupt(long cause, long epc, long regs[32]) {
	/*  switch(cause & 0xF) {

	    case M_SOFTWARE_INTERRUPT:
	    clear_software_interrupt();

	    case M_TIMER_INTERRUPT:
	    clear_timer_interrupt_cycles();

	    case M_EXTERNAL_INTERRUPT:
	    {
	    int plic_claim;
	    claim_external_interrupt(&plic_claim);
	    complete_external_interrupt(plic_claim);
	    }
	    break;

	    default:
	    break;
	    }
	*/
	return epc;

}
