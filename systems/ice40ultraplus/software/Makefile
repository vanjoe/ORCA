#define C_MAIN as env or in config.mk to override test
#define C_LINK as env or in config.mk to add additional sources to
#link against
-include config.mk

ifndef ORCA_TEST
C_MAIN ?= main.c
C_SRCS += $(C_MAIN)
C_SRCS += $(C_LINK)
C_SRCS += vbx_api.c orca_printf.c
AS_SRCS += min-crt.S
else #ifndef ORCA_TEST
C_SRCS += orca_printf.c orca_exceptions.c
AS_SRCS += full-crt.S
endif #else #ifndef ORCA_TEST

C_SRCS += uart.c

## Common ORCA software build script and parameters to pass to it
USE_LVE       := TRUE
EXTRA_C_FLAGS += -mno-div
ORCA_ROOT     ?= ../../..
C_DEPS        += sys_clk.h
TARGET        ?= test
include $(ORCA_ROOT)/software/software.mk



#For including the system clock time
SYS_CLK_FREQ :=(($(shell sed -n 's/.*USE_PLL *\([0-9]\)/\1/p' ../ice40ultraplus_syn.prj)+1)*8000000)
SYS_CLK_TEMPLATE := sys_clk.h.template
SYS_CLK_TEMP     := sys_clk.h.temp
sys_clk.h::
	@if [ ! -e $@ ]; then touch $@; fi
	@sed "s/YOUR_SYS_CLK_HERE/$(SYS_CLK_FREQ)/g" $(SYS_CLK_TEMPLATE) > $(SYS_CLK_TEMP)
	@diff -q $(SYS_CLK_TEMP) $@; if [ $$? != 0 ]; then cp $(SYS_CLK_TEMP) $@; echo "New key file $@ created.  Contents:"; cat $@; fi
	@rm -f $(SYS_CLK_TEMP)

golden.c: ../golden.bin
	rm -f $@
	echo "#include <stdint.h>" > $@
	echo "const int      golden_size = `du -b ../golden.bin | sed 's/\([0-9]*\).*/\1/g'`;" >> $@
	echo "const uint16_t golden_BSD_checksums[] = {" >> $@
	split -b 65536 ../golden.bin golden.bin.
	for chunk in $$(ls golden.bin.*); do sum $$chunk | sed 's/[^0-9].*/,/g' >> $@; done
	rm -f golden.bin.*
	echo "};" >> $@

.phony:all clean
ifndef FORMAT
FORMAT=elf
endif
all: $(TARGET).$(FORMAT)

clean:
	rm -rf sys_clk.h golden.bin.*

-include $(wildcard obj/*.d)
