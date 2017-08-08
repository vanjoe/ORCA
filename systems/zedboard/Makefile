BD_NAME=design_1
PROJECT_TCL=project.tcl
BD_TCL=$(BD_NAME).tcl
PGM_TCL=pgm.tcl

PROJ_DIR=project/
PROJ_NAME=project

SW_DIR=software
ELF_FILE=$(SW_DIR)/test.elf
MEM_FILE=$(SW_DIR)/test.mem

PROJ_FILE=$(PROJ_DIR)/$(PROJ_NAME).xpr
BD_FILE=$(PROJ_DIR)/$(PROJ_NAME).srcs/sources_1/bd/$(BD_NAME)/$(BD_NAME).bd
HWH_FILE=$(PROJ_DIR)/$(PROJ_NAME).srcs/sources_1/bd/$(BD_NAME)/hw_handoff/$(BD_NAME).hwh
SYNTH_DCP=$(PROJ_DIR)/$(PROJ_NAME).runs/synth_1/$(BD_NAME)_wrapper.dcp
IMPL_BIT=$(PROJ_DIR)/$(PROJ_NAME).runs/impl_1/$(BD_NAME)_wrapper.bit
VIVADO=vivado -mode tcl -nolog -nojournal

MMI_TCL=write_mmi.tcl
BRAM_NAME=idram_gen
MMI_FILE=$(BRAM_NAME).mmi
OUT_BIT=out.bit

.PHONY: all
all: $(OUT_BIT)

VIVADO_SOURCE=vivado -nojournal -nolog -mode batch -source


$(PROJ_FILE) $(BD_FILE): $(PROJECT_TCL) $(BD_TCL)
	$(VIVADO_SOURCE) $(PROJECT_TCL) -tclargs init_project $(PROJ_DIR) $(PROJ_NAME)
	$(VIVADO_SOURCE) $(PROJECT_TCL) -tclargs create_bd $(PROJ_DIR) $(PROJ_NAME) $(BD_TCL)

.PHONY: archiveBD
archiveBD: $(HWH_FILE)

$(HWH_FILE): $(BD_FILE)
	rm -f tmp.$(BD_TCL)
	rm -f $@
	$(VIVADO_SOURCE) $(PROJECT_TCL) -tclargs generate_bd_design $(PROJ_DIR) $(PROJ_NAME) tmp.$(BD_TCL)
	[ -e tmp.$(BD_TCL) ]
	[ -e $@ ]
	mv tmp.$(BD_TCL) $(BD_TCL)
	touch $<
	touch $@

$(SYNTH_DCP): $(HWH_FILE)
	$(VIVADO_SOURCE) $(PROJECT_TCL) -tclargs project_synth $(PROJ_DIR) $(PROJ_NAME)

$(IMPL_BIT): $(SYNTH_DCP)
	$(VIVADO_SOURCE) $(PROJECT_TCL) -tclargs project_impl $(PROJ_DIR) $(PROJ_NAME)

$(MMI_FILE): $(IMPL_BIT) 
	$(VIVADO_SOURCE) $(MMI_TCL) -tclargs mmi_wrapper $(PROJ_DIR) $(PROJ_NAME) $(BRAM_NAME)

$(ELF_FILE)::
	make -C $(SW_DIR)

.PHONY: gui
gui: $(BD_FILE)
	vivado -nolog -nojournal $(PROJ_FILE) &

.PHONY: bitstream
bitstream: $(OUT_BIT)

$(OUT_BIT): $(IMPL_BIT) $(MMI_FILE) $(ELF_FILE)
	updatemem -force --meminfo $(MMI_FILE) \
	--data $(ELF_FILE) \
	--bit $(IMPL_BIT) \
	--proc dummy \
	--out $(OUT_BIT) 
	rm -f updatemem_*.backup.*

.PHONY: pgm
pgm: $(OUT_BIT)
	$(VIVADO_SOURCE) $(PGM_TCL) -tclargs pgm_bits $(PROJ_DIR) $(PROJ_NAME)

.PHONY: clean
clean:
	rm -rf $(PROJ_DIR) $(PROJ_NAME).bit $(OUT_BIT) $(MMI_FILE) *.jou *.log
	make clean -C $(SW_DIR)

.DELETE_ON_ERROR:
