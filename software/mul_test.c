int main(void)
{
  volatile register int test asm ("a5");
  test = 0;
  test += 1;
  return 1;
}


int handle_trap(long cause,long epc, long regs[32])
{
	//spin forever
	for(;;);
}
