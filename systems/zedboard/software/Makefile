#Optionally add sources here/set SW_PROJECT variable
-include config.mk
-include ../config.mk

all:
AS_SRCS += crt.S
C_SRCS  += uart.c

ifeq ($(SW_PROJ), dhrystone)
  C_SRCS  += dhry_1.c dhry_2.c printf.c malloc.c orca_time.c
else ifeq ($(SW_PROJ), cache_test)
  AS_SRCS += cache_test.S
  C_SRCS  += cache_test_main.c
else ifeq ($(C_SRCS), uart.c)
  C_SRCS  += hello_world.c
endif

#These should come from the BSP
JTAG_RESET_BASE_ADDRESS ?= 0x40000000
ifdef RESET_VECTOR
RESET_VECTOR_HEX := $(shell printf "0x%08X" $(RESET_VECTOR))
ifeq ($(RESET_VECTOR_HEX), 0xB0000000)
IDRAM_BASE_ADDRESS      ?= 0xB0000000
JTAG_IDRAM_BASE_ADDRESS ?= 0xA0000000
else #ifeq(RESET_VECTOR_HEX, 0xB0000000)
IDRAM_BASE_ADDRESS      ?= $(RESET_VECTOR_HEX)
JTAG_IDRAM_BASE_ADDRESS ?= $(RESET_VECTOR_HEX)
endif #else #ifeq(RESET_VECTOR_HEX, 0xB0000000)
else #ifdef RESET_VECTOR
IDRAM_BASE_ADDRESS      ?= 0xA0000000
JTAG_IDRAM_BASE_ADDRESS ?= 0xA0000000
endif #else #ifdef RESET_VECTOR
IDRAM_LENGTH            ?= 0x00020000


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

$(LD_SCRIPT)::
	$(MAKE) -C ../ link.ld

$(TARGET).elf: $(C_OBJ_FILES) $(S_OBJ_FILES) $(LD_SCRIPT)
	$(CC) -T $(LD_SCRIPT) $(S_OBJ_FILES)  $(C_OBJ_FILES)  -o $@ $(LD_FLAGS)
$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) -D $(TARGET).elf > $(TARGET).dump
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@
$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex $< $@
$(TARGET).mem: $(TARGET).bin
	 head -c $$((0x100)) /dev/zero | cat - $< | xxd -g1 -c4 | awk '{print $$5$$4$$3$$2}' > $@
hex_to_coe: hex_to_coe.cpp
	g++ hex_to_coe.cpp -o hex_to_coe
$(TARGET).coe: $(TARGET).hex hex_to_coe
	./hex_to_coe $(IDRAM_BASE_ADDRESS) `printf "0x%08X" $$(($(IDRAM_BASE_ADDRESS) + $(IDRAM_LENGTH) - 1))`

ifndef FORMAT
FORMAT=elf
endif
.PHONY: all
all: $(TARGET).$(FORMAT) $(TARGET).hex $(TARGET).mem $(TARGET).coe $(TARGET).dump

.PHONY: clean
clean:
	rm -rf obj $(TARGET).elf $(TARGET).dump $(TARGET).bin $(TARGET).hex $(TARGET).mif $(TARGET).mem hex_to_coe

-include $(wildcard obj/*.d)

.DELETE_ON_ERROR:
