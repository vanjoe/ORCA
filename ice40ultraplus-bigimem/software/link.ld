/*======================================================================*/
/* Proxy kernel linker script                                           */
/*======================================================================*/
/* This is the linker script used when building the proxy kernel. */

/*----------------------------------------------------------------------*/
/* Setup                                                                */
/*----------------------------------------------------------------------*/

/* The OUTPUT_ARCH command specifies the machine architecture where the
   argument is one of the names used in the BFD library. More
   specifically one of the entires in bfd/cpu-mips.c */

OUTPUT_ARCH( "riscv" )
MEMORY
{
 BOOTMEM : ORIGIN = 0, LENGTH = 1K
 IMEM : ORIGIN = 64K, LENGTH = 64K
 DMEM : ORIGIN = 128K, LENGTH = 64K
}
/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/
ENTRY(_start)

SECTIONS
{

  /* text: test code section */
  .init . :
  {
	  *(.init)
  }>BOOTMEM
  .text :
  {
    *(.text)
  }>IMEM
  /* data segment */
  .rodata : { *(.rodata) }>DMEM
  .data : { *(.data) }>DMEM

  .sdata : {
    _gp = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }>DMEM

  _bss_start = .;
  /* bss segment */
  .sbss : {
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }>DMEM
  .bss : { *(.bss) }>DMEM
  _bss_end = .;
  /* End of uninitalized data segement */
  _end = .;

  _end_of_memory = 128K + 64K;

  _scratchpad_base = 0x08000000;
}
