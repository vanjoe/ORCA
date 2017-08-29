BUILD_ARGS= -k -l -u -v --cfg-file=../../test/build_cfg_orca.py
-include config.mk

default: builds

################################################################################

ALT_QSYS_FILE=system.qsys
ALT_QPF_FILE=system.qpf
ALT_QSF_FILE=system.qsf
ALT_SDC_FILE=system.sdc
ALT_HEX_FILE=test.hex
ALT_QUARTUS_FILES=$(ALT_QPF_FILE) $(ALT_QSF_FILE) $(ALT_QWS_FILE) $(ALT_SDC_FILE)
ALT_QIP_FILE=system/synthesis/system.qip
ALT_SIP_FILE=system/synthesis/system.sip
ALT_SOF_FILE=system.sof

ALT_OUTPUT_DIR=output_files/
ALT_MAP_RPT_FILE=$(ALT_OUTPUT_DIR)system.map.rpt
ALT_FIT_RPT_FILE=$(ALT_OUTPUT_DIR)system.fit.rpt
ALT_MIF_RPT_FILE=$(ALT_OUTPUT_DIR)system.mif_update.rpt
ALT_ASM_RPT_FILE=$(ALT_OUTPUT_DIR)system.asm.rpt
ALT_STA_RPT_FILE=$(ALT_OUTPUT_DIR)system.sta.rpt

ALT_RTL_DIR=../../../../rtl/
ALT_RTL_TCL=$(ALT_RTL_DIR)orca_hw.tcl
ALT_SYSTEM_DIR=../../../../systems/$(ALT_SYSTEM)/
ALT_ORCA_SUBMODULE_FILES=$(wildcard system/synthesis/submodules/vblox_orca/*.vhd)
ALT_TOP_LEVEL_FILES=$(notdir $(wildcard $(ALT_SYSTEM_DIR)*.vhd))
ALT_HDL_FILES=$(ALT_ORCA_SUBMODULE_FILES) $(ALT_TOP_LEVEL_FILES)
ALT_SYSTEM_FILES=$(notdir $(wildcard $(ALT_SYSTEM_DIR)system.*))
ALT_CONFIG_FILE=config.mk

system.%: $(ALT_SYSTEM_DIR)system.% 
	cp $< $@
$(ALT_ORCA_SUBMODULE_FILES): system/synthesis/submodules/vblox_orca/% : $(ALT_RTL_DIR)% | $(ALT_QIP_FILE)
	cp $^ $@
%.vhd: $(ALT_SYSTEM_DIR)%.vhd
	cp $< $@

$(ALT_QSYS_FILE) : $(ALT_CONFIG_FILE)
	cp $(ALT_SYSTEM_DIR)$@ $@
ifdef RESET_VECTOR
	sed -i 's/parameter name="RESET_VECTOR" value=".*"/parameter name="RESET_VECTOR" value="$(ALT_RESET_VECTOR)"/g' $(ALT_QSYS_FILE)
endif
ifdef MULTIPLY_ENABLE
	sed -i 's/parameter name="MULTIPLY_ENABLE" value=".*"/parameter name="MULTIPLY_ENABLE" value="$(ALT_MULTIPLY_ENABLE)"/g' $(ALT_QSYS_FILE)
endif
ifdef DIVIDE_ENABLE
	sed -i 's/parameter name="DIVIDE_ENABLE" value=".*"/parameter name="DIVIDE_ENABLE" value="$(ALT_DIVIDE_ENABLE)"/g' $(ALT_QSYS_FILE)
endif
ifdef SHIFTER_MAX_CYCLES
	sed -i 's/parameter name="SHIFTER_MAX_CYCLES" value=".*"/parameter name="SHIFTER_MAX_CYCLES" value="$(ALT_SHIFTER_MAX_CYCLES)"/g' $(ALT_QSYS_FILE)
endif
ifdef COUNTER_LENGTH
	sed -i 's/parameter name="COUNTER_LENGTH" value=".*"/parameter name="COUNTER_LENGTH" value="$(ALT_COUNTER_LENGTH)"/g' $(ALT_QSYS_FILE)
endif
ifdef ENABLE_EXCEPTIONS
	sed -i 's/parameter name="ENABLE_EXCEPTIONS" value=".*"/parameter name="ENABLE_EXCEPTIONS" value="$(ALT_ENABLE_EXCEPTIONS)"/g' $(ALT_QSYS_FILE)
endif
ifdef BRANCH_PREDICTORS
	sed -i 's/parameter name="BRANCH_PREDICTORS" value=".*"/parameter name="BRANCH_PREDICTORS" value="$(ALT_BRANCH_PREDICTORS)"/g' $(ALT_QSYS_FILE)
endif
ifdef PIPELINE_STAGES
	sed -i 's/parameter name="PIPELINE_STAGES" value=".*"/parameter name="PIPELINE_STAGES" value="$(ALT_PIPELINE_STAGES)"/g' $(ALT_QSYS_FILE)
endif
ifdef LVE_ENABLE
	sed -i 's/parameter name="LVE_ENABLE" value=".*"/parameter name="LVE_ENABLE" value="$(ALT_LVE_ENABLE)"/g' $(ALT_QSYS_FILE)
endif
ifdef ENABLE_EXT_INTERRUPTS
	sed -i 's/parameter name="ENABLE_EXT_INTERRUPTS" value=".*"/parameter name="ENABLE_EXT_INTERRUPTS" value="$(ALT_ENABLE_EXT_INTERRUPTS)"/g' $(ALT_QSYS_FILE)
endif
ifdef NUM_EXT_INTERRUPTS
	sed -i 's/parameter name="NUM_EXT_INTERRUPTS" value=".*"/parameter name="NUM_EXT_INTERRUPTS" value="$(ALT_NUM_EXT_INTERRUPTS)"/g' $(ALT_QSYS_FILE)
endif
ifdef SCRATCHPAD_ADDR_BITS
	sed -i 's/parameter name="SCRATCHPAD_ADDR_BITS" value=".*"/parameter name="SCRATCHPAD_ADDR_BITS" value="$(ALT_SCRATCHPAD_ADDR_BITS)"/g' $(ALT_QSYS_FILE)
endif
ifdef TCRAM_SIZE
	sed -i 's/parameter name="TCRAM_SIZE" value=".*"/parameter name="TCRAM_SIZE" value="$(ALT_TCRAM_SIZE)"/g' $(ALT_QSYS_FILE)
endif
ifdef CACHE_SIZE
	sed -i 's/parameter name="CACHE_SIZE" value=".*"/parameter name="CACHE_SIZE" value="$(ALT_CACHE_SIZE)"/g' $(ALT_QSYS_FILE)
endif
ifdef LINE_SIZE
	sed -i 's/parameter name="LINE_SIZE" value=".*"/parameter name="LINE_SIZE" value="$(ALT_LINE_SIZE)"/g' $(ALT_QSYS_FILE)
endif
ifdef DRAM_WIDTH
	sed -i 's/parameter name="DRAM_WIDTH" value=".*"/parameter name="DRAM_WIDTH" value="$(ALT_DRAM_WIDTH)"/g' $(ALT_QSYS_FILE)
endif
ifdef BURST_EN
	sed -i 's/parameter name="BURST_EN" value=".*"/parameter name="BURST_EN" value="$(ALT_BURST_EN)"/g' $(ALT_QSYS_FILE)
endif
ifdef POWER_OPTIMIZED
	sed -i 's/parameter name="POWER_OPTIMIZED" value=".*"/parameter name="POWER_OPTIMIZED" value="$(ALT_POWER_OPTIMIZED)"/g' $(ALT_QSYS_FILE)
endif
ifdef CACHE_ENABLE
	sed -i 's/parameter name="CACHE_ENABLE" value=".*"/parameter name="CACHE_ENABLE" value="$(ALT_CACHE_ENABLE)"/g' $(ALT_QSYS_FILE)
endif
$(ALT_QIP_FILE) : $(ALT_QSYS_FILE) $(ALT_RTL_TCL) | $(ALT_QSF_FILE) $(ALT_SDC_FILE)
	qsys-generate --synthesis=VHDL system.qsys
$(ALT_MAP_RPT_FILE) : $(ALT_QIP_FILE) $(ALT_HDL_FILES)
	quartus_map $(ALT_QPF_FILE)
$(ALT_FIT_RPT_FILE) : $(ALT_MAP_RPT_FILE)
	quartus_fit $(ALT_QPF_FILE)
$(ALT_MIF_RPT_FILE) : $(ALT_FIT_RPT_FILE)
	quartus_cdb --update_mif $(ALT_QPF_FILE)
$(ALT_ASM_RPT_FILE) : $(ALT_MIF_RPT_FILE)
	quartus_asm $(ALT_QPF_FILE)
$(ALT_STA_RPT_FILE) : $(ALT_ASM_RPT_FILE)
	quartus_sta $(ALT_QPF_FILE)
$(ALT_SOF_FILE) : $(ALT_STA_RPT_FILE)
	cp $(ALT_OUTPUT_DIR)$@ $@

altera: $(ALT_SOF_FILE)

################################################################################

XIL_PROJECT_TCL=project.tcl
XIL_BD_TCL=design_1.tcl
XIL_PGM_TCL=pgm.tcl

XIL_PROJ_DIR=project
XIL_PROJ_NAME=project

XIL_SW_DIR=software
XIL_ELF_FILE=$(XIL_SW_DIR)/test.elf
XIL_MEM_FILE=$(XIL_SW_DIR)/test.mem

XIL_PROJ_FILE=$(XIL_PROJ_DIR)/$(XIL_PROJ_NAME).xpr
XIL_BD_FILE=$(XIL_PROJ_DIR)/$(XIL_PROJ_NAME).srcs/sources_1/bd/design_1/design_1.bd
XIL_BLOCK_DESIGN_GEN_STAMP=$(XIL_BD_FILE).gen_stamp
XIL_IMPL_STAMP=$(XIL_BD_FILE).impl_stamp
XIL_HWDEF_FILE=$(XIL_PROJ_DIR)/$(XIL_PROJ_NAME).srcs/sources_1/bd/design_1/design_1.hwdef
XIL_SYNTH_LOG=$(XIL_PROJ_DIR)/$(XIL_PROJ_NAME).runs/synth_1/runme.log
XIL_IMPL_TIMING_RPT=$(XIL_PROJ_DIR)/$(XIL_PROJ_NAME).runs/impl_1/design_1_wrapper_timing_summary_routed.rpt
XIL_VIVADO=vivado -mode tcl -nolog -nojournal

XIL_MMI_TCL=write_mmi.tcl
XIL_BRAM_NAME=idram_gen
XIL_MMI_FILE=$(BRAM_NAME).mmi
XIL_OUT_BIT=out.bit

$(XIL_PROJ_FILE) $(XIL_BD_FILE):
	echo "init_project $(XIL_PROJ_DIR) $(XIL_PROJ_NAME)" | $(XIL_VIVADO) -source $(XIL_PROJECT_TCL)
	echo "create_bd $(XIL_PROJ_DIR) $(XIL_PROJ_NAME) $(XIL_BD_TCL)" | $(XIL_VIVADO) -source $(XIL_PROJECT_TCL)

$(XIL_BLOCK_DESIGN_GEN_STAMP): $(XIL_BD_FILE)
	echo "generate_bd_design $(XIL_PROJ_DIR) $(XIL_PROJ_NAME)" | $(XIL_VIVADO) -source $(XIL_PROJECT_TCL)
	touch $@

$(XIL_SYNTH_LOG): $(XIL_BLOCK_DESIGN_GEN_STAMP) 
	echo "project_synth $(XIL_PROJ_DIR) $(XIL_PROJ_NAME)" | $(XIL_VIVADO) -source $(XIL_PROJECT_TCL)

$(XIL_IMPL_STAMP): $(XIL_SYNTH_LOG)
	echo "project_impl $(XIL_PROJ_DIR) $(XIL_PROJ_NAME)" | $(XIL_VIVADO) -source $(XIL_PROJECT_TCL)
	touch $@

$(XIL_PROJ_NAME).bit: $(XIL_IMPL_STAMP)
	echo "export_bit $(XIL_PROJ_DIR) $(XIL_PROJ_NAME)" | $(XIL_VIVADO) -source $(XIL_PROJECT_TCL)

$(XIL_MMI_FILE): $(XIL_IMPL_TIMING_RPT) 
	echo "mmi_wrapper $(XIL_PROJ_DIR) $(XIL_PROJ_NAME) $(XIL_BRAM_NAME)" | $(XIL_VIVADO) -source $(XIL_MMI_TCL)

$(XIL_OUT_BIT): $(XIL_PROJ_NAME).bit $(XIL_MMI_FILE)
	cp $(XIL_PROJ_NAME).bit $(XIL_OUT_BIT)

xilinx: $(XIL_OUT_BIT)

################################################################################

MCSM_SYNTHESIS_LOG=synthesis/synplify.log
MCSM_COMPILE_LOG=designer/Top_Fabric_Master/Top_Fabric_Master_compile_log.log
MCSM_LAYOUT_LOG=designer/Top_Fabric_Master/Top_Fabric_Master_layout_log.log
MCSM_TIMING_LOG=designer/Top_Fabric_Master/Top_Fabric_Master_max_timing_slow_1.14V_85C.xml
MCSM_INIT_CONFIG_XML=designer/Top_Fabric_Master/Top_Fabric_Master_init_config.xml
MCSM_BITSTREAM_LOG=designer/Top_Fabric_Master/Top_Fabric_Master_fp/Top_Fabric_Master_generateBitstream.log
MCSM_HEX_FILE=test.hex

$(MCSM_SYNTHESIS_LOG):
	libero script:flow.tcl script_args:synthesis

$(MCSM_COMPILE_LOG): $(MCSM_SYNTHESIS_LOG) 
	libero script:flow.tcl script_args:compile

$(MCSM_LAYOUT_LOG): $(MCSM_COMPILE_LOG)
	libero script:flow.tcl script_args:place_and_route

$(MCSM_TIMING_LOG): $(MCSM_LAYOUT_LOG)
	libero script:flow.tcl script_args:verify_timing

$(MCSM_INIT_CONFIG_XML): $(MCSM_LAYOUT_LOG) 
	libero script:flow.tcl script_args:gen_prog_data

$(MCSM_BITSTREAM_LOG): $(MCSM_HEX_FILE) $(MCSM_INIT_CONFIG_XML) 
	libero script:flow.tcl script_args:gen_prog_file

microsemi_timing: $(MCSM_TIMING_LOG)

microsemi_pgm: $(MCSM_BITSTREAM_LOG) 
	libero script:flow.tcl script_args:program

microsemi_clean_bit:
	libero script:flow.tcl script_args:clean_bit

microsemi: $(MCSM_BITSTREAM_LOG)

################################################################################

lattice:
	@echo 'Lattice automated testing not yet supported.'

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

.PHONY: builds clean altera xilinx microsemi microsemi_timing lattice
