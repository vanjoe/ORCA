.section .init

.globl _start
_start:
	la gp, _gp
	la sp, _end_of_memory
	jal main
	mv t3,a0
	nop
	nop
	ecall
1:
	j 1b
