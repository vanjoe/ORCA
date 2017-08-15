#include "printf.h"
#include "uart.h"
#include "test_passfail.h"
#include "handle_interrupt.h"

int test_2()
{

  //Tests all return 0 on success, non-zero on failure
  return 0;
}

//this macro runs the test, and returns the test number on failure
#define do_test(i) do { if ( test_##i () ) { test_fail(); return i; } } while(0)

int main()
{

  do_test(2);

	test_pass();
  return 0;

}

