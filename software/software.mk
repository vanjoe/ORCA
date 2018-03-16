#Makefile for ORCA software
#define USE_LVE before including to add LVE/MXP support
#define ORCA_TEST before including to build software/orca-tests/$(ORCA_TEST)
.PHONY: all
all:

ifdef ORCA_TEST
vpath %.c $(ORCA_ROOT)/software/orca-tests/
C_SRCS += orca-test.c
endif #ifdef ORCA_TEST

TARGET     ?= $(shell pwd | xargs basename)
ifdef OUTPUT_DIR
OUTPUT_PREFIX ?= $(OUTPUT_DIR)/
endif #ifdef OUTPUT_DIR
OBJDIR     ?= $(OUTPUT_PREFIX)obj

CROSS_COMPILE ?= riscv32-unknown-elf-
CC            = $(CROSS_COMPILE)gcc
OBJCOPY       = $(CROSS_COMPILE)objcopy
OBJDUMP       = $(CROSS_COMPILE)objdump

ORCA_ROOT ?= ../../..

#Include assembly (min-crt.S or full-crt.S) from risc-v/software
vpath %.S $(ORCA_ROOT)/software

#Include software from orca_lib
vpath %.c $(ORCA_ROOT)/software/orca_lib

ifdef USE_LVE
ARCH ?= rv32imxlve
#Include VBX/LVE software from vbx_lib
vpath %.c $(ORCA_ROOT)/software/vbx_lib
INCLUDE_DIRS += $(ORCA_ROOT)/software/vbx_lib
else #ifdef USE_LVE
ARCH ?= rv32im
endif #else #ifdef USE_LVE

RISCV_OLEVEL ?= -O2

RISCV_TESTS_DIR ?= $(ORCA_ROOT)/software/riscv-tests
RISCV_ENV_DIR   ?= $(RISCV_TESTS_DIR)/env
ENCODING_H      ?= $(RISCV_TESTS_DIR)/env/encoding.h

INCLUDE_DIRS += $(RISCV_ENV_DIR)  $(RISCV_TESTS_DIR)/isa/macros/scalar . $(OUTPUT_PREFIX).. $(ORCA_ROOT)/software $(ORCA_ROOT)/software/orca_lib
INCLUDE_STRING := $(addprefix -I,$(INCLUDE_DIRS))

CFLAGS   ?= -march=$(ARCH) $(RISCV_OLEVEL) -MD -Wall -std=gnu99 -Wmisleading-indentation $(EXTRA_CFLAGS) $(INCLUDE_STRING)
LD_FLAGS ?= -march=$(ARCH) -static -nostartfiles $(EXTRA_LDFLAGS)

C_OBJ_FILES := $(addprefix $(OBJDIR)/,$(addsuffix .o, $(notdir $(C_SRCS))))

S_OBJ_FILES := $(addprefix $(OBJDIR)/,$(addsuffix .o, $(notdir $(AS_SRCS))))

START_ADDRESS ?= 0x100

$(RISCV_ENV_DIR) $(ENCODING_H):
	git submodule update --init --recursive $(RISCV_TESTS_DIR)


LD_SCRIPT ?= $(OUTPUT_PREFIX)../link.ld
$(LD_SCRIPT)::
	$(MAKE) -C $(OUTPUT_PREFIX)../ link.ld

$(C_OBJ_FILES) $(S_OBJ_FILES): $(ENCODING_H)

$(C_OBJ_FILES) $(S_OBJ_FILES): | $(OBJDIR)/
$(OBJDIR)/:
	mkdir -p $(OBJDIR)/

$(C_OBJ_FILES): $(OBJDIR)/%.c.o: %.c $(C_DEPS)
	$(CC) $(CFLAGS) -c $< -o $@

$(S_OBJ_FILES): $(OBJDIR)/%.S.o : %.S
	$(CC) $(CFLAGS) -c $< -o $@

$(OUTPUT_PREFIX)$(TARGET).elf: $(C_OBJ_FILES) $(S_OBJ_FILES) $(LD_SCRIPT)
	$(CC) -T$(LD_SCRIPT) $(S_OBJ_FILES) $(C_OBJ_FILES) -o $@ $(LD_FLAGS)
$(OUTPUT_PREFIX)$(TARGET).dump: $(OUTPUT_PREFIX)$(TARGET).elf
	$(OBJDUMP) -D $(OUTPUT_PREFIX)$(TARGET).elf > $(OUTPUT_PREFIX)$(TARGET).dump
$(OUTPUT_PREFIX)$(TARGET).bin: $(OUTPUT_PREFIX)$(TARGET).elf
	$(OBJCOPY) -O binary $< $@
$(OUTPUT_PREFIX)$(TARGET).ihex: $(OUTPUT_PREFIX)$(TARGET).elf
	$(OBJCOPY) -O ihex $< $@
$(OUTPUT_PREFIX)$(TARGET).hex: $(OUTPUT_PREFIX)$(TARGET).bin
	python ../../../tools/bin2hex.py -o $@ $<
$(OUTPUT_PREFIX)$(TARGET).qex: $(OUTPUT_PREFIX)$(TARGET).bin
	python ../../../tools/bin2hex.py -o $@ $<
$(OUTPUT_PREFIX)$(TARGET).mem: $(OUTPUT_PREFIX)$(TARGET).bin
	 head -c $$(( $(START_ADDRESS))) /dev/zero | cat - $< | xxd -g1 -c4 | awk '{print $$5$$4$$3$$2}' > $@
$(ORCA_ROOT)/tools/hex_to_coe: $(ORCA_ROOT)/tools/hex_to_coe.cpp
	g++ $< -o $@
$(OUTPUT_PREFIX)$(TARGET).coe: $(OUTPUT_PREFIX)$(TARGET).ihex $(ORCA_ROOT)/tools/hex_to_coe
	@if [[ -z "$(IDRAM_BASE_ADDRESS)" || -z "$(IDRAM_LENGTH)" ]]; then echo "ERROR: Please define IDRAM_BASE_ADDRESS $(IDRAM_BASE_ADDRESS) and IDRAM_LENGTH $(IDRAM_LENGTH) to make $(OUTPUT_PREFIX)$(TARGET).coe"; exit 1; fi
	$(ORCA_ROOT)/tools/hex_to_coe $< $@ $(IDRAM_BASE_ADDRESS) $(shell printf "0x%08X" $$(($(IDRAM_BASE_ADDRESS) + $(IDRAM_LENGTH) - 1)))


-include $(wildcard $(OBJDIR)/*.d)

.PHONY: clean
clean: common_clean
.PHONY: common_clean
common_clean:
	rm -rf $(OBJDIR) $(OUTPUT_PREFIX)$(TARGET).elf $(OUTPUT_PREFIX)$(TARGET).dump $(OUTPUT_PREFIX)$(TARGET).bin $(OUTPUT_PREFIX)$(TARGET).hex $(OUTPUT_PREFIX)$(TARGET).qex $(OUTPUT_PREFIX)$(TARGET).ihex $(OUTPUT_PREFIX)$(TARGET).coe $(OUTPUT_PREFIX)$(TARGET).mif $(OUTPUT_PREFIX)$(TARGET).mem *~ \#*

.PHONY: pristine
pristine: common_pristine clean
.PHONY: common_pristine
common_pristine:
	rm -rf *.elf *.dump *.bin *.hex *.ihex *.coe *.mif *.mem

.DELETE_ON_ERROR:


####
# riscv-tests
#####
RISCV_ARCHS=rv32ui rv32mi rv32um
RISCV_TEST_DIR=$(ORCA_ROOT)/software/riscv-tests/
RISCV_TESTS=$(basename $(foreach arch,$(RISCV_ARCHS),\
	$(addprefix $(arch)-p-,$(notdir $(wildcard $(RISCV_TEST_DIR)/isa/$(arch)/*.S) ))))
RISCV_PHONY=$(addsuffix .phony,$(RISCV_TESTS))

$(RISCV_TESTS) : $(ORCA_ROOT)/software/orca_lib/orca_printf.c
	$(CC) -o $@ $(RISCV_TEST_DIR)/isa/$(firstword $(subst -p-, , $@))/$(lastword $(subst -p-, , $@)).S \
	$< $(INCLUDE_STRING) -nostdlib -T $(LD_SCRIPT)

$(addsuffix .qex,$(RISCV_TESTS)):%.qex : %.bin
	python $(ORCA_ROOT)/tools/bin2hex.py $< -a 0x0 > $@
$(addsuffix .bin,$(RISCV_TESTS)):%.bin : %
	$(CROSS_COMPILE)objcopy -O binary $< $@
$(addsuffix .ihex,$(RISCV_TESTS)):%.ihex : %
	$(CROSS_COMPILE)objcopy -O ihex $< $@
$(addsuffix .dump,$(RISCV_TESTS)): %.dump : %
	$(CROSS_COMPILE)objdump  --disassemble-all -Mnumeric,no-aliases $^ > $@
$(addsuffix .coe,$(RISCV_TESTS)): %.coe : %.ihex $(ORCA_ROOT)/tools/hex_to_coe
	$(ORCA_ROOT)/tools/hex_to_coe $< $@ 0x$(shell nm --numeric-sort $* | awk '{print $$1}' | head -n1) 	0x$(shell nm --numeric-sort $* | awk '{print $$1}' | tail -n1)

$(RISCV_PHONY): %.phony : %.dump %.qex %.ihex
$(ORCA_ROOT)/tools/hex_to_coe : % :%.cpp
	gcc $^ -o $@


.PHONY: $(RISCV_PHONY) riscv_tests
riscv-tests: $(RISCV_PHONY)
all: $(RISCV_PHONY)
clean : clean-riscv-test
clean-riscv-test:
	rm -f $(addsuffix *,$(RISCV_TESTS))
