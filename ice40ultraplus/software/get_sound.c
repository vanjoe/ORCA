#include "printf.h"
#include "i2s.h"
#include "interrupt.h"
#include "lve_test.h"

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
#define UART_TX_FULL() (!((*UART_LSR) &0x20))
#define UART_RX_EMPTY() (!((*UART_LSR) &0x01))
void mputc ( void* p, char c)
{
        while(UART_TX_FULL());
        *UART_DATA = c;
}
int getc(){
  while(UART_RX_EMPTY());
  return *UART_DATA;
}

#define SYS_CLK 8000000
static inline unsigned get_time()
{int tmp;       asm volatile("csrr %0,time":"=r"(tmp));return tmp;}
static inline void to_host(unsigned tmp)
{   asm volatile("csrw mscratch,%0"::"r"(tmp));}


void delayus(int us)
{
	unsigned start=get_time();
	us*=(SYS_CLK/1000000);
	while(get_time()-start < us);
}

#define SCRATCHPAD_BASE 0x80000000

#define MIC_HZ 8000
int main()
{
  int retval=0;
  UART_INIT();
  init_printf(0,mputc);
  i2s_set_frequency(SYS_CLK,MIC_HZ);
  volatile int16_t *buffer=(volatile int16_t* )SCRATCHPAD_BASE ;

  //128 KB divided by 2 bytes per channel
  const int BUFFER_SIZE=128*1024/2;
  //const int BUFFER_SIZE=300;
  int index;
  buffer[0]=2;
  buffer[1]=3;
  buffer[2]=4;
  buffer[3]=5;
  buffer[4]=6;
  buffer[5]=7;

  int sum=buffer[0]+buffer[1];
  to_host(sum);
#if 0
  //discard the first bunch of data, seems to be garbage
  printf("discarding samples ... ");

   for(int i=0;i<3*MIC_HZ ;i++){
	  i2s_get_data();
   }
  printf("done\r\n");

#endif


  while(1){
	 int buffer_overflow=0;

	 //wait for start signal
	 printf("Waiting for start signal\r\n");
	 while( getc() != '1');
	 printf("starting\r\n");

	 //capture audio data;
	 for(index=0;;){
		i2s_data_t data=i2s_get_data();
		buffer[index++]=data.left;
		buffer[index++]=data.right;

		if(! UART_RX_EMPTY()){
		  int g=getc();
		  if(g == '2'){
			 break;
		  }
		  printf("spurious getc\r\n");
		  if(g == '1'){
			 //restart capture
			 index = 0;
			 continue;
		  }
		}
		if(index>=BUFFER_SIZE){
		  while(getc() !='2');
		  buffer_overflow=1;
		  break;
		}
	 }
	 //print audio data over uart
	 int audio_clip_len=index;
	 printf("START\r\n");
	 for(index=0;index<audio_clip_len;index+=2){
		int sum=buffer[index] + buffer[index+1];
		printf("%d ",buffer[index]);
		printf("%d ",buffer[index+1]);
		printf("%d\r\n",sum);
	 }

	 printf(buffer_overflow?"OVERFLOW\r\n":"END\r\n");


  }

  return retval;
}

int handle_interrupt(long cause, long epc, long regs[32]) {
  switch(cause & 0xF) {

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

  return epc;
}
