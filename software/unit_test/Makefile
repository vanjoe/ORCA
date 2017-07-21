all:

RISCV_TOOLS_DIR=$(abspath ../../tools/riscv-toolchain/riscv-tools)
RISCV_TESTS_DIR=$(RISCV_TOOLS_DIR)/riscv-tests
RISCV_ENV_DIR=$(RISCV_TESTS_DIR)/env/p

ARCH=rv32im
LVE_EXT=xlve
PREFIX=riscv32-unknown-elf-
CC=$(PREFIX)gcc
OBJDUMP=$(PREFIX)objdump
TEST_ASM=consecutive_instr.S
TEST_C=simple_c_test.c vbx_test.c interrupt_test.c cmov_test.c

TEST_ASM_ELF=$(addsuffix .elf,$(basename $(TEST_ASM)))
TEST_C_ELF=$(addsuffix .elf,$(basename $(TEST_C)))

C_FLAGS=-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -march=$(ARCH) -Wa,-march=$(ARCH)$(LVE_EXT) -Wall
INCLUDE_DIRS:=$(RISCV_ENV_DIR) $(RISCV_TESTS_DIR)/isa/macros/scalar ../

INCLUDE_DIRS:=$(addprefix -I,$(INCLUDE_DIRS))
LINK_FILE=link.ld

$(TEST_ASM_ELF): %.elf : %.S | $(RISCV_ENV_DIR)
	$(CC) $(C_FLAGS)  $(INCLUDE_DIRS) -T$(LINK_FILE) $^ -o $@
	$(OBJDUMP) -D $@ > $*.dump

$(TEST_C_ELF): %.elf : %.c crt.S | $(RISCV_ENV_DIR)
	$(CC) $(C_FLAGS) -O2 $(INCLUDE_DIRS) -T$(LINK_FILE) $^ -o $@
	$(OBJDUMP) -D $@ > $*.dump

all:$(TEST_ASM_ELF) $(TEST_C_ELF)

clean:
	rm -rf $(TEST_ASM_ELF) $(TEST_C_ELF)
