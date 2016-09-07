

ifndef BUS_TYPE
$(error ERROR: define BUS_TYPE to 'avalon' or 'axi')
endif

all:

SOURCE_QSYS=system_$(BUS_TYPE).qsys

ORCA_FILES=$(wildcard rtl/*.vhd)

ORCA_COPY_FILES=$(addprfix system/simulation/submodules/, $(notdir $(ORCA_FILES)))

system.qsys:$(SOURCE_QSYS)
	cp -f $^ $@

system/simulation/mentor/msim_setup.tcl: system.qsys
	qsys-generate --simulation=vhdl system.qsys
	( cd system/simulation/submodules/; for i in *.vhd; do if [ -f ../../../rtl/$$i ] ; then ln -sf ../../../rtl/$$i $$i; fi; done; )

test/rv32ui-p-add.qex:
	../tools/generate_hex_files.sh

testall: test/rv32ui-p-add.qex system/simulation/mentor/msim_setup.tcl
	vsim -c -do testall_sim.tcl | grep '\.qex'

all: system/simulation/mentor/msim_setup.tcl
	(cd system/simulation/mentor/; ln -sf ../../../test.hex .)

clean:
	rm -rf system system.qsys
