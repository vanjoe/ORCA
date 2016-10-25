
#define _stringify(a) #a
#define stringify(a) _stringify(a)
#define csrr(name,dst) asm volatile ("csrr %0 ," stringify(name) :"=r"(dst) )
#define csrw(name,src) asm volatile ("csrw " stringify(name) ",%0" ::"r"(src) )

#define MEIMASK 0x7C0
#define MEIPEND 0x7C0

#define MSTATUS_MIE 0x8
#define PIO_REGISTER ((volatile int*)(0x01000000))

volatile int interrupt_count;
void* handle_interrupt(int cause,void* pc)
{
	interrupt_count++;
	*PIO_REGISTER = 0; //clear interrupt
	return pc;
}
#define TEST_ATTR static __attribute__((noinline))
TEST_ATTR int test_2()
{
	int before=interrupt_count;

	//enable interrupts
	csrw(mstatus,MSTATUS_MIE);
	csrw(MEIMASK,1);
	//send interrupt
	*PIO_REGISTER = 1;
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
	*PIO_REGISTER = 1;
	//disable interrupts
	csrw(mstatus,0);
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
	*PIO_REGISTER = 1;
	//disable interrupts
	csrw(mstatus,0);
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
	*PIO_REGISTER = 1;
	//disable interrupts
	csrw(mstatus,0);
	//check if interrupt was signalled
	return before == interrupt_count ? 0: 1;

}



//this macro runs the test, and returns the test number on failure
#define do_test(i) do{if ( test_##i () ) return i;}while(0)

int main()
{
	//disable interrupts
	csrw(mstatus,0);

	do_test(2);
	do_test(3);
	do_test(4);
	do_test(5);
	return 0;

}
