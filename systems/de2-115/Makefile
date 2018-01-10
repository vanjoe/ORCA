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
BD_CHANGES += updateORCA REGISTER_SIZE $(REGISTER_SIZE);
endif #ifdef REGISTER_SIZE
ifdef RESET_VECTOR
BD_CHANGES += updateORCA RESET_VECTOR $(RESET_VECTOR);
endif #ifdef RESET_VECTOR
ifdef INTERRUPT_VECTOR
BD_CHANGES += updateORCA INTERRUPT_VECTOR $(INTERRUPT_VECTOR);
endif #ifdef INTERRUPT_VECTOR
ifdef MAX_IFETCHES_IN_FLIGHT
BD_CHANGES += updateORCA MAX_IFETCHES_IN_FLIGHT $(MAX_IFETCHES_IN_FLIGHT);
endif #ifdef MAX_IFETCHES_IN_FLIGHT
ifdef BTB_ENTRIES
BD_CHANGES += updateORCA BTB_ENTRIES $(BTB_ENTRIES);
endif #ifdef BTB_ENTRIES
ifdef MULTIPLY_ENABLE
BD_CHANGES += updateORCA MULTIPLY_ENABLE $(MULTIPLY_ENABLE);
endif #ifdef MULTIPLY_ENABLE
ifdef DIVIDE_ENABLE
BD_CHANGES += updateORCA DIVIDE_ENABLE $(DIVIDE_ENABLE);
endif #ifdef DIVIDE_ENABLE
ifdef SHIFTER_MAX_CYCLES
BD_CHANGES += updateORCA SHIFTER_MAX_CYCLES $(SHIFTER_MAX_CYCLES);
endif #ifdef SHIFTER_MAX_CYCLES
ifdef COUNTER_LENGTH
BD_CHANGES += updateORCA COUNTER_LENGTH $(COUNTER_LENGTH);
endif #ifdef COUNTER_LENGTH
ifdef ENABLE_EXCEPTIONS
BD_CHANGES += updateORCA ENABLE_EXCEPTIONS $(ENABLE_EXCEPTIONS);
endif #ifdef ENABLE_EXCEPTIONS
ifdef PIPELINE_STAGES
BD_CHANGES += updateORCA PIPELINE_STAGES $(PIPELINE_STAGES);
endif #ifdef PIPELINE_STAGES
ifdef VCP_ENABLE
BD_CHANGES += updateORCA VCP_ENABLE $(VCP_ENABLE);
endif #ifdef VCP_ENABLE
ifdef ENABLE_EXT_INTERRUPTS
BD_CHANGES += updateORCA ENABLE_EXT_INTERRUPTS $(ENABLE_EXT_INTERRUPTS);
endif #ifdef ENABLE_EXT_INTERRUPTS
ifdef NUM_EXT_INTERRUPTS
BD_CHANGES += updateORCA NUM_EXT_INTERRUPTS $(NUM_EXT_INTERRUPTS);
endif #ifdef NUM_EXT_INTERRUPTS
ifdef POWER_OPTIMIZED
BD_CHANGES += updateORCA POWER_OPTIMIZED $(POWER_OPTIMIZED);
endif #ifdef POWER_OPTIMIZED
ifdef FAMILY
BD_CHANGES += updateORCA FAMILY $(FAMILY);
endif #ifdef FAMILY
ifdef LOG2_BURSTLENGTH
BD_CHANGES += updateORCA LOG2_BURSTLENGTH $(LOG2_BURSTLENGTH);
endif #ifdef LOG2_BURSTLENGTH
ifdef AXI_ID_WIDTH
BD_CHANGES += updateORCA AXI_ID_WIDTH $(AXI_ID_WIDTH);
endif #ifdef AXI_ID_WIDTH
ifdef AVALON_AUX
BD_CHANGES += updateORCA AVALON_AUX $(AVALON_AUX);
endif #ifdef AVALON_AUX
ifdef LMB_AUX
BD_CHANGES += updateORCA LMB_AUX $(LMB_AUX);
endif #ifdef LMB_AUX
ifdef WISHBONE_AUX
BD_CHANGES += updateORCA WISHBONE_AUX $(WISHBONE_AUX);
endif #ifdef WISHBONE_AUX
ifdef AUX_MEMORY_REGIONS
BD_CHANGES += updateORCA AUX_MEMORY_REGIONS $(AUX_MEMORY_REGIONS);
endif #ifdef AUX_MEMORY_REGIONS
ifdef AMR0_ADDR_BASE
BD_CHANGES += updateORCA AMR0_ADDR_BASE $(AMR0_ADDR_BASE);
endif #ifdef AMR0_ADDR_BASE
ifdef AMR0_ADDR_LAST
BD_CHANGES += updateORCA AMR0_ADDR_LAST $(AMR0_ADDR_LAST);
endif #ifdef AMR0_ADDR_LAST
ifdef UC_MEMORY_REGIONS
BD_CHANGES += updateORCA UC_MEMORY_REGIONS $(UC_MEMORY_REGIONS);
endif #ifdef UC_MEMORY_REGIONS
ifdef UMR0_ADDR_BASE
BD_CHANGES += updateORCA UMR0_ADDR_BASE $(UMR0_ADDR_BASE);
endif #ifdef UMR0_ADDR_BASE
ifdef UMR0_ADDR_LAST
BD_CHANGES += updateORCA UMR0_ADDR_LAST $(UMR0_ADDR_LAST);
endif #ifdef UMR0_ADDR_LAST
ifdef ICACHE_SIZE
BD_CHANGES += updateORCA ICACHE_SIZE $(ICACHE_SIZE);
endif #ifdef ICACHE_SIZE
ifdef ICACHE_LINE_SIZE
BD_CHANGES += updateORCA ICACHE_LINE_SIZE $(ICACHE_LINE_SIZE);
endif #ifdef ICACHE_LINE_SIZE
ifdef ICACHE_EXTERNAL_WIDTH
BD_CHANGES += updateORCA ICACHE_EXTERNAL_WIDTH $(ICACHE_EXTERNAL_WIDTH);
endif #ifdef ICACHE_EXTERNAL_WIDTH
ifdef INSTRUCTION_REQUEST_REGISTER
BD_CHANGES += updateORCA INSTRUCTION_REQUEST_REGISTER $(INSTRUCTION_REQUEST_REGISTER);
endif #ifdef INSTRUCTION_REQUEST_REGISTER
ifdef INSTRUCTION_RETURN_REGISTER
BD_CHANGES += updateORCA INSTRUCTION_RETURN_REGISTER $(INSTRUCTION_RETURN_REGISTER);
endif #ifdef INSTRUCTION_RETURN_REGISTER
ifdef IUC_REQUEST_REGISTER
BD_CHANGES += updateORCA IUC_REQUEST_REGISTER $(IUC_REQUEST_REGISTER);
endif #ifdef IUC_REQUEST_REGISTER
ifdef IUC_RETURN_REGISTER
BD_CHANGES += updateORCA IUC_RETURN_REGISTER $(IUC_RETURN_REGISTER);
endif #ifdef IUC_RETURN_REGISTER
ifdef IAUX_REQUEST_REGISTER
BD_CHANGES += updateORCA IAUX_REQUEST_REGISTER $(IAUX_REQUEST_REGISTER);
endif #ifdef IAUX_REQUEST_REGISTER
ifdef IAUX_RETURN_REGISTER
BD_CHANGES += updateORCA IAUX_RETURN_REGISTER $(IAUX_RETURN_REGISTER);
endif #ifdef IAUX_RETURN_REGISTER
ifdef IC_REQUEST_REGISTER
BD_CHANGES += updateORCA IC_REQUEST_REGISTER $(IC_REQUEST_REGISTER);
endif #ifdef IC_REQUEST_REGISTER
ifdef IC_RETURN_REGISTER
BD_CHANGES += updateORCA IC_RETURN_REGISTER $(IC_RETURN_REGISTER);
endif #ifdef IC_RETURN_REGISTER
ifdef DCACHE_SIZE
BD_CHANGES += updateORCA DCACHE_SIZE $(DCACHE_SIZE);
endif #ifdef DCACHE_SIZE
ifdef DCACHE_LINE_SIZE
BD_CHANGES += updateORCA DCACHE_LINE_SIZE $(DCACHE_LINE_SIZE);
endif #ifdef DCACHE_LINE_SIZE
ifdef DCACHE_EXTERNAL_WIDTH
BD_CHANGES += updateORCA DCACHE_EXTERNAL_WIDTH $(DCACHE_EXTERNAL_WIDTH);
endif #ifdef DCACHE_EXTERNAL_WIDTH
ifdef DATA_REQUEST_REGISTER
BD_CHANGES += updateORCA DATA_REQUEST_REGISTER $(DATA_REQUEST_REGISTER);
endif #ifdef DATA_REQUEST_REGISTER
ifdef DATA_RETURN_REGISTER
BD_CHANGES += updateORCA DATA_RETURN_REGISTER $(DATA_RETURN_REGISTER);
endif #ifdef DATA_RETURN_REGISTER
ifdef DUC_REQUEST_REGISTER
BD_CHANGES += updateORCA DUC_REQUEST_REGISTER $(DUC_REQUEST_REGISTER);
endif #ifdef DUC_REQUEST_REGISTER
ifdef DUC_RETURN_REGISTER
BD_CHANGES += updateORCA DUC_RETURN_REGISTER $(DUC_RETURN_REGISTER);
endif #ifdef DUC_RETURN_REGISTER
ifdef DAUX_REQUEST_REGISTER
BD_CHANGES += updateORCA DAUX_REQUEST_REGISTER $(DAUX_REQUEST_REGISTER);
endif #ifdef DAUX_REQUEST_REGISTER
ifdef DAUX_RETURN_REGISTER
BD_CHANGES += updateORCA DAUX_RETURN_REGISTER $(DAUX_RETURN_REGISTER);
endif #ifdef DAUX_RETURN_REGISTER
ifdef DC_REQUEST_REGISTER
BD_CHANGES += updateORCA DC_REQUEST_REGISTER $(DC_REQUEST_REGISTER);
endif #ifdef DC_REQUEST_REGISTER
ifdef DC_RETURN_REGISTER
BD_CHANGES += updateORCA DC_RETURN_REGISTER $(DC_RETURN_REGISTER);
endif #ifdef DC_RETURN_REGISTER


$(QSYS_FILE): $(CREATE_QSYS_TCL) updateORCA.tcl $(wildcard config.mk)
	qsys-script --search-path="./,../../rtl/,$$" --cmd="package require qsys; set_project_property DEVICE_FAMILY {$(DEVICE_FAMILY)};set_project_property DEVICE $(DEVICE); source $(CREATE_QSYS_TCL); create_system $@; compose; source updateORCA.tcl; $(BD_CHANGES) save_system $@"

.PHONY: gui-qsys
gui-qsys: $(QSYS_FILE)
	qsys-edit $(QSYS_FILE) --search-path="./,../../rtl/,$$" &

.PHONY: archiveBD
archiveBD: $(QIP_FILE)

$(QIP_FILE): $(QSYS_FILE) ../../rtl/orca_hw.tcl
	if [ -e $(SW_DIR)/Makefile ]; then make -C $(SW_DIR) $(HEX_FILE); fi
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

.PHONY: gui-quartus
gui-quartus: $(QIP_FILE) $(SUBMODULE_FILES) $(TOP_LEVEL_FILES)
	quartus $(QPF_FILE) &


$(MAP_RPT_FILE) : $(QIP_FILE) $(SUBMODULE_FILES) $(TOP_LEVEL_FILES) 
	quartus_map $(QPF_FILE)
$(FIT_RPT_FILE) : $(MAP_RPT_FILE)
	quartus_fit $(QPF_FILE)
$(STA_RPT_FILE) : $(FIT_RPT_FILE)
	quartus_sta $(QPF_FILE)
#$(MIF_RPT_FILE) : $(FIT_RPT_FILE)
#	quartus_cdb --update_mif $(QPF_FILE)
#$(ASM_RPT_FILE) : $(MIF_RPT_FILE)
$(OUTPUT_DIR)/system.sof $(ASM_RPT_FILE) : $(FIT_RPT_FILE)
	quartus_asm $(QPF_FILE)

system.sof: $(OUTPUT_DIR)/system.sof
	cp $(OUTPUT_DIR)/$@ $@

qip: $(QIP_FILE)
map: $(MAP_RPT_FILE)
fit: $(FIT_RPT_FILE)
mif: $(MIF_RPT_FILE)
asm: $(ASM_RPT_FILE)
sta: $(STA_RPT_FILE)

.phony: all clean qip map fit mif asm sta pgm run testbench sim help

testbench: system/simulation/mentor/software/$(HEX_FILE)

system/simulation/mentor/msim_setup.tcl: $(QSYS_FILE) $(SUBMODULE_FILES)
	qsys-generate $(QSYS_FILE) --search-path="./,../../rtl/,$$" --simulation=VHDL 2>&1 | tee ./sim.$(QSYS_FILE).log
	[ -e $@ ]

$(SW_DIR)/$(HEX_FILE):
	$(MAKE) -C $(SW_DIR) $(HEX_FILE)

system/simulation/mentor/software/$(HEX_FILE): system/simulation/mentor/msim_setup.tcl $(SW_DIR)/$(HEX_FILE)
	mkdir -p system/simulation/mentor/software
	cd system/simulation/mentor/software &&	ln -sf ../../../../software/$(HEX_FILE)

sim: system/simulation/mentor/software/$(HEX_FILE)
	vsim -do simulate.tcl

clean:
	rm -rf system/ $(OUTPUT_DIR) $(QSYS_HW_TCL) $(QSYS_FILE)
	rm -rf db/ incremental_db/
	rm -rf *.log system.sopcinfo
	rm -rf system.sof .qsys_edit/
	rm -f *~ \#* PLL*_INFO.txt transcript jtag_init.tcl
	$(MAKE) -C $(SW_DIR)/ clean || true


ifneq ($(BIN_FILE), NONE)
pgm: system.sof
endif #ifneq ($(ELF_FILE), NONE)
pgm:
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
	@echo "   gui-quartus:"
	@echo "     Open the project in the Quartus GUI"
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
	@echo "     Generate testbench from QSYS file"
	@echo
	@echo "   sim:"
	@echo "     Run Modelsim simulator"
	@echo
	@echo "   pgm:"
	@echo "     Program the attached de2-115 board"
	@echo
	@echo "   run:"
	@echo "     Program and run the program from the software directory"

.DELETE_ON_ERROR:
