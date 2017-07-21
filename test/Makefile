BUILD_ARGS=-k -l -v --cfg-file=../../test/build_cfg_orca.py
-include config.mk

default: builds

################################################################################
QSYS_FILE=system.qsys
QPF_FILE=system.qpf
QSF_FILE=system.qsf
SDC_FILE=system.sdc
HEX_FILE=test.hex
QUARTUS_FILES=$(QPF_FILE) $(QSF_FILE) $(QWS_FILE) $(SDC_FILE)
QIP_FILE=system/synthesis/system.qip
SIP_FILE=system/synthesis/system.sip
SOF_FILE=system.sof

OUTPUT_DIR=output_files/
MAP_RPT_FILE=$(OUTPUT_DIR)system.map.rpt
FIT_RPT_FILE=$(OUTPUT_DIR)system.fit.rpt
MIF_RPT_FILE=$(OUTPUT_DIR)system.mif_update.rpt
ASM_RPT_FILE=$(OUTPUT_DIR)system.asm.rpt
STA_RPT_FILE=$(OUTPUT_DIR)system.sta.rpt

RTL_DIR=../../../../rtl/
RTL_TCL=$(RTL_DIR)orca_hw.tcl
SYSTEM_DIR=../../../../systems/$(SYSTEM)/
ORCA_SUBMODULE_FILES=$(wildcard system/synthesis/submodules/vblox_orca/*.vhd)
TOP_LEVEL_FILES=$(notdir $(wildcard $(SYSTEM_DIR)*.vhd))
HDL_FILES=$(ORCA_SUBMODULE_FILES) $(TOP_LEVEL_FILES)
SYSTEM_FILES=$(notdir $(wildcard $(SYSTEM_DIR)system.*))

system.%: $(SYSTEM_DIR)system.% 
	cp $< $@
$(ORCA_SUBMODULE_FILES): system/synthesis/submodules/vblox_orca/% : $(RTL_DIR)% | $(QIP_FILE)
	cp $^ $@
%.vhd: $(SYSTEM_DIR)%.vhd
	cp $< $@

$(QSYS_FILE) : config.mk
    #sed...
$(QIP_FILE) : $(QSYS_FILE) $(RTL_TCL) 
	cp $(SYSTEM_DIR)system.qpf system.qpf
	cp $(SYSTEM_DIR)system.qsf system.qsf
	cp $(SYSTEM_DIR)system.sdc system.sdc
	qsys-generate --synthesis=VHDL system.qsys
$(MAP_RPT_FILE) : $(QIP_FILE) $(HDL_FILES)
	quartus_map $(QPF_FILE)
$(FIT_RPT_FILE) : $(MAP_RPT_FILE)
	quartus_fit $(QPF_FILE)
$(MIF_RPT_FILE) : $(FIT_RPT_FILE)
	quartus_cdb --update_mif $(QPF_FILE)
$(ASM_RPT_FILE) : $(MIF_RPT_FILE)
	quartus_asm $(QPF_FILE)
$(STA_RPT_FILE) : $(ASM_RPT_FILE)
	quartus_sta $(QPF_FILE)
$(SOF_FILE) : $(STA_RPT_FILE)
	cp $(OUTPUT_DIR)$@ $@

altera: $(SOF_FILE)

################################################################################

xilinx:

################################################################################
microsemi:

################################################################################
lattice:

################################################################################
RV_TESTS=../tools/riscv-toolchain/riscv-tools/riscv-tests
RV_TESTS_COPY=software/riscv-tests
$(RV_TESTS_COPY): $(RV_TESTS)
	rm -rf software/riscv-tests
	cp -r $< $@ 	

builds: $(RV_TESTS_COPY)
	python ../scripts/build/build.py $(BUILD_ARGS) 2>&1 | tee builds.log

################################################################################
clean:
	rm -rf builds/ builds.log config.mk program.mk $(RV_TESTS_COPY)


################################################################################
.PHONY: builds clean altera xilinx microsemi lattice
