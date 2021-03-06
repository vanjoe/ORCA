-include config.mk

all:
.SUFFIXES:

#ICECUBE2?=/nfs/opt/lattice/iCEcube2/2016.02
ICECUBE2?=/nfs/opt/lattice/iCEcube2/2017.01

PROJECT= ice40ultraplus
SBT_PROJECT=$(PROJECT)_sbt.project
SYN_PRJ=$(PROJECT)_syn.prj
LSE_PRJ=$(PROJECT)_lse.prj
OUTPUT_DIR=$(PROJECT)_Implmnt
TOP_LEVEL_ENTITY=verilog_top
COMPILER_LOG=$(OUTPUT_DIR)/synlog/$(PROJECT)_compiler.srr
TIMING_REPORT=$(OUTPUT_DIR)/sbt/outputs/router/$(TOP_LEVEL_ENTITY)_timing.rpt
EDF=$(OUTPUT_DIR)/$(PROJECT).edf
PROJ_BITFILE=$(OUTPUT_DIR)/sbt/outputs/bitmap/$(TOP_LEVEL_ENTITY)_bitmap.bin

FINAL_BITFILE=flash.bin
IMEM_LIST=imem.list
DMEM_LIST=dmem.list
MEM_FILE?=software/test.mem

HDL_FILES=$(wildcard hdl/*.vhd) $(wildcard hdl/*.v) $(wildcard ../../ip/orca/hdl/*.vhd) $(wildcard ../../ip/lve/hdl/*.vhd) ./top.vhd ./top_top.v

all:  bits

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
$(PROJ_BITFILE): $(TIMING_REPORT) dmem.mem imem.mem $(DMEM_LIST) $(IMEM_LIST) $(MEM_FILE)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) dmem.mem $(DMEM_LIST)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) imem.mem $(IMEM_LIST)

	$(mem-init) $(IMEM_LIST)
	$(mem-init) $(DMEM_LIST)

	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) $(DMEM_LIST)
	$(ice-tcl) iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR) $(IMEM_LIST)


$(TIMING_REPORT): $(EDF)
	ICECUBE2=$(ICECUBE2) tclsh iCEcube2_flow.tcl $(PROJECT) $(OUTPUT_DIR)
	grep -B10 "End of Clock Frequency Summary" $(TIMING_REPORT)
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
	ORCA_TEST=$(ORCA_TEST) $(MAKE) -C software clean

build-software: $(MEM_FILE)
$(MEM_FILE)::
	ORCA_TEST=$(ORCA_TEST) $(MAKE) -C software FORMAT=mem

PGM_CMD=$(ICECUBE2)/../../programmer/3.8_x64/bin/lin64/pgrcmd -infile

bits.bin : $(PROJ_BITFILE)
	cp $^ $@
$(FINAL_BITFILE): bits.bin golden.bin qmin.bin cifar_weights.bin
	cp bits.bin $@
	truncate --size $$(( 0x20000 )) $@
	cat golden.bin >> $@
	truncate --size $$(( 0xB0000 )) $@
	cat qmin.bin >> $@
	truncate --size $$(( 0xC0000 )) $@
	cat cifar_weights.bin >> $@
	echo -en "\x01\x06\x00" >> $@
	xxd -c 1 $@  | awk '{print $$2}' > flash.mem
	wc -c $@

bits: $(FINAL_BITFILE)

pgm : $(FINAL_BITFILE)
	$(PGM_CMD) programmer.xcf || true
pgm-flash : $(FINAL_BITFILE)
	$(PGM_CMD) programmer_flash.xcf || true
.PHONY: syn all clean clean-all build-software bit pgm sim run_sim

.DELETE_ON_ERROR:
