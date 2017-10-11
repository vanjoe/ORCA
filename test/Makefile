-include test_config.mk
CFG_FILE   ?= ../../test/build_cfg_orca.py
BUILD_ARGS ?= -k --cfg-file=$(CFG_FILE) $(EXTRA_BUILD_ARGS)

default: builds

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
	rm -rf builds/ builds.log $(RV_TESTS_COPY)

################################################################################

.PHONY: builds clean microsemi microsemi_timing lattice
.DELETE_ON_ERROR:
