
all:bits
PROJECT_TCL=project.tcl
BD_TCL=design_1.tcl

PROJ_DIR=project/
PROJ_NAME=project

PROJ_FILE=$(PROJ_DIR)/$(PROJ_NAME).xpr
BD_FILE=$(PROJ_DIR)/$(PROJ_NAME).srcs/sources_1/bd/design_1/design_1.b
HWDEF_FILE=$(PROJ_DIR)/$(PROJ_NAME).srcs/sources_1/bd/design_1/design_1.hwdef
SYNTH_LOG=$(PROJ_DIR)/$(PROJ_NAME).runs/synth_1/runme.log
IMPL_LOG=$(PROJ_DIR)/$(PROJ_NAME).runs/impl_1/runme.log
VIVADO=vivado -mode tcl -nolog -nojournal


$(PROJ_FILE):
	echo "init_project $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)

$(BD_FILE): $(PROJ_FILE)
	echo "create_bd $(PROJ_DIR) $(PROJ_NAME) $(BD_TCL)" | $(VIVADO) -source $(PROJECT_TCL)

$(HWDEF_FILE): $(BD_FILE)
	echo "generate_bd_design $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)

$(SYNTH_LOG):$(HWDEF_FILE)
	echo "project_synth $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)

$(IMPL_LOG):$(SYNTH_FILE)
	echo "project_impl $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)

$(PROJ_NAME).bit:
	echo "export_bit $(PROJ_DIR) $(PROJ_NAME)" | $(VIVADO) -source $(PROJECT_TCL)

bits:$(PROJ_NAME).bit

clean:
	rm -rf $(PROJ_DIR) $(PROJ_NAME).bit
