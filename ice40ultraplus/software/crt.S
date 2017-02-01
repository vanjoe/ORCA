
.section ".init"

.global _start
_start:
		  /*set gp */
		  la gp, _gp
		  /*set sp*/
		  la sp, _end_of_memory
		  jal main
1:		  j 1b
