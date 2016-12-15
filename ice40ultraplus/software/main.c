#include "printf.h"
#include "i2s.h"
#include "interrupt.h"
#include "lve_test.h"

#define SYS_CLK 6000000
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
/* void __attribute__((noinline)) spi_read_id(){ */
/* 	char id_str[20]; */

/* 	//COMMAND */
/* 	SPI_BASE[SPICR2]=0xC0; */
/* 	wait_for_trdy(); */
/* 	SPI_BASE[SPITXDR] =  0x9F; */
/* 	wait_for_rrdy(); */
/* 	int dummy_data; */
/* 	dummy_data=SPI_BASE[SPIRXDR]; */
/* 	dummy_data=0; */
/* 	//READ */

/* 	SPI_BASE[SPITXDR] =  dummy_data; */
/* 	wait_for_rrdy(); */
/* 	id_str[0]=SPI_BASE[SPIRXDR]; //mem_type */

/* 	SPI_BASE[SPITXDR] =  dummy_data; */
/* 	wait_for_rrdy(); */
/* 	id_str[1]=SPI_BASE[SPIRXDR];//mem capacity */

/* 	SPI_BASE[SPITXDR] =  dummy_data; */
/* 	wait_for_rrdy(); */
/* 	id_str[2]=SPI_BASE[SPIRXDR];//cfd lenght */
/* 	int i; */
/* 	int cfd_length=id_str[2]; */
/* 	for(i=0;i<cfd_length;i++){ */
/* 		SPI_BASE[SPITXDR] =  dummy_data; */
/* 		wait_for_rrdy(); */
/* 		id_str[2+i]=SPI_BASE[SPIRXDR];//cfd lenght */
/* 	} */
/* 	SPI_BASE[SPICR2]=0x80; */
/* 	//wait for not TIP */
/* 	wait_for_not_tip(); */

/* 	return ; */
/* } */


void __attribute__((noinline)) spi_read_id(char* id_str)
{

	int dummy_data;

	SPI_BASE[1] = 1;
	SPI_BASE[0] = 0x9F;
	while(SPI_BASE[2] == 0);
	dummy_data=SPI_BASE[0];
	dummy_data=0x0;

	SPI_BASE[0] = dummy_data;
	while(SPI_BASE[2] == 0);
	id_str[0]=SPI_BASE[0];

	SPI_BASE[0] = dummy_data;
	while(SPI_BASE[2] == 0);
	id_str[1]=SPI_BASE[0];

	SPI_BASE[0] = dummy_data;
	while(SPI_BASE[2] == 0);
	id_str[2]=SPI_BASE[0];

	SPI_BASE[0] = dummy_data;
	while(SPI_BASE[2] == 0);


	int len= 16;
	int i=0;
	while(i++ < len){
		SPI_BASE[0] = dummy_data;
		id_str[3+i]=SPI_BASE[0];
	}
	SPI_BASE[1] = 0;
}
int main()
{
	UART_INIT();
	init_printf(0,mputc);
	int i=0;
	while(i++<10){
		debug(i);
	}

	int a=0;
	char id_str[20]={0};
	while(1){
		spi_read_id(id_str);

		printf("id_str = ");

		for(i=0;i<sizeof(id_str);i++){
			printf(" 0x%x",id_str[i]);
		}
		printf("\r\n");
	}
	while(1){
		debug(a++);
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
