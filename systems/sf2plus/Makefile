SYNTHESIS_LOG=synthesis/synplify.log
COMPILE_LOG=designer/Top_Fabric_Master/Top_Fabric_Master_compile_log.log
LAYOUT_LOG=designer/Top_Fabric_Master/Top_Fabric_Master_layout_log.log
TIMING_LOG=designer/Top_Fabric_Master_max_timing_slow_1.14V_85C.xml
INIT_CONFIG_XML=designer/Top_Fabric_Master/Top_Fabric_Master_init_config.xml
BITSTREAM_LOG=designer/Top_Fabric_Master/Top_Fabric_Master_fp/Top_Fabric_Master_generateBitstream.log
HEX_FILE=test.hex

$(HEX_FILE):
	make -C software

$(SYNTHESIS_LOG):
	libero script:flow.tcl script_args:synthesis

$(COMPILE_LOG): $(SYNTHESIS_LOG) 
	libero script:flow.tcl script_args:compile

$(LAYOUT_LOG): $(COMPILE_LOG)
	libero script:flow.tcl script_args:place_and_route

$(TIMING_LOG): $(LAYOUT_LOG)
	libero script:flow.tcl script_args:verify_timing

$(INIT_CONFIG_XML): $(LAYOUT_LOG)
	libero script:flow.tcl script_args:gen_prog_data

$(BITSTREAM_LOG): $(INIT_CONFIG_XML) $(HEX_FILE)
	libero script:flow.tcl script_args:gen_prog_file

pgm: $(BITSTREAM_LOG) 
	libero script:flow.tcl script_args:program

clean:
	libero script:flow.tcl script_args:clean
	make -C software clean


synth: $(SYNTHESIS_LOG)
comp: $(COMPILE_LOG)
pr: $(LAYOUT_LOG)
bit_config: $(INIT_CONFIG_XML)
bit: $(BITSTREAM_LOG)

.PHONY: clean synth comp pr bit_config bit pgm
