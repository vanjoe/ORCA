#include "printf.h"
#include "uart.h"
#include "test_passfail.h"
#include "handle_interrupt.h"

#define _stringify(a) #a
#define stringify(a) _stringify(a)
#define csrr(name,dst) asm volatile ("csrr %0 ," stringify(name) :"=r"(dst) )
#define csrw(name,src) asm volatile ("csrw " stringify(name) ",%0" ::"r"(src) )
#define nop asm volatile ("nop" )

#define MEIMASK 0x7C0
#define MEIPEND 0x7C0

#define MSTATUS_MIE 0x8


#define TEST_ATTR static __attribute__((noinline))

extern int interrupt_count;

TEST_ATTR int test_2()
{
	int before=interrupt_count;

	//enable interrupts
	csrw(mstatus,MSTATUS_MIE);
	csrw(MEIMASK,1);
	//send interrupt
	schedule_interrupt(0);
	nop;nop;nop;//poor mans pipeline flush

	//disable interrupts
	csrw(mstatus,0);
	//check if interrupt was signalled
	return before+1 == interrupt_count ? 0: 1;

}

TEST_ATTR int test_3()
{
	int before=interrupt_count;

	//clear interrupts
	csrw(mstatus,0);
	csrw(MEIMASK,1);
	//send interrupt
	schedule_interrupt(0);
	nop;nop;nop;//poor mans pipeline flush
	//disable interrupts
	csrw(mstatus,0);
	schedule_interrupt(-1);
	//check if interrupt was signalled
	return before == interrupt_count ? 0: 1;

}


TEST_ATTR int test_4()
{
	int before=interrupt_count;

	//clear interrupts
	csrw(mstatus,MSTATUS_MIE);
	csrw(MEIMASK,0);
	//send interrupt
	schedule_interrupt(0);
	nop;nop;nop;//poor mans pipeline flush
	//disable interrupts
	csrw(mstatus,0);
	schedule_interrupt(-1);
	//check if interrupt was signalled
	return before == interrupt_count ? 0: 1;

}

TEST_ATTR int test_5()
{
	int before=interrupt_count;

	//clear interrupts
	csrw(mstatus,MSTATUS_MIE);
	csrw(MEIMASK,0);
	//send interrupt
	schedule_interrupt(0);
	nop;nop;nop;//poor mans pipeline flush
	//disable interrupts
	csrw(mstatus,0);
	schedule_interrupt(-1);
	//check if interrupt was signalled
	return before == interrupt_count ? 0: 1;

}

TEST_ATTR int interrupt_latency_test(int cycles)
{
	int before=interrupt_count;

	//clear interrupts
	csrw(mstatus,MSTATUS_MIE);
	csrw(MEIMASK,1);
	//send interrupt
	schedule_interrupt(cycles);
	int timeout=80;
	while((before+1) > interrupt_count){
		if(--timeout == 0 ){break;};
	}
	//disable interrupts
	schedule_interrupt(-1);
	csrw(mstatus,0);
	//if timeout > 0 then the loop did not timeout
	return timeout>0 ? 0 :1;

}




//this macro runs the test, and returns the test number on failure
#define do_test(i) do { if ( test_##i () ) { test_fail(); return i; } } while(0)

int main()
{
	//disable interrupts
	csrw(mstatus,0);

	do_test(2);
	do_test(3);
	do_test(4);
	do_test(5);

	int i;
	for(i = 0; i < 15; i++) {
		if (interrupt_latency_test(i)) {
			test_fail();
			return i+6;
		}
	}

	test_pass();
	return 0;

}
