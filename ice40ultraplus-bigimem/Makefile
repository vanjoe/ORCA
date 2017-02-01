-include config.mk

all:
.SUFFIXES:

ICECUBE2?=/nfs/opt/lattice/iCEcube2/2016.02

PROJECT ?= ice40ultraplus
SBT_PROJECT=$(PROJECT)_sbt.project
SYN_PRJ=$(PROJECT)_syn.prj
LSE_PRJ=$(PROJECT)_lse.prj
OUTPUT_DIR=$(PROJECT)_Implmnt
TOP_LEVEL_ENTITY=verilog_top
COMPILER_LOG=$(OUTPUT_DIR)/synlog/$(PROJECT)_compiler.srr
TIMING_REPORT=$(OUTPUT_DIR)/sbt/outputs/router/$(TOP_LEVEL_ENTITY)_timing.rpt
EDF=$(OUTPUT_DIR)/$(PROJECT).edf
BITFILE=$(OUTPUT_DIR)/sbt/outputs/bitmap/$(TOP_LEVEL_ENTITY)_bitmap.bin
FINAL_BITFILE=bits.bin
BOOTMEM_LIST=bootmem.list
BIN_FILE?=software/test.bin

HDL_FILES=$(wildcard hdl/*.vhd) $(wildcard hdl/*.v) $(wildcard ../rtl/*.vhd) ./top.vhd




all: build-software bit programmer.xcf flash.mem
bits: $(FINAL_BITFILE)

BOOT_BASE=0
BOOT_LEN=1024

FLASH_BASE=65536
FLASH_LEN=131072

bootmem.bin : $(BIN_FILE)
	tail -c +$$(( $(BOOT_BASE) +1)) $< | head -c $$(( $(BOOT_LEN)))  >$@
bootmem.mem: bootmem.bin
	xxd -g1 -c4 $^ | awk '{print $$5$$4$$3$$2}' > $@

flash.bin:$(BIN_FILE)
	tail -c +$$(( $(FLASH_BASE)+1)) $< | head -c $$(( $(FLASH_LEN))) > $@
	@wc -c $@
flash.mem: flash.bin
	xxd -g1 -c1 $^ | awk '{print $$2}' >$@

sim: flash.mem bootmem.mem
run_sim: sims
	vsim -gui -do simulate.tcl &

SET_ARCH=setarch x86_64 --uname-2.6
define ice-tcl
ICECUBE2=$(ICECUBE2) tclsh
endef

define mem-init
LD_LIBRARY_PATH=$(ICECUBE2)/sbt_backend/lib/linux/opt:$${LD_LIBRARY_PATH} $(ICECUBE2)/sbt_backend/bin/linux/opt/meminitializer --des-lib $(OUTPUT_DIR)/sbt/netlist/oadb-$(TOP_LEVEL_ENTITY) --mem-list-file
endef
$(BITFILE): $(TIMING_REPORT) bootmem.mem $(BOOTMEM_LIST)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) bootmem.mem $(BOOTMEM_LIST)
	$(mem-init) $(BOOTMEM_LIST)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) $(BOOTMEM_LIST)


$(TIMING_REPORT): $(EDF)
	ICECUBE2=$(ICECUBE2) tclsh iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR)
$(EDF): $(HDL_FILES)
#run the compiler, output the log if compiler fails
	SYNPLIFY_PATH=$(ICECUBE2)/synpbase \
	SBT_DIR=$(ICECUBE2)/sbt_backend/ \
	LD_LIBRARY_PATH=$(ICECUBE2)/sbt_backend/bin/linux/opt/synpwrap:$${LD_LIBRARY_PATH} \
	$(SET_ARCH)	$(ICECUBE2)/sbt_backend/bin/linux/opt/synpwrap/synpwrap -prj $(SYN_PRJ) || \
	 ( cat $(COMPILER_LOG) && exit -1)


syn: $(EDF)




clean:
	rm -rf $(OUTPUT_DIR) *.mem *.imem *.dmem *_Implmnt program_flash.xcf programmer.xcf

clean-all: clean
	make -C software clean

build-software: $(BIN_FILE)
$(BIN_FILE)::
	make -C software FORMAT=bin

PGM_CMD=$(ICECUBE2)/../../programmer/3.8_x64/bin/lin64/pgrcmd -infile

$(FINAL_BITFILE):$(BITFILE)
	cp $^ $@
pgm : $(FINAL_BITFILE)
	$(PGM_CMD) programmer.xcf

.PHONY: syn all clean clean-all build-software bit pgm sim run_sim

.DELETE_ON_ERROR:
