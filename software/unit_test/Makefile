all:

RISCV_TOOLS_DIR=$(abspath ../../tools/riscv-toolchain/riscv-tools)
RISCV_TESTS_DIR=$(RISCV_TOOLS_DIR)/riscv-tests
RISCV_ENV_DIR=$(RISCV_TESTS_DIR)/env/p

$(RISCV_ENV_DIR):
	cd $(RISCV_TOOLS_DIR); git submodule update --init .
	cd $(RISCV_TESTS_DIR); git submodule update --init --recursive .
	sed -i 's/. = 0x80000000/. = 0x00000200/' $@/link.ld
	sed -i 's/.tohost.*$//' $@/link.ld
	sed -i 's/ ecall/fence.i;ecall/' $@/riscv_test.h

PREFIX=riscv32-unknown-elf-
CC=$(PREFIX)gcc
OBJDUMP=$(PREFIX)objdump
TEST_ASM=consecutive_instr.S

TEST=$(addsuffix .elf,$(basename $(TEST_ASM)))

C_FLAGS=-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
INCLUDE_DIRS:=$(RISCV_ENV_DIR) $(RISCV_TESTS_DIR)/isa/macros/scalar

INCLUDE_DIRS:=$(addprefix -I,$(INCLUDE_DIRS))
LINK_FILE=$(RISCV_ENV_DIR)/link.ld

$(TEST): %.elf : %.S | $(RISCV_ENV_DIR)
	$(CC) $(C_FLAGS)  $(INCLUDE_DIRS) -T$(LINK_FILE) $^ -o $@
	$(OBJDUMP) -D $@ > $*.dump

all:$(TEST)


clean:
	rm -rf $(TEST)
