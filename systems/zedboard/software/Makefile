#Optionally add sources here/set ORCA_TEST/SW_PROJ variables

-include config.mk
-include ../config.mk
TARGET ?= test

ifndef ORCA_TEST
ifeq ($(SW_PROJ), cache_test)
  AS_SRCS += cache_test.S
  C_SRCS  += cache_test_main.c orca_interrupts.c orca_memory.c orca_malloc.c
else
  C_SRCS  ?= hello_world.c
endif
endif #ifndef ORCA_TEST

.PHONY: all
all: ../orca_defines.h

C_SRCS  += orca_printf.c orca_exceptions.c
AS_SRCS += full-crt.S

#These should come from the BSP
ifdef RESET_VECTOR
RESET_VECTOR_HEX        := $(shell printf "0x%08X" $(RESET_VECTOR))
IDRAM_BASE_ADDRESS      ?= $(RESET_VECTOR_HEX)
else #ifdef RESET_VECTOR
IDRAM_BASE_ADDRESS      ?= 0xA0000000
endif #else #ifdef RESET_VECTOR
IDRAM_LENGTH            ?= 0x00020000

## Common ORCA software build script and parameters to pass to it
RISCV_OLEVEL ?= -O3
ORCA_ROOT ?= ../../..
include $(ORCA_ROOT)/software/software.mk

../orca_defines.h:
	$(MAKE) -C .. orca_defines.h

.PHONY: all
all: $(TARGET).elf $(TARGET).coe $(TARGET).dump $(TARGET).ihex

ORCA_TESTS =$(addsuffix .elf,$(notdir $(abspath $(dir $(wildcard $(ORCA_ROOT)/software/orca-tests/*/Makefile )))))

PWD=$(shell pwd)
$(ORCA_TESTS)::
	make -C $(ORCA_ROOT)/software/orca-tests/$(basename $@) $(PWD)/$@ OUTPUT_DIR=$(PWD) LD_SCRIPT=$(PWD)/$(LD_SCRIPT)  RISCV_OLEVEL=-O3

$(ORCA_TESTS:.elf=.qex):%.qex : %.bin
	python $(ORCA_ROOT)/tools/bin2hex.py $< -a 0x0 > $@
$(ORCA_TESTS:.elf=.bin):%.bin : %.elf
	$(CROSS_COMPILE)objcopy -O binary $< $@
$(ORCA_TESTS:.elf=.ihex):%.ihex : %.elf
	$(CROSS_COMPILE)objcopy -O ihex $< $@
$(ORCA_TESTS:.elf=.dump): %.dump : %.elf
	$(CROSS_COMPILE)objdump  --disassemble-all -Mnumeric,no-aliases $^ > $@


$(ORCA_TESTS:.elf=.coe): %.coe : %.ihex  $(ORCA_ROOT)/tools/hex_to_coe
	$(ORCA_ROOT)/tools/hex_to_coe $< $@ 0x$(shell nm --numeric-sort $*.elf | awk '{print $$1}' | head -n1) 	0x$(shell nm --numeric-sort $*.elf | awk '{print $$1}' | tail -n1)

all: $(ORCA_TESTS:.elf=.qex)  $(ORCA_TESTS:.elf=.ihex) $(ORCA_TESTS:.elf=.dump)

clean:clean-orca-test
clean-orca-test:
	rm -f $(addsuffix *,$(basename $(ORCA_TESTS)))
