-include config.mk

BD_NAME     ?= design_1
PROJECT_TCL ?= project.tcl
BD_TCL      ?= $(BD_NAME).tcl

PROJ_DIR  ?= project
PROJ_NAME ?= project

SW_DIR   ?= software
ELF_FILE ?= $(SW_DIR)/test.elf
MEM_FILE ?= $(SW_DIR)/test.mem

PROJ_FILE=$(PROJ_DIR)/$(PROJ_NAME).xpr
BD_FILE=$(PROJ_DIR)/$(PROJ_NAME).srcs/sources_1/bd/$(BD_NAME)/$(BD_NAME).bd
HWH_FILE=$(PROJ_DIR)/$(PROJ_NAME).srcs/sources_1/bd/$(BD_NAME)/hw_handoff/$(BD_NAME).hwh
SYNTH_DCP=$(PROJ_DIR)/$(PROJ_NAME).runs/synth_1/$(BD_NAME)_wrapper.dcp
IMPL_BIT=$(PROJ_DIR)/$(PROJ_NAME).runs/impl_1/$(BD_NAME)_wrapper.bit

RESOURCE_TCL=report_resource_usage.tcl
MMI_TCL=write_mmi.tcl
BRAM_NAME=idram_gen
MMI_FILE=$(BRAM_NAME).mmi
OUT_BIT=out.bit

PGM_TCL=pgm.tcl

.PHONY: all
all: $(OUT_BIT) resource_utilization.rpt

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

#These should come from the BSP
JTAG_RESET_BASE_ADDRESS ?= 0x40000000
IDRAM_BASE_ADDRESS ?= 0xC0000000
IDRAM_MAX_ADDRESS  ?= 0xC001FFFF

$(MMI_FILE): $(IMPL_BIT) $(MMI_TCL)
	$(VIVADO_SOURCE) $(MMI_TCL) -tclargs mmi_wrapper $(PROJ_DIR) $(PROJ_NAME) $(BRAM_NAME) $(IDRAM_BASE_ADDRESS)

$(ELF_FILE)::
	make -C $(SW_DIR)

.PHONY: gui
gui: $(BD_FILE)
	vivado -nolog -nojournal $(PROJ_FILE) &

.PHONY: bitstream
bitstream: $(OUT_BIT)

ifeq ($(ELF_FILE), NONE)
$(OUT_BIT): $(IMPL_BIT)
	cp $(IMPL_BIT) $(OUT_BIT)
else #ifeq ($(ELF_FILE), NONE)
$(OUT_BIT): $(IMPL_BIT) $(MMI_FILE) $(ELF_FILE)
	updatemem -force --meminfo $(MMI_FILE) \
	--data $(ELF_FILE)                     \
	--bit $(IMPL_BIT)                      \
	--proc dummy                           \
	--out $(OUT_BIT)
	rm -f updatemem_*.backup.*
endif #else #ifeq ($(ELF_FILE), NONE)

resource_utilization.rpt: $(IMPL_BIT) $(RESOURCE_TCL)
	$(VIVADO_SOURCE) $(RESOURCE_TCL) -tclargs report_resources $(PROJ_DIR) $(PROJ_NAME) $@

.PHONY: pgm
pgm: $(OUT_BIT)
	xsdb $(PGM_TCL) $(OUT_BIT) ps7_init.tcl arm.elf

.PHONY: run
run::
ifeq ($(ELF_FILE), NONE)
	python orca_pgm.py test.bin --family=xilinx --reset_address=$(JTAG_RESET_BASE_ADDRESS) --base_address=$(IDRAM_BASE_ADDRESS) --end_address=`printf "0x%08X" $$(($(IDRAM_MAX_ADDRESS) + 1))` --device=xc7z020_1 --project=$(PROJ_FILE) --debug_nets=$(PROJ_DIR)/$(PROJ_NAME).runs/impl_1/$(BD_NAME)_wrapper.ltx --output_file=jtag_init.tcl
else #ifeq ($(ELF_FILE), NONE)
	$(MAKE) -C software test.bin
	python orca_pgm.py software/test.bin --family=xilinx --reset_address=$(JTAG_RESET_BASE_ADDRESS) --base_address=$(IDRAM_BASE_ADDRESS) --end_address=`printf "0x%08X" $$(($(IDRAM_MAX_ADDRESS) + 1))` --device=xc7z020_1 --project=$(PROJ_FILE) --debug_nets=$(PROJ_DIR)/$(PROJ_NAME).runs/impl_1/$(BD_NAME)_wrapper.ltx --output_file=jtag_init.tcl
endif #else #ifeq ($(ELF_FILE), NONE)

.PHONY: clean
clean:
	rm -rf $(PROJ_DIR) $(PROJ_NAME).bit $(OUT_BIT) $(MMI_FILE) *.jou *.log tmp.* vivado_pid* export_sim/
	make clean -C $(SW_DIR)

.DELETE_ON_ERROR:
