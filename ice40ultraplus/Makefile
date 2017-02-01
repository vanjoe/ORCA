-include config.mk

all:
.SUFFIXES:

ICECUBE2?=/nfs/opt/lattice/iCEcube2/2016.02

PROJECT= ice40ultraplus
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
IMEM_LIST=imem.list
DMEM_LIST=dmem.list
MEM_FILE?=software/test.mem

HDL_FILES=$(wildcard hdl/*.vhd) $(wildcard hdl/*.v) $(wildcard ../rtl/*.vhd) ./top.vhd ./top_top.v

all:  bits programmer.xcf

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
$(BITFILE): $(TIMING_REPORT) dmem.mem imem.mem $(DMEM_LIST) $(IMEM_LIST) build-software
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) dmem.mem $(DMEM_LIST)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) imem.mem $(IMEM_LIST)

	$(mem-init) $(IMEM_LIST)
	$(mem-init) $(DMEM_LIST)

	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) $(DMEM_LIST)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) $(IMEM_LIST)


$(TIMING_REPORT): $(EDF)
	ICECUBE2=$(ICECUBE2) tclsh iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR)
$(EDF): $(HDL_FILES) $(SYN_PRJ)
#run the compiler, output the log if compiler fails
	SYNPLIFY_PATH=$(ICECUBE2)/synpbase \
	SBT_DIR=$(ICECUBE2)/sbt_backend/ \
	LD_LIBRARY_PATH=$(ICECUBE2)/sbt_backend/bin/linux/opt/synpwrap:$${LD_LIBRARY_PATH} \
	setarch x86_64 --uname-2.6 \
	$(ICECUBE2)/sbt_backend/bin/linux/opt/synpwrap/synpwrap -prj $(SYN_PRJ) || \
	 ( cat $(COMPILER_LOG) && exit -1)


syn: $(EDF)


clean-log:
	rm -rf stdout.log stdout.log.bak transcript vsim.wlf synlog.tcl
clean: clean-log
	rm -rf $(OUTPUT_DIR) *.mem *.imem *.dmem *_Implmnt  *~ $(FINAL_BITFILE)

clean-all: clean
	make -C software clean

build-software: $(MEM_FILE)
$(MEM_FILE)::
	make -C software FORMAT=mem

PGM_CMD=$(ICECUBE2)/../../programmer/3.8_x64/bin/lin64/pgrcmd -infile

$(FINAL_BITFILE):$(BITFILE)
	cp $^ $@
bits: $(FINAL_BITFILE)

pgm : $(FINAL_BITFILE)
	$(PGM_CMD) programmer.xcf || true


.PHONY: syn all clean clean-all build-software bit pgm sim run_sim

.DELETE_ON_ERROR:
