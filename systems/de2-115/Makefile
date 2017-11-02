-include config.mk

BD_NAME         ?= system
CREATE_QSYS_TCL ?= create_$(BD_NAME).tcl
QSYS_HW_TCL     ?= $(BD_NAME)_hw.tcl
QSYS_FILE       ?= $(BD_NAME).qsys
QPF_FILE        ?= $(BD_NAME).qpf

QIP_FILE     := $(BD_NAME)/synthesis/$(BD_NAME).qip
SIP_FILE     := $(BD_NAME)/synthesis/$(BD_NAME).sip
OUTPUT_DIR   := output_files
MAP_RPT_FILE := $(OUTPUT_DIR)/$(BD_NAME).map.rpt
FIT_RPT_FILE := $(OUTPUT_DIR)/$(BD_NAME).fit.rpt
ASM_RPT_FILE := $(OUTPUT_DIR)/$(BD_NAME).asm.rpt
MIF_RPT_FILE := $(OUTPUT_DIR)/$(BD_NAME).mif_update.rpt
STA_RPT_FILE := $(OUTPUT_DIR)/$(BD_NAME).sta.rpt

SW_DIR   ?= software
BIN_FILE ?= test.bin
HEX_FILE ?= test.hex

#Define DEVICE_FAMILY and DEVICE here
include board_cfg.mk

all: system.sof  $(STA_RPT_FILE)

TEST_FILES+=$(wildcard test_components/*.vhd)

ORCA_SUBMODULE_FILES=$(wildcard system/synthesis/submodules/vblox_orca/*.vhd)
TEST_SUBMODULE_FILES=$(addprefix system/synthesis/submodules/,$(notdir $(TEST_FILES)))
JTAG_SUBMODULE_FILES=$(wildcard memory_mapped_reset/*.vhd) 
SUBMODULE_FILES=$(ORCA_SUBMODULE_FILES) $(TEST_SUBMODULE_FILES) $(JTAG_SUBMODULE_FILES)
TOP_LEVEL_FILES=$(wildcard *.vhd)

ifdef REGISTER_SIZE
BD_CHANGES += updateOrca REGISTER_SIZE $(REGISTER_SIZE);
endif #ifdef REGISTER_SIZE
ifdef AVALON_ENABLE
BD_CHANGES += updateOrca AVALON_ENABLE $(AVALON_ENABLE);
endif #ifdef AVALON_ENABLE
ifdef WISHBONE_ENABLE
BD_CHANGES += updateOrca WISHBONE_ENABLE $(WISHBONE_ENABLE);
endif #ifdef WISHBONE_ENABLE
ifdef AXI_ENABLE
BD_CHANGES += updateOrca AXI_ENABLE $(AXI_ENABLE);
endif #ifdef AXI_ENABLE
ifdef RESET_VECTOR
BD_CHANGES += updateOrca RESET_VECTOR $(RESET_VECTOR);
endif #ifdef RESET_VECTOR
ifdef INTERRUPT_VECTOR
BD_CHANGES += updateOrca INTERRUPT_VECTOR $(INTERRUPT_VECTOR);
endif #ifdef INTERRUPT_VECTOR
ifdef MAX_IFETCHES_IN_FLIGHT
BD_CHANGES += updateOrca MAX_IFETCHES_IN_FLIGHT $(MAX_IFETCHES_IN_FLIGHT);
endif #ifdef MAX_IFETCHES_IN_FLIGHT
ifdef MULTIPLY_ENABLE
BD_CHANGES += updateOrca MULTIPLY_ENABLE $(MULTIPLY_ENABLE);
endif #ifdef MULTIPLY_ENABLE
ifdef DIVIDE_ENABLE
BD_CHANGES += updateOrca DIVIDE_ENABLE $(DIVIDE_ENABLE);
endif #ifdef DIVIDE_ENABLE
ifdef SHIFTER_MAX_CYCLES
BD_CHANGES += updateOrca SHIFTER_MAX_CYCLES $(SHIFTER_MAX_CYCLES);
endif #ifdef SHIFTER_MAX_CYCLES
ifdef COUNTER_LENGTH
BD_CHANGES += updateOrca COUNTER_LENGTH $(COUNTER_LENGTH);
endif #ifdef COUNTER_LENGTH
ifdef ENABLE_EXCEPTIONS
BD_CHANGES += updateOrca ENABLE_EXCEPTIONS $(ENABLE_EXCEPTIONS);
endif #ifdef ENABLE_EXCEPTIONS
ifdef DATA_REQUEST_REGISTER
BD_CHANGES += updateOrca DATA_REQUEST_REGISTER $(DATA_REQUEST_REGISTER);
endif #ifdef DATA_REQUEST_REGISTER
ifdef DATA_RETURN_REGISTER
BD_CHANGES += updateOrca DATA_RETURN_REGISTER $(DATA_RETURN_REGISTER);
endif #ifdef DATA_RETURN_REGISTER
ifdef PIPELINE_STAGES
BD_CHANGES += updateOrca PIPELINE_STAGES $(PIPELINE_STAGES);
endif #ifdef PIPELINE_STAGES
ifdef LVE_ENABLE
BD_CHANGES += updateOrca LVE_ENABLE $(LVE_ENABLE);
endif #ifdef LVE_ENABLE
ifdef ENABLE_EXT_INTERRUPTS
BD_CHANGES += updateOrca ENABLE_EXT_INTERRUPTS $(ENABLE_EXT_INTERRUPTS);
endif #ifdef ENABLE_EXT_INTERRUPTS
ifdef NUM_EXT_INTERRUPTS
BD_CHANGES += updateOrca NUM_EXT_INTERRUPTS $(NUM_EXT_INTERRUPTS);
endif #ifdef NUM_EXT_INTERRUPTS
ifdef SCRATCHPAD_ADDR_BITS
BD_CHANGES += updateOrca SCRATCHPAD_ADDR_BITS $(SCRATCHPAD_ADDR_BITS);
endif #ifdef SCRATCHPAD_ADDR_BITS
ifdef IUC_ADDR_BASE
BD_CHANGES += updateOrca IUC_ADDR_BASE $(IUC_ADDR_BASE);
endif #ifdef IUC_ADDR_BASE
ifdef IUC_ADDR_LAST
BD_CHANGES += updateOrca IUC_ADDR_LAST $(IUC_ADDR_LAST);
endif #ifdef IUC_ADDR_LAST
ifdef ICACHE_SIZE
BD_CHANGES += updateOrca ICACHE_SIZE $(ICACHE_SIZE);
endif #ifdef ICACHE_SIZE
ifdef ICACHE_LINE_SIZE
BD_CHANGES += updateOrca ICACHE_LINE_SIZE $(ICACHE_LINE_SIZE);
endif #ifdef ICACHE_LINE_SIZE
ifdef ICACHE_EXTERNAL_WIDTH
BD_CHANGES += updateOrca ICACHE_EXTERNAL_WIDTH $(ICACHE_EXTERNAL_WIDTH);
endif #ifdef ICACHE_EXTERNAL_WIDTH
ifdef ICACHE_BURST_EN
BD_CHANGES += updateOrca ICACHE_BURST_EN $(ICACHE_BURST_EN);
endif #ifdef ICACHE_BURST_EN
ifdef POWER_OPTIMIZED
BD_CHANGES += updateOrca POWER_OPTIMIZED $(POWER_OPTIMIZED);
endif #ifdef POWER_OPTIMIZED
ifdef FAMILY
BD_CHANGES += updateOrca FAMILY $(FAMILY);
endif #ifdef FAMILY


$(QSYS_FILE): $(CREATE_QSYS_TCL) updateOrca.tcl $(wildcard config.mk)
	qsys-script --search-path="./,../../rtl/,$$" --cmd="package require qsys; set_project_property DEVICE_FAMILY {$(DEVICE_FAMILY)};set_project_property DEVICE $(DEVICE); source $(CREATE_QSYS_TCL); create_system $@; compose; source updateOrca.tcl; $(BD_CHANGES) save_system $@"

.PHONY: gui-qsys
gui-qsys: $(QSYS_FILE)
	qsys-edit $(QSYS_FILE) --search-path="./,../../rtl/,$$" &

.PHONY: archiveBD
archiveBD: $(QIP_FILE)

$(QIP_FILE): $(QSYS_FILE) ../../rtl/orca_hw.tcl
	rm -f $(QSYS_HW_TCL)
	rm -f $@
	qsys-generate $(QSYS_FILE) --search-path="./,../../rtl/,$$" --synthesis=VHDL 2>&1 | tee ./synth.$(QSYS_FILE).log
	qsys-script --search-path="./,../../rtl/,$$" --system-file=$(QSYS_FILE) --cmd="package require qsys; export_hw_tcl"
	[ -e $@ ]
	[ -e $(QSYS_HW_TCL) ]
	sed 's/set_module_property.*//g' $(QSYS_HW_TCL) | sed 's/package require -exact qsys.*//g' > $(CREATE_QSYS_TCL)
	rm -f $(QSYS_HW_TCL)
	touch $(QSYS_FILE)
	touch $@

$(ORCA_SUBMODULE_FILES): system/synthesis/submodules/vblox_orca/% : ../../rtl/% | $(QIP_FILE)
	 cp $^ $@

.phony: copy-files

copy-files: $(ORCA_SUBMODULE_FILES)

$(TEST_SUBMODULE_FILES): system/synthesis/submodules/% : test_components/%
	cp $^ $@

$(MAP_RPT_FILE) : $(QIP_FILE) $(SUBMODULE_FILES) $(TOP_LEVEL_FILES) 
	quartus_map $(QPF_FILE)
$(FIT_RPT_FILE) : $(MAP_RPT_FILE)
	quartus_fit $(QPF_FILE)
$(STA_RPT_FILE) : $(FIT_RPT_FILE)
	quartus_sta $(QPF_FILE)
$(MIF_RPT_FILE) : $(FIT_RPT_FILE)
	quartus_cdb --update_mif $(QPF_FILE)
$(ASM_RPT_FILE) : $(MIF_RPT_FILE)
	quartus_asm $(QPF_FILE)

system.sof: $(ASM_RPT_FILE)
	cp $(OUTPUT_DIR)/$@ $@

qip: $(QIP_FILE)
map: $(MAP_RPT_FILE)
fit: $(FIT_RPT_FILE)
mif: $(MIF_RPT_FILE)
asm: $(ASM_RPT_FILE)
sta: $(STA_RPT_FILE)

.phony: all clean qip map fit mif asm sta pgm run testbench sim help

testbench: system/simulation/mentor/msim_setup.tcl

system/simulation/mentor/msim_setup.tcl: $(QSYS_FILE) $(SUBMODULE_FILES)
	qsys-generate $(QSYS_FILE) --search-path="./,../../rtl/,$$" --simulation=VHDL 2>&1 | tee ./sim.$(QSYS_FILE).log
	[ -e $@ ]

$(SW_DIR)/$(HEX_FILE):
	$(MAKE) -C $(SW_DIR) $(HEX_FILE)

sim: testbench $(SW_DIR)/$(HEX_FILE)
	vsim -do simulate.tcl

clean:
	rm -rf system/ $(OUTPUT_DIR) $(QSYS_HW_TCL) $(QSYS_FILE)
	rm -rf db/ incremental_db/
	rm -rf *.log system.sopcinfo
	rm -rf system.sof .qsys_edit/
	$(MAKE) -C $(SW_DIR)/ clean || true


pgm: system.sof
	quartus_pgm -m JTAG -o P\;$^

run:
ifeq ($(BIN_FILE), NONE)
	python orca_pgm.py test.bin --family=altera --reset_address=0x10000000 --end_address=0x00010000
else #ifeq ($(BIN_FILE), NONE)
	make -C $(SW_DIR) $(BIN_FILE)
	python orca_pgm.py $(SW_DIR)/$(BIN_FILE) --family=altera --reset_address=0x10000000 --end_address=0x00010000
endif #else #ifeq ($(BIN_FILE), NONE)

terminal-run:
	$(MAKE) run
	nios2-terminal | tee run.log

help:
	@echo "Makefile Help:"
	@echo "Targets:"
	@echo
	@echo "   all:"
	@echo "     Build bitstream and run timing reports"
	@echo
	@echo "   gui-qsys:"
	@echo "     Open the system in the QSYS GUI"
	@echo
	@echo "   qip:"
	@echo "     Run qsys-generate"
	@echo
	@echo "   map:"
	@echo "     Run sythesis"
	@echo
	@echo "   fit:"
	@echo "     Run Place and Route"
	@echo
	@echo "   sta:"
	@echo "     Run timing analysis"
	@echo
	@echo "   asm:"
	@echo "     Assemble bitstream"
	@echo
	@echo "   clean:"
	@echo "     Clean all outputs"
	@echo
	@echo "   testbench:"
	@echo "     Generate testbench from qsys file"
	@echo
	@echo "   sim:"
	@echo "     Run modelsim simulator"
	@echo
	@echo "   pgm:"
	@echo "     Program the attached de2-115 board"
	@echo
	@echo "   run:"
	@echo "     Program and run the program from the software directory"

.DELETE_ON_ERROR:
