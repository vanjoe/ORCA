
#define MEIMASK 0x7C0
#define MEIPEND 0x7C0

#define MSTATUS_MPIE (1<<7)
#define MSTATUS_MIE (1<<3)
#include "bsp.h"
#include <stdlib.h>
#include "orca_exceptions.h"
#include "orca_csrs.h"

volatile static int*  INT_GEN_REGISTER = (volatile int*)(0x01000000);

static inline unsigned get_time() {
	int tmp;
	csrr(time,tmp);
	return tmp;
}
static inline void delay_cycles(int cycles) {
	unsigned start = get_time();
	while(get_time() - start < cycles){
	}
}


static inline void schedule_interrupt(int cycles)
{
	//when an integer is written to the INT_GEN_REGISTER,
	//an iterrupt will be triggered that many cycles from now.
	//if the number is negative, no interrupt will occur

	// Note that an interrupt must clear flush the popeling, before the
	//processor can be interrupted, so if the next instruction disables
	//interrupts, the interrupt will probably not be taken


	*INT_GEN_REGISTER = cycles;
}

volatile int interrupt_count=0;
void handle_interrupt(int intnum, void* cnxt)
{

	interrupt_count++;
	schedule_interrupt(-1);//clear interrupt
	return ;
}



int test_2()
{
	int before=interrupt_count;

	//enable interrupts
	csrw(mstatus,MSTATUS_MIE);
	csrw(MEIMASK,1);
	//send interrupt
	schedule_interrupt(0);
	delay_cycles(32);

	//disable interrupts
	csrw(mstatus,0);
	//check if interrupt was signalled
	return before+1 != interrupt_count;

}

int test_3()
{
	int before=interrupt_count;

	//clear interrupts
	csrw(mstatus,0);
	csrw(MEIMASK,1);
	//send interrupt
	schedule_interrupt(0);
	delay_cycles(32);
	//disable interrupts
	csrw(mstatus,0);
	schedule_interrupt(-1);
	//check if interrupt was signalled
	return before != interrupt_count;

}


int test_4()
{
	int before=interrupt_count;

	//clear interrupts
	csrw(mstatus,MSTATUS_MIE);
	csrw(MEIMASK,0);
	//send interrupt
	schedule_interrupt(0);
	delay_cycles(32);
	//disable interrupts
	csrw(mstatus,0);
	schedule_interrupt(-1);
	//check if interrupt was signalled
	return before != interrupt_count;

}

int test_5()
{
	int isa_spec;
	csrr(misa,isa_spec);
	//if this test fails it will hang
	if(!(isa_spec & (1<<23))){
		//VCP is disabled, skip this test
		return 0;
	}

	csrw(mstatus,MSTATUS_MIE);
	csrw(MEIMASK,-1);
	asm(" vbx_set_vl %0,%0,%0"::"r"(1));

	//one of these interrupts should interrupt just
	//when one half of the instruction has been fetched
	//but not the other.
	for(int cycles=0;cycles<20;cycles++){
		schedule_interrupt(cycles);
		//send interrupt
		delay_cycles(3);
		asm("vor.vvwwwuuu x0,x0,x0");//64bit instructions
	}
	//disable interrupts
	csrw(mstatus,0);
	schedule_interrupt(-1);

	//if the test has not hung before this, the test has passed
	return 0;
}

int test_6()
{
	//make sure interrupts don't take an
	//excessive amount of time to be triggered
	int before=interrupt_count;

	//clear interrupts
	csrw(mstatus,MSTATUS_MIE);
	csrw(MEIMASK,1);
	//send interrupt
	schedule_interrupt(0);
	int timeout=8;
	while((before+1) > interrupt_count){
		if(--timeout == 0 ){break;};
	}
	//disable interrupts
	schedule_interrupt(-1);
	csrw(mstatus,0);
	//if timeout > 0 then the loop did not timeout
	if (timeout==0){
		return 1;
	}
	return 0;

}

int test_init()
{
	return orca_register_interrupt_handler(1,handle_interrupt,NULL);

}
typedef int (*test_func)() ;
test_func test_functions[] ={
	test_init,
	test_2,
	test_3,
	test_4,
	test_5,
	test_6,
	(void*)0
};
