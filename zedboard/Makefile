all:bits
PROJECT_TCL=project.tcl
BD_TCL=design_1.tcl

PROJ_DIR=project/
PROJ_NAME=project

SW_DIR=software
ELF_FILE=$(SW_DIR)/test.elf
MEM_FILE=$(SW_DIR)/test.mem

PROJ_FILE=$(PROJ_DIR)/$(PROJ_NAME).xpr
BD_FILE=$(PROJ_DIR)/$(PROJ_NAME).srcs/sources_1/bd/design_1/design_1.bd
BLOCK_DESIGN_GEN_STAMP=$(BD_FILE).gen_stamp
HWDEF_FILE=$(PROJ_DIR)/$(PROJ_NAME).srcs/sources_1/bd/design_1/design_1.hwdef
SYNTH_LOG=$(PROJ_DIR)/$(PROJ_NAME).runs/synth_1/runme.log
IMPL_LOG=$(PROJ_DIR)/$(PROJ_NAME).runs/impl_1/runme.log
VIVADO=vivado -mode tcl -nolog -nojournal

MMI_TCL=write_mmi.tcl
BRAM_NAME=blk_mem_gen_0
MMI_FILE=$(BRAM_NAME).mmi
OUT_BIT=out.bit


$(PROJ_FILE) $(BD_FILE):
	echo "init_project $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)
	echo "create_bd $(PROJ_DIR) $(PROJ_NAME) $(BD_TCL)" | $(VIVADO) -source $(PROJECT_TCL)

$(BLOCK_DESIGN_GEN_STAMP): $(BD_FILE)
	echo "generate_bd_design $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)
	touch $@

$(SYNTH_LOG): $(BLOCK_DESIGN_GEN_STAMP) 
	echo "project_synth $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)

$(IMPL_LOG): $(SYNTH_LOG)
	echo "project_impl $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)

$(PROJ_NAME).bit: $(IMPL_LOG)
	echo "export_bit $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)

$(MEM_FILE):
	make -C $(SW_DIR)

$(MMI_FILE):
	echo "mmi_wrapper $(PROJ_DIR) $(PROJ_NAME) $(BRAM_NAME)" | $(VIVADO) -source $(MMI_TCL)

bits: $(PROJ_NAME).bit $(MEM_FILE) $(MMI_FILE) 
	updatemem -force --meminfo $(MMI_FILE) \
  	--data $(ELF_FILE) \
  	--bit $(PROJ_NAME).bit \
  	--proc dummy \
  	--out $(OUT_BIT) 

clean:
	rm -rf $(PROJ_DIR) $(PROJ_NAME).bit out.bit
