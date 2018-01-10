#Optionally add sources here/set SW_PROJECT variable
-include config.mk
-include ../config.mk

all:
AS_SRCS=crt.S

C_SRCS=
C_SRCS+=hello_world.c
C_SRCS+=printf.c


C_OBJ_FILES=$(addprefix obj/,$(addsuffix .o, $(C_SRCS)))
S_OBJ_FILES=$(addprefix obj/,$(addsuffix .o, $(AS_SRCS)))

CROSS_COMPILE=riscv32-unknown-elf-
CC=$(CROSS_COMPILE)gcc
OBJCOPY=$(CROSS_COMPILE)objcopy
OBJDUMP=$(CROSS_COMPILE)objdump
ARCH=rv32im
CFLAGS= -O2 -fno-delete-null-pointer-checks -g -march=$(ARCH) -MD -Wall -std=gnu99
LD_FLAGS= -march=$(ARCH) -static -nostartfiles

TARGET=test

$(C_OBJ_FILES) $(S_OBJ_FILES) : | obj/
obj/:
	mkdir -p obj/

$(C_OBJ_FILES): obj/%.c.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(S_OBJ_FILES): obj/%.S.o : %.S
	$(CC) $(CFLAGS) -c $< -o $@

LD_SCRIPT=../link.ld
LIBC=

$(TARGET).elf: $(C_OBJ_FILES) $(S_OBJ_FILES) $(LD_SCRIPT)
	$(CC) -T $(LD_SCRIPT) $(S_OBJ_FILES)  $(C_OBJ_FILES)  -o $@ $(LD_FLAGS)
	$(MAKE) $(TARGET).dump
 $(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) -D $(TARGET).elf > $(TARGET).dump
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@
$(TARGET).hex: $(TARGET).bin
	python ../../../tools/bin2hex.py -o $@ $<
$(TARGET).mem: $(TARGET).bin
	 head -c $$((0x100)) /dev/zero | cat - $< | xxd -g1 -c4 | awk '{print $$5$$4$$3$$2}' > $@

ifndef FORMAT
FORMAT=elf
endif
.PHONY: all
all: $(TARGET).$(FORMAT) $(TARGET).mem

.PHONY: clean
clean:
	rm -rf obj *.elf *.dump *.bin *.mif *.mem *.hex *~ \#*

-include $(wildcard obj/*.d)

.DELETE_ON_ERROR:
