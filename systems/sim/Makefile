-include config.mk
BUS_TYPES := $(filter-out csmith%,$(patsubst system_%.qsys,%,$(wildcard system_*.qsys)))

ifndef BUS_TYPE
$(info INFO: BUS_TYPE not defined, defaulting to avalon )
BUS_TYPE := avalon
endif
ifeq ($(filter $(BUS_TYPE), $(BUS_TYPES)),)
$(error BUS_TYPE $(BUS_TYPE) is not in the list of bus types ($(BUS_TYPES)))
endif

.PHONY: all
all:

SYSTEMS         := $(BUS_TYPES:%=system_%)
SYSTEM          := system_$(BUS_TYPE)
QSYS_FILE       := $(SYSTEM).qsys
QSYS_FILES      := $(BUS_TYPES:%=%.qsys)
SIM_WAVES_FILE  := sim_waves_system_$(BUS_TYPE).tcl
SIM_WAVES_FILES := $(BUS_TYPES:%=sim_waves_system_%.tcl)
SIM_FILE        := simulate_$(BUS_TYPE).tcl
SIM_FILES       := $(BUS_TYPES:%=simulate_%.tcl)
TESTALL_FILE    := testall_$(BUS_TYPE).tcl
TESTALL_FILES   := $(BUS_TYPES:%=testall_%.tcl)
MSIM_FILE       := $(SYSTEM)/simulation/mentor/msim_setup.tcl
MSIM_FILES      := $(SYSTEMS:%=%/simulation/mentor/msim_setup.tcl)

.PHONY: gui-qsys
gui-qsys: $(QSYS_FILE)
	qsys-edit $(QSYS_FILE) --search-path="./,../../rtl/,$$" &

%/simulation/mentor/msim_setup.tcl %/simulation/mentor/test.hex: %.qsys
	qsys-generate --simulation=vhdl $^
	(cd $(*)/simulation/submodules/vblox_orca; for i in *.vhd; do if [ -f ../../../../rtl/$$i ] ; then ln -sf ../../../../rtl/$$i $$i; fi; done; )
	if [ -e $(*)/simulation/submodules/vblox_lve ]; then (cd $(*)/simulation/submodules/vblox_lve; for i in *.vhd; do if [ -f ../../../../rtl/lve/$$i ] ; then ln -sf ../../../../rtl/lve/$$i $$i; fi; done; ); fi

RISCV_TEST_QEXES ?= test/rv32ui-p-add.qex
$(RISCV_TEST_QEXES):
	../../tools/generate_hex_files.sh

ORCA_ROOT       ?= ../..
ORCA_TEST_DIRS  ?= $(shell find $(ORCA_ROOT)/software/orca-tests -mindepth 2 -name 'Makefile' | xargs -n 1 dirname)
ORCA_TEST_ELFS  := $(patsubst %,test/%.elf,$(notdir $(ORCA_TEST_DIRS)))
ORCA_TEST_DUMPS := $(patsubst %,test/%.dump,$(notdir $(ORCA_TEST_DIRS)))
ORCA_TEST_QEXES := $(patsubst %,test/%.qex,$(notdir $(ORCA_TEST_DIRS)))
PWD_ABSPATH     := $(abspath $(shell pwd))
LD_SCRIPT       := $(PWD_ABSPATH)/link.ld
test/%.elf test/%.qex test/%.dump: | test
	$(MAKE) -C $(ORCA_ROOT)/software/orca-tests/$*/ $(PWD_ABSPATH)/test/$*.elf $(PWD_ABSPATH)/test/$*.qex $(PWD_ABSPATH)/test/$*.dump OUTPUT_DIR=$(PWD_ABSPATH)/test LD_SCRIPT=$(LD_SCRIPT) RISCV_OLEVEL=-O3
test:
	mkdir -p $@

.PHONY: sw
sw: $(ORCA_TEST_QEXES) $(RISCV_TEST_QEXES)

simulate_%.tcl: simulate.tcl
	sed 's/system/system_$(*)/g' $^ > $@
sim_waves_system_%.tcl: sim_waves_system.tcl
	sed 's/system/system_$(*)/g' $^ > $@
testall_%.tcl: testall.tcl
	sed 's/system/system_$(*)/g' $^ > $@


.PHONY: testone
testone: $(RISCV_TEST_QEXES) $(ORCA_TEST_QEXES) $(MSIM_FILE) $(TESTALL_FILE)
	vsim -c -do $(TESTALL_FILE) | egrep '(^[^#]|Error:|Error \(suppressible\):)' | tee test_$(BUS_TYPE).log

.PHONY: testall
testall: $(RISCV_TEST_QEXES) $(ORCA_TEST_QEXES) $(MSIM_FILES) $(TESTALL_FILES)
	for bus_type in $(BUS_TYPES); do vsim -c -do testall_$${bus_type}.tcl | egrep '(^[^#]|Error:|Error \(suppressible\):)' | tee test_$${bus_type}.log; done

.PHONY: all
all: $(RISCV_TEST_QEXES) $(ORCA_TEST_QEXES) $(MSIM_FILES) $(TESTALL_FILES)

.PHONY: sim
sim: all $(SIM_FILE) $(SIM_WAVES_FILE) $(MSIM_FILE)
	cd $(SYSTEM)/simulation/mentor/; ln -sf ../../../test.hex .
	cd -
	vsim -do $(SIM_FILE)

.PHONY: clean
clean:
	rm -rf $(SYSTEMS) test test.hex $(SIM_WAVE_FILES) $(SIM_FILES) $(TESTALL_FILES)
	rm -rf transcript *.sopcinfo platform.info csmith-compile *~ \#*
	rm -rf .qsys_edit

.DELETE_ON_ERROR:
