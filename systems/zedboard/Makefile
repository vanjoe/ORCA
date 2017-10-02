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

BD_CHANGES = {

ifdef REGISTER_SIZE
BD_CHANGES += REGISTER_SIZE $(REGISTER_SIZE)
endif #ifdef REGISTER_SIZE
ifdef AVALON_ENABLE
BD_CHANGES += AVALON_ENABLE $(AVALON_ENABLE)
endif #ifdef AVALON_ENABLE
ifdef WISHBONE_ENABLE
BD_CHANGES += WISHBONE_ENABLE $(WISHBONE_ENABLE)
endif #ifdef WISHBONE_ENABLE
ifdef AXI_ENABLE
BD_CHANGES += AXI_ENABLE $(AXI_ENABLE)
endif #ifdef AXI_ENABLE
ifdef RESET_VECTOR
BD_CHANGES += RESET_VECTOR $(RESET_VECTOR)
endif #ifdef RESET_VECTOR
ifdef INTERRUPT_VECTOR
BD_CHANGES += INTERRUPT_VECTOR $(INTERRUPT_VECTOR)
endif #ifdef INTERRUPT_VECTOR
ifdef MULTIPLY_ENABLE
BD_CHANGES += MULTIPLY_ENABLE $(MULTIPLY_ENABLE)
endif #ifdef MULTIPLY_ENABLE
ifdef DIVIDE_ENABLE
BD_CHANGES += DIVIDE_ENABLE $(DIVIDE_ENABLE)
endif #ifdef DIVIDE_ENABLE
ifdef SHIFTER_MAX_CYCLES
BD_CHANGES += SHIFTER_MAX_CYCLES $(SHIFTER_MAX_CYCLES)
endif #ifdef SHIFTER_MAX_CYCLES
ifdef COUNTER_LENGTH
BD_CHANGES += COUNTER_LENGTH $(COUNTER_LENGTH)
endif #ifdef COUNTER_LENGTH
ifdef ENABLE_EXCEPTIONS
BD_CHANGES += ENABLE_EXCEPTIONS $(ENABLE_EXCEPTIONS)
endif #ifdef ENABLE_EXCEPTIONS
ifdef BRANCH_PREDICTORS
BD_CHANGES += BRANCH_PREDICTORS $(BRANCH_PREDICTORS)
endif #ifdef BRANCH_PREDICTORS
ifdef DATA_REQUEST_REGISTER
BD_CHANGES += DATA_REQUEST_REGISTER $(DATA_REQUEST_REGISTER)
endif #ifdef DATA_REQUEST_REGISTER
ifdef DATA_RETURN_REGISTER
BD_CHANGES += DATA_RETURN_REGISTER $(DATA_RETURN_REGISTER)
endif #ifdef DATA_RETURN_REGISTER
ifdef PIPELINE_STAGES
BD_CHANGES += PIPELINE_STAGES $(PIPELINE_STAGES)
endif #ifdef PIPELINE_STAGES
ifdef LVE_ENABLE
BD_CHANGES += LVE_ENABLE $(LVE_ENABLE)
endif #ifdef LVE_ENABLE
ifdef ENABLE_EXT_INTERRUPTS
BD_CHANGES += ENABLE_EXT_INTERRUPTS $(ENABLE_EXT_INTERRUPTS)
endif #ifdef ENABLE_EXT_INTERRUPTS
ifdef NUM_EXT_INTERRUPTS
BD_CHANGES += NUM_EXT_INTERRUPTS $(NUM_EXT_INTERRUPTS)
endif #ifdef NUM_EXT_INTERRUPTS
ifdef SCRATCHPAD_ADDR_BITS
BD_CHANGES += SCRATCHPAD_ADDR_BITS $(SCRATCHPAD_ADDR_BITS)
endif #ifdef SCRATCHPAD_ADDR_BITS
ifdef IUC_ADDR_BASE
BD_CHANGES += IUC_ADDR_BASE $(IUC_ADDR_BASE)
endif #ifdef IUC_ADDR_BASE
ifdef IUC_ADDR_LAST
BD_CHANGES += IUC_ADDR_LAST $(IUC_ADDR_LAST)
endif #ifdef IUC_ADDR_LAST
ifdef ICACHE_SIZE
BD_CHANGES += ICACHE_SIZE $(ICACHE_SIZE)
endif #ifdef ICACHE_SIZE
ifdef ICACHE_LINE_SIZE
BD_CHANGES += ICACHE_LINE_SIZE $(ICACHE_LINE_SIZE)
endif #ifdef ICACHE_LINE_SIZE
ifdef ICACHE_EXTERNAL_WIDTH
BD_CHANGES += ICACHE_EXTERNAL_WIDTH $(ICACHE_EXTERNAL_WIDTH)
endif #ifdef ICACHE_EXTERNAL_WIDTH
ifdef ICACHE_BURST_EN
BD_CHANGES += ICACHE_BURST_EN $(ICACHE_BURST_EN)
endif #ifdef ICACHE_BURST_EN
ifdef POWER_OPTIMIZED
BD_CHANGES += POWER_OPTIMIZED $(POWER_OPTIMIZED)
endif #ifdef POWER_OPTIMIZED
ifdef FAMILY
BD_CHANGES += FAMILY $(FAMILY)
endif #ifdef FAMILY

BD_CHANGES += }

$(PROJ_FILE) $(BD_FILE): $(PROJECT_TCL) $(BD_TCL) $(wildcard config.mk)
	$(VIVADO_SOURCE) $(PROJECT_TCL) -tclargs init_project $(PROJ_DIR) $(PROJ_NAME)
	$(VIVADO_SOURCE) $(PROJECT_TCL) -tclargs create_bd $(PROJ_DIR) $(PROJ_NAME) $(BD_TCL) $(BD_CHANGES)

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
run:
ifeq ($(ELF_FILE), NONE)
	python orca_pgm.py test.bin --family=xilinx --reset_address=$(JTAG_RESET_BASE_ADDRESS) --base_address=$(IDRAM_BASE_ADDRESS) --end_address=`printf "0x%08X" $$(($(IDRAM_MAX_ADDRESS) + 1))` --device=xc7z* --project=$(PROJ_FILE) --debug_nets=$(PROJ_DIR)/$(PROJ_NAME).runs/impl_1/$(BD_NAME)_wrapper.ltx --output_file=jtag_init.tcl
else #ifeq ($(ELF_FILE), NONE)
	$(MAKE) -C software test.bin
	python orca_pgm.py software/test.bin --family=xilinx --reset_address=$(JTAG_RESET_BASE_ADDRESS) --base_address=$(IDRAM_BASE_ADDRESS) --end_address=`printf "0x%08X" $$(($(IDRAM_MAX_ADDRESS) + 1))` --device=xc7z* --project=$(PROJ_FILE) --debug_nets=$(PROJ_DIR)/$(PROJ_NAME).runs/impl_1/$(BD_NAME)_wrapper.ltx --output_file=jtag_init.tcl
endif #else #ifeq ($(ELF_FILE), NONE)

.PHONY: clean
clean:
	rm -rf $(PROJ_DIR) $(PROJ_NAME).bit $(OUT_BIT) $(MMI_FILE) *.jou *.log tmp.* vivado_pid* export_sim/
	make clean -C $(SW_DIR)

.DELETE_ON_ERROR:
