#=======================================================================
# Makefile for riscv-tests/isa
#-----------------------------------------------------------------------

XLEN ?= 32

src_dir := .

include $(src_dir)/rv32mi/Makefrag
include $(src_dir)/rv32mi_c/Makefrag

default: all

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

ARCH=rv32im
LVE_EXT=xlve
RISCV_PREFIX ?= riscv$(XLEN)-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -march=$(ARCH) -Wa,-march=$(ARCH)$(LVE_EXT) -Wall
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassemble-all --disassemble-zeroes 


vpath %.S $(src_dir)
vpath %.c $(src_dir)

#------------------------------------------------------------
# Build assembly tests

%.dump: %
	$(RISCV_OBJDUMP) $< > $@

define compile_template_S

$$($(1)_p_tests): $(1)-p-%: $(1)/%.S
	$$(RISCV_GCC) $$(RISCV_GCC_OPTS) -I$(src_dir)/../common/env/p -I$(src_dir)/../common/macros/scalar -I$(src_dir)/../common -T$(src_dir)/../common/link.ld $$< -o $$@
$(1)_tests += $$($(1)_p_tests)

$(1)_tests_dump = $$(addsuffix .dump, $$($(1)_tests))

$(1): $$($(1)_tests_dump)

.PHONY: $(1)

tests += $$($(1)_tests)

endef

define compile_template_c

$$($(1)_p_tests): $(1)-p-%: $(1)/%.c
	$$(RISCV_GCC) $$(RISCV_GCC_OPTS) -I$(src_dir)/../common/env/p -I$(src_dir)/../common/macros/scalar -I$(src_dir)/../common -T$(src_dir)/../common/link.ld ../common/crt.S $$< -o $$@
$(1)_tests += $$($(1)_p_tests)

$(1)_tests_dump = $$(addsuffix .dump, $$($(1)_tests))

$(1): $$($(1)_tests_dump)

.PHONY: $(1)

tests += $$($(1)_tests)

endef

$(eval $(call compile_template_S,rv32mi))
$(eval $(call compile_template_c,rv32mi_c))

tests_dump = $(addsuffix .dump, $(tests))
tests_hex = $(addsuffix .hex, $(tests))

junk += $(tests) $(tests_dump) $(tests_hex) $(tests_out) $(tests32_out)

#------------------------------------------------------------
# Default

all: $(tests_dump)

#------------------------------------------------------------
# Clean up

clean:
	rm -rf $(junk)













#ARCH=rv32im
#LVE_EXT=xlve
#PREFIX=riscv32-unknown-elf-
#CC=$(PREFIX)gcc
#OBJDUMP=$(PREFIX)objdump
#TEST_ASM=consecutive_instr.S
#TEST_C=simple_c_test.c vbx_test.c interrupt_test.c cmov_test.c
#
#TEST_ASM_ELF=$(addsuffix .elf,$(basename $(TEST_ASM)))
#TEST_C_ELF=$(addsuffix .elf,$(basename $(TEST_C)))
#
#C_FLAGS=-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -march=$(ARCH) -Wa,-march=$(ARCH)$(LVE_EXT) -Wall
#INCLUDE_DIRS:=$(RISCV_ENV_DIR) $(RISCV_TESTS_DIR)/isa/macros/scalar ../
#
#INCLUDE_DIRS:=$(addprefix -I,$(INCLUDE_DIRS))
#LINK_FILE=link.ld
#
#$(TEST_ASM_ELF): %.elf : %.S | $(RISCV_ENV_DIR)
#	$(CC) $(C_FLAGS)  $(INCLUDE_DIRS) -T$(LINK_FILE) $^ -o $@
#	$(OBJDUMP) -D $@ > $*.dump
#
#$(TEST_C_ELF): %.elf : %.c crt.S | $(RISCV_ENV_DIR)
#	$(CC) $(C_FLAGS) -O2 $(INCLUDE_DIRS) -T$(LINK_FILE) $^ -o $@
#	$(OBJDUMP) -D $@ > $*.dump
#
#all:$(TEST_ASM_ELF) $(TEST_C_ELF)
#
#clean:
#	rm -rf $(TEST_ASM_ELF) $(TEST_C_ELF) *.dump
