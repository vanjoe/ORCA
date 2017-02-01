#define C_MAIN as env or in config.mk to override test
#define C_LINK as env or in config.mk to add additional sources to
#link against
-include config.mk
C_MAIN?=main.c
OBJDUMP_STYLE?=--disassemble-all
ARCH?=rv32im
LVE_EXT=xlve
RISCV_OLEVEL?=-Os
RISCV_CFLAGS?=

all:
AS_SRCS=crt.S

C_SRCS=
C_SRCS+=$(C_MAIN)
C_SRCS+=$(C_LINK)
C_SRCS+= vbx_api.c printf.c time.c uart.c


C_OBJ_FILES=$(addprefix obj/,$(addsuffix .o, $(C_SRCS)))
S_OBJ_FILES=$(addprefix obj/,$(addsuffix .o, $(AS_SRCS)))

CROSS_COMPILE=riscv32-unknown-elf-
CC=$(CROSS_COMPILE)gcc
OBJCOPY=$(CROSS_COMPILE)objcopy
OBJDUMP=$(CROSS_COMPILE)objdump
CFLAGS=-march=$(ARCH) -Wa,-march=$(ARCH)$(LVE_EXT) $(RISCV_OLEVEL) -MD -Wall -std=gnu99 $(RISCV_CFLAGS) -Wmisleading-indentation -mno-div
LD_FLAGS= -static -nostartfiles -march=$(ARCH)

TARGET=test

#For including the system clock time
SYS_CLK_FREQ :=(($(shell sed -n 's/.*USE_PLL \([0-9]\)/\1/p' ../ice40ultraplus_syn.prj)+1)*8000000)
SYS_CLK_TEMPLATE := sys_clk.h.template
SYS_CLK_TEMP     := sys_clk.h.temp
sys_clk.h::
	@if [ ! -e $@ ]; then touch $@; fi
	@sed "s/YOUR_SYS_CLK_HERE/$(SYS_CLK_FREQ)/g" $(SYS_CLK_TEMPLATE) > $(SYS_CLK_TEMP)
	@diff -q $(SYS_CLK_TEMP) $@; if [ $$? != 0 ]; then cp $(SYS_CLK_TEMP) $@; echo "New key file $@ created.  Contents:"; cat $@; fi
	@rm -f $(SYS_CLK_TEMP)


$(C_OBJ_FILES) $(S_OBJ_FILES) : | obj/
obj/:
	mkdir -p obj/

$(C_OBJ_FILES): obj/%.c.o : %.c sys_clk.h
	$(CC) $(CFLAGS) -c $< -o $@

# obj/printf.c.o: obj/%.c.o : %.c sys_clk.h
# 	$(CC) -m32 -march=RV32IXmxp $(RISCV_OLEVEL) -MD -Wall -std=gnu99 $(RISCV_CFLAGS) -Wmisleading-indentation -c $< -o $@

$(S_OBJ_FILES): obj/%.S.o : %.S
	$(CC) $(CFLAGS) -c $< -o $@

LD_SCRIPT=link.ld
LIBC=

$(TARGET).elf: $(C_OBJ_FILES) $(S_OBJ_FILES) $(LD_SCRIPT)
	$(CC) -T $(LD_SCRIPT) $(S_OBJ_FILES)  $(C_OBJ_FILES)  -o $@ $(LD_FLAGS)
	$(OBJDUMP) $(OBJDUMP_STYLE) test.elf > test.dump
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).mem: $(TARGET).bin
	 head -c $$((0x000)) /dev/zero | cat - $< | xxd -g1 -c4 | awk '{print $$5$$4$$3$$2}' > $@

.phony:all clean
ifndef FORMAT
FORMAT=elf
endif
all: $(TARGET).$(FORMAT)

clean:
	rm -rf obj test.elf test.dump test.bin test.hex test.mif test.mem sys_clk.h

-include $(wildcard obj/*.d)
