all:



ARCH=rv32im
LVE_EXT=xlve
PREFIX=riscv32-unknown-elf-
OBJDIR=obj
CC=$(PREFIX)gcc
OBJDUMP=$(PREFIX)objdump
TEST_ASM=consecutive_instr.S
TEST_C=simple_c_test.c vbx_test.c interrupt_test.c cmov_test.c back2back_load_store_test.c cache_test.c dhrystone.c

OBJS=$(addprefix $(OBJDIR)/,$(addsuffix .o,$(TEST_C) $(TEST_ASM)))

TEST_ASM_ELF=$(addsuffix .elf,$(basename $(TEST_ASM)))
TEST_C_ELF=$(addsuffix .elf,$(basename $(TEST_C)))

C_FLAGS= -march=$(ARCH) -O3 -Wa,-march=$(ARCH)$(LVE_EXT) -Wall -MMD
LD_FLAGS= -static -nostartfiles $(CFLAGS)
RISCV_TESTS_DIR=../riscv-tests
RISCV_ENV_DIR=$(RISCV_TESTS_DIR)/env/p

INCLUDE_DIRS:=$(RISCV_ENV_DIR) $(RISCV_TESTS_DIR)/isa/macros/scalar ../ ../vbx_lib

INCLUDE_DIRS:=$(addprefix -I,$(INCLUDE_DIRS))
LINK_FILE=link.ld


DEP_FILES=$(wildcard $(OBJDIR)/*.d)

-include $(DEP_FILES)
$(DEPENDS_DIR):
	mkdir -p $@

$(OBJDIR)/:
	mkdir -p $(OBJDIR)/


$(OBJS): $(OBJDIR)/%.o : % | $(OBJDIR)/
	$(CC) -c $(C_FLAGS)  $(INCLUDE_DIRS) $< -o $@


$(TEST_ASM_ELF): %.elf : $(OBJDIR)/%.S.o | $(RISCV_ENV_DIR)
	$(CC) $(LD_FLAGS)  -T$(LINK_FILE) $^ -o $@
	$(OBJDUMP) -D $@ > $*.dump

$(TEST_C_ELF): %.elf : $(OBJDIR)/%.c.o crt.S | $(RISCV_ENV_DIR)
	$(CC) $(LD_FLAGS) -T$(LINK_FILE) $^ -o $@
	$(OBJDUMP) -D $@ > $*.dump

all:$(TEST_ASM_ELF) $(TEST_C_ELF)

clean:
	rm -rf $(TEST_ASM_ELF) $(TEST_C_ELF) $(DEPENDS_DIR)
