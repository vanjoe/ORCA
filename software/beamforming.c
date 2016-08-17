#define SYS_CLK 50000000
#include "macros.h"
#include "vbx_cproto.h"
#include "interrupt.h"
#include "printf.h"

#define SAMPLE_RATE 48e3 // Hz
#define DISTANCE 10e3 // mm

int main() {
  

}


int tohost_exit() {
	for(;;);
}

int handle_interrupt(long cause, long epc, long regs[32]) {
  for(;;);
}
