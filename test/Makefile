BUILD_ARGS=-k -l -v --cfg-file=../../test/build_cfg_orca.py --recreate-sw-links
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
CONFIG_FILE=config.mk

system.%: $(SYSTEM_DIR)system.% 
	cp $< $@
$(ORCA_SUBMODULE_FILES): system/synthesis/submodules/vblox_orca/% : $(RTL_DIR)% | $(QIP_FILE)
	cp $^ $@
%.vhd: $(SYSTEM_DIR)%.vhd
	cp $< $@

$(QSYS_FILE) : $(CONFIG_FILE)
	cp $(SYSTEM_DIR)$@ $@
ifdef RESET_VECTOR
	sed -i 's/parameter name="RESET_VECTOR" value=".*"/parameter name="RESET_VECTOR" value="$(RESET_VECTOR)"/g' $(QSYS_FILE)
endif
ifdef MULTIPLY_ENABLE
	sed -i 's/parameter name="MULTIPLY_ENABLE" value=".*"/parameter name="MULTIPLY_ENABLE" value="$(MULTIPLY_ENABLE)"/g' $(QSYS_FILE)
endif
ifdef DIVIDE_ENABLE
	sed -i 's/parameter name="DIVIDE_ENABLE" value=".*"/parameter name="DIVIDE_ENABLE" value="$(DIVIDE_ENABLE)"/g' $(QSYS_FILE)
endif
ifdef SHIFTER_MAX_CYCLES
	sed -i 's/parameter name="SHIFTER_MAX_CYCLES" value=".*"/parameter name="SHIFTER_MAX_CYCLES" value="$(SHIFTER_MAX_CYCLES)"/g' $(QSYS_FILE)
endif
ifdef COUNTER_LENGTH
	sed -i 's/parameter name="COUNTER_LENGTH" value=".*"/parameter name="COUNTER_LENGTH" value="$(COUNTER_LENGTH)"/g' $(QSYS_FILE)
endif
ifdef ENABLE_EXCEPTIONS
	sed -i 's/parameter name="ENABLE_EXCEPTIONS" value=".*"/parameter name="ENABLE_EXCEPTIONS" value="$(ENABLE_EXCEPTIONS)"/g' $(QSYS_FILE)
endif
ifdef BRANCH_PREDICTORS
	sed -i 's/parameter name="BRANCH_PREDICTORS" value=".*"/parameter name="BRANCH_PREDICTORS" value="$(BRANCH_PREDICTORS)"/g' $(QSYS_FILE)
endif
ifdef PIPELINE_STAGES
	sed -i 's/parameter name="PIPELINE_STAGES" value=".*"/parameter name="PIPELINE_STAGES" value="$(PIPELINE_STAGES)"/g' $(QSYS_FILE)
endif
ifdef LVE_ENABLE
	sed -i 's/parameter name="LVE_ENABLE" value=".*"/parameter name="LVE_ENABLE" value="$(LVE_ENABLE)"/g' $(QSYS_FILE)
endif
ifdef ENABLE_EXT_INTERRUPTS
	sed -i 's/parameter name="ENABLE_EXT_INTERRUPTS" value=".*"/parameter name="ENABLE_EXT_INTERRUPTS" value="$(ENABLE_EXT_INTERRUPTS)"/g' $(QSYS_FILE)
endif
ifdef NUM_EXT_INTERRUPTS
	sed -i 's/parameter name="NUM_EXT_INTERRUPTS" value=".*"/parameter name="NUM_EXT_INTERRUPTS" value="$(NUM_EXT_INTERRUPTS)"/g' $(QSYS_FILE)
endif
ifdef SCRATCHPAD_ADDR_BITS
	sed -i 's/parameter name="SCRATCHPAD_ADDR_BITS" value=".*"/parameter name="SCRATCHPAD_ADDR_BITS" value="$(SCRATCHPAD_ADDR_BITS)"/g' $(QSYS_FILE)
endif
ifdef TCRAM_SIZE
	sed -i 's/parameter name="TCRAM_SIZE" value=".*"/parameter name="TCRAM_SIZE" value="$(TCRAM_SIZE)"/g' $(QSYS_FILE)
endif
ifdef CACHE_SIZE
	sed -i 's/parameter name="CACHE_SIZE" value=".*"/parameter name="CACHE_SIZE" value="$(CACHE_SIZE)"/g' $(QSYS_FILE)
endif
ifdef LINE_SIZE
	sed -i 's/parameter name="LINE_SIZE" value=".*"/parameter name="LINE_SIZE" value="$(LINE_SIZE)"/g' $(QSYS_FILE)
endif
ifdef DRAM_WIDTH
	sed -i 's/parameter name="DRAM_WIDTH" value=".*"/parameter name="DRAM_WIDTH" value="$(DRAM_WIDTH)"/g' $(QSYS_FILE)
endif
ifdef BURST_EN
	sed -i 's/parameter name="BURST_EN" value=".*"/parameter name="BURST_EN" value="$(BURST_EN)"/g' $(QSYS_FILE)
endif
ifdef POWER_OPTIMIZED
	sed -i 's/parameter name="POWER_OPTIMIZED" value=".*"/parameter name="POWER_OPTIMIZED" value="$(POWER_OPTIMIZED)"/g' $(QSYS_FILE)
endif
ifdef CACHE_ENABLE
	sed -i 's/parameter name="CACHE_ENABLE" value=".*"/parameter name="CACHE_ENABLE" value="$(CACHE_ENABLE)"/g' $(QSYS_FILE)
endif
$(QIP_FILE) : $(QSYS_FILE) $(RTL_TCL) | $(QSF_FILE) $(SDC_FILE)
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
