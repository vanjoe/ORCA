all:

ARCH=rv32im
LVE_EXT=xlve
PREFIX=riscv32-unknown-elf-
CC=$(PREFIX)gcc
OBJDUMP=$(PREFIX)objdump
TEST_ASM=consecutive_instr.S
TEST_C=simple_c_test.c vbx_test.c interrupt_test.c cmov_test.c back2back_load_store_test.c

TEST_ASM_ELF=$(addsuffix .elf,$(basename $(TEST_ASM)))
TEST_C_ELF=$(addsuffix .elf,$(basename $(TEST_C)))

C_FLAGS=-static -nostartfiles -march=$(ARCH) -Wa,-march=$(ARCH)$(LVE_EXT) -Wall
RISCV_TESTS_DIR=../riscv-tests
RISCV_ENV_DIR=$(RISCV_TESTS_DIR)/env/p

INCLUDE_DIRS:=$(RISCV_ENV_DIR) $(RISCV_TESTS_DIR)/isa/macros/scalar ../

INCLUDE_DIRS:=$(addprefix -I,$(INCLUDE_DIRS))
LINK_FILE=link.ld

DEPENDS_DIR=depends
DEP_FILES=$(wildcard $(DEPENDS_DIR)/*.d)

-include $(DEP_FILES)
$(DEPENDS_DIR):
	mkdir -p $@
$(TEST_ASM_ELF): %.elf : %.S | $(RISCV_ENV_DIR) $(DEPENDS_DIR)
	$(CC) $(C_FLAGS)  $(INCLUDE_DIRS) -T$(LINK_FILE) $^ -o $@  -MD -MF $(DEPENDS_DIR)/$(basename $@).d
	$(OBJDUMP) -D $@ > $*.dump

$(TEST_C_ELF): %.elf : %.c crt.S | $(RISCV_ENV_DIR) $(DEPENDS_DIR)
	$(CC) $(C_FLAGS) -O2 $(INCLUDE_DIRS) -T$(LINK_FILE) $^ -o $@ -MD -MF $(DEPENDS_DIR)/$(basename $@).d
	$(OBJDUMP) -D $@ > $*.dump

all:$(TEST_ASM_ELF) $(TEST_C_ELF)

clean:
	rm -rf $(TEST_ASM_ELF) $(TEST_C_ELF) $(DEPENDS_DIR)
