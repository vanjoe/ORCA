-include config.mk

all:
.SUFFIXES:

ICECUBE2=/nfs/opt/lattice/iCEcube2/2016.02

PROJECT ?= ice40up_mdp_16MHz
SBT_PROJECT=$(PROJECT)_sbt.project
SYN_PRJ=$(PROJECT)_syn.prj
LSE_PRJ=$(PROJECT)_lse.prj
OUTPUT_DIR=$(PROJECT)_Implmnt
TOP_LEVEL_ENTITY=verilog_top
COMPILER_LOG=$(OUTPUT_DIR)/synlog/$(PROJECT)_compiler.srr
TIMING_REPORT=$(OUTPUT_DIR)/sbt/outputs/router/$(TOP_LEVEL_ENTITY)_timing.rpt
EDF=$(OUTPUT_DIR)/$(PROJECT).edf
BITFILE=$(OUTPUT_DIR)/sbt/outputs/bitmap/$(TOP_LEVEL_ENTITY)_bitmap.hex

IMEM_LIST=imem.list
DMEM_LIST=dmem.list
MEM_FILE?=software/test.mem

HDL_FILES=$(wildcard hdl/*.vhd) $(wildcard hdl/*.v) $(wildcard ../rtl/*.vhd) ./top.vhd ./top_top.v





all: build-software bit programmer.xcf program_flash.xcf
bit: $(BITFILE)

IMEM_BASE=0
IMEM_LEN=8192
DMEM_BASE=$(IMEM_LEN)
DMEM_LEN=4096

imem.mem: $(MEM_FILE)
	tail -n +$$(( $(IMEM_BASE)/4 +1)) $< | head -n $$(( $(IMEM_LEN)/4)) >$@
dmem.mem: $(MEM_FILE)
	tail -n +$$(($(DMEM_BASE)/4 +1)) $< | head -n $$(( $(DMEM_LEN)/4)) >$@

sim: imem.mem dmem.mem
run_sim: sim
	vsim -gui -do simulate.tcl &

define ice-tcl
ICECUBE2=$(ICECUBE2) tclsh
endef

define mem-init
LD_LIBRARY_PATH=$(ICECUBE2)/sbt_backend/lib/linux/opt:$${LD_LIBRARY_PATH} $(ICECUBE2)/sbt_backend/bin/linux/opt/meminitializer --des-lib $(OUTPUT_DIR)/sbt/netlist/oadb-$(TOP_LEVEL_ENTITY) --mem-list-file
endef
$(BITFILE): $(TIMING_REPORT) dmem.mem imem.mem $(DMEM_LIST) $(IMEM_LIST)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) dmem.mem $(DMEM_LIST)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) imem.mem $(IMEM_LIST)

	$(mem-init) $(IMEM_LIST)
	$(mem-init) $(DMEM_LIST)

	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) $(DMEM_LIST)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) $(IMEM_LIST)


$(TIMING_REPORT): $(EDF)
	ICECUBE2=$(ICECUBE2) tclsh iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR)
$(EDF): $(HDL_FILES)
#run the compiler, output the log if compiler fails
	SYNPLIFY_PATH=$(ICECUBE2)/synpbase \
	SBT_DIR=$(ICECUBE2)/sbt_backend/ \
	LD_LIBRARY_PATH=$(ICECUBE2)/sbt_backend/bin/linux/opt/synpwrap:$${LD_LIBRARY_PATH} \
	$(ICECUBE2)/sbt_backend/bin/linux/opt/synpwrap/synpwrap -prj $(SYN_PRJ) || \
	 ( cat $(COMPILER_LOG) && exit -1)


syn: $(EDF)




clean:
	rm -rf $(OUTPUT_DIR) *.mem *.imem *.dmem *_Implmnt program_flash.xcf programmer.xcf

clean-all: clean
	make -C software clean

build-software: $(MEM_FILE)
$(MEM_FILE)::
	make -C software FORMAT=mem

PGM_CMD=$(ICECUBE2)/../../programmer/3.8_x64/bin/lin64/pgrcmd -infile
programmer.xcf::
	@if [ ! -e $@ ]; then touch $@; fi
	@sed "s/ice40ultraplus/$(PROJECT)/g" programmer.xcf.template > programmer.xcf.temp
	@diff -q programmer.xcf.temp $@; if [ $$? != 0 ]; then cp programmer.xcf.temp $@; echo "New key file $@ created."; fi
	@rm -f programmer.xcf.temp
pgm : $(BITFILE) programmer.xcf
	$(PGM_CMD) programmer.xcf

program_flash.xcf::
	@if [ ! -e $@ ]; then touch $@; fi
	@sed "s/ice40ultraplus/$(PROJECT)/g" program_flash.xcf.template > program_flash.xcf.temp
	@diff -q program_flash.xcf.temp $@; if [ $$? != 0 ]; then cp program_flash.xcf.temp $@; echo "New key file $@ created."; fi
	@rm -f program_flash.xcf.temp
flash: program_flash.xcf.template
	$(PGM_CMD) program_flash.xcf

.PHONY: syn all clean clean-all build-software bit pgm sim run_sim

.DELETE_ON_ERROR:
