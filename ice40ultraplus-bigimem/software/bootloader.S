
#include "system.h"

.section ".init"
nop


.ALIGN (9)
_boot:
		  /*set gp */
		  la gp, _gp
		  /*set sp*/
		  la sp, _end_of_memory

		  li a1, '\n'
		  jal uart_putc
		  li a1, '\n'
		  jal uart_putc
		  li a1, '\r'
		  jal uart_putc

		  li a1, 't'
		  jal uart_putc

		  /*load flash contorller address*/
		  li s0, FLASH_CTRL_ADDR
		  /*chech if still initializing*/
		  li s1, 0x80000000
1:		  lw s2, 0xC(s0)
		  and s2,s2,s1
		  li a1, 'w'
		  jal uart_putc
		  bnez s2,1b
		  li a1, 'e'
		  jal uart_putc

		  /*since flash controller done initializing*/
		  /*now tranfer to imem */

		  /* Flash Read Address */
		  li s2,0
		  sw s2,0(s0)
		  li s2,IMEM_ADDR
		  sw s2,4(s0)
		  li s2,IMEM_SIZE
		  sw s2,8(s0)
		  nop
		  li a1, 's'
		  jal uart_putc

		  /*wait for transfer done*/
1:		  lw s2, 0xC(s0)
		  bnez s2,1b
		  li a1, 't'
		  jal uart_putc
		  /*now transfer to dmem */
		  li s2,0+65536
		  sw s2,0(s0)
		  li s2,DMEM_ADDR
		  sw s2,4(s0)
		  li s2,DMEM_SIZE
		  sw s2,8(s0)
		  nop
		  li a1, '!'
		  jal uart_putc

		  /*wait for transfer done*/
1:		  lw s2, 0xC(s0)
		  bnez s2,1b
		  li a1, '!'
		  jal uart_putc
		  li a1, '\r'
		  jal uart_putc
		  li a1, '\n'
		  jal uart_putc

		  /* jump to _start to initialized CRT*/
		  j _start

.global _start
_start:
		  /*set gp */
		  la gp, _gp
		  /*set sp*/
		  la sp, _end_of_memory
		  jal main
1:		  j 1b

/* put this here so we can use it during boot*/
uart_putc:
		  li     a5, UART_ADDR
		  li      a4,3
		  sw      a4,12(a5)
1:		  lw      a4,20(a5)
		  andi    a4,a4,32
		  beqz    a4,1b
		  sw      a1,0(a5)
		  ret
