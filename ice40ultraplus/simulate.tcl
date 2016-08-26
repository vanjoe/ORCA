
proc com {} {
    set fileset [list \
                     ../rtl/utils.vhd                   \
                     ../rtl/components.vhd              \
                     ../rtl/alu.vhd                     \
                     ../rtl/branch_unit.vhd             \
                     ../rtl/decode.vhd                  \
                     ../rtl/execute.vhd                 \
                     ../rtl/instruction_fetch.vhd       \
                     ../rtl/load_store_unit.vhd         \
                     ../rtl/register_file.vhd           \
                     ../rtl/orca.vhd                    \
                     ../rtl/sys_call.vhd                \
                     ../rtl/wishbone_wrapper.vhd        \
                     ../rtl/plic.vhd                    \
                     ../rtl/gateway.vhd                 \
                     ../rtl/lve_top.vhd                 \
                     ../rtl/4port_mem.vhd               \
                     hdl/top_util_pkg.vhd               \
                     hdl/top_component_pkg.vhd          \
                     hdl/wb_ram.vhd                     \
                     hdl/wb_arbiter.vhd                 \
                     hdl/wb_splitter.vhd                \
                     hdl/wb_pio.vhd                     \
                     hdl/bram.vhd                       \
                     hdl/my_led_sim.v                   \
                     hdl/uart_rd1042/uart_core.vhd      \
                     hdl/uart_rd1042/modem.vhd          \
                     hdl/uart_rd1042/rxcver.vhd         \
                     hdl/uart_rd1042/txcver_fifo.vhd    \
                     hdl/uart_rd1042/rxcver_fifo.vhd    \
                     hdl/uart_rd1042/intface.vhd        \
                     hdl/uart_rd1042/txmitt.vhd         \
                     hdl/pmod_mic/pmod_mic_wb.vhd       \
                     hdl/pmod_mic/pmod_mic_ref_comp.vhd \
                     osc_hf_sim.vhd                     \
                     SB_GB_sim.vhd                      \
                     hdl/i2s_interface/i2s_decode.vhd   \
                     hdl/i2s_interface/i2s_wb.vhd       \
                     top.vhd                            \
                     top_tb.vhd \
							hdl/i2s_tx/i2s_codec.vhd       \
							hdl/i2s_tx/tx_i2s_pack.vhd		 \
							hdl/i2s_tx/gen_control_reg.vhd \
							hdl/i2s_tx/i2s_version.vhd		 \
							hdl/i2s_tx/dpram_rtl.vhd		 \
							hdl/i2s_tx/gen_event_reg.vhd	 \
							hdl/i2s_tx/tx_i2s_wbd.vhd      \
							hdl/i2s_tx/tx_i2s_topm.vhd
					 ]


	 lappend fileset /nfs/opt/lattice/iCEcube2/2016.02/verilog/ABIPTBS8.v
	 lappend fileset /nfs/opt/lattice/iCEcube2/2016.02/verilog/ABIWTCZ4.v
	 lappend fileset /nfs/opt/lattice/iCEcube2/2016.02/verilog/sb_ice_ipenc_modelsim.v
	 lappend fileset /nfs/opt/lattice/iCEcube2/2016.02/verilog/sb_ice_lc.v
	 lappend fileset /nfs/opt/lattice/iCEcube2/2016.02/verilog/sb_ice_syn.v

    ##If you want to view the ram contents of the scratchpad use this file, otherwise the Toolchain files above should work
	 #
	 #  lappend fileset SB_SPRAM256KA.vhd


    vlib work

    foreach f $fileset {
        if { [file extension $f ] == ".v" } {
            vlog -work work -stats=none $f
        } else {
            vcom -work work -2002 -explicit $f
        }
    }
}

proc wave_LVE { } {
    add wave -noupdate -divider "LVE enable (in execute)"
    add wave -hex /top_tb/dut/rv/rv/X/enable_lve/*
    add wave -noupdate -divider "LVE"
    add wave -hex /top_tb/dut/rv/rv/X/enable_lve/lve/*
    add wave -noupdate -divider "LVE Scratchpad"
    add wave -hex /top_tb/dut/rv/rv/X/enable_lve/lve/scratchpad_memory/*
}

proc wave_X { } {
    add wave -noupdate -divider "Execute (full)"
    add wave -hex /top_tb/dut/rv/rv/X/*
}

proc wave_ALU { } {
    add wave -noupdate -divider "ALU (full)"
    add wave -hex /top_tb/dut/rv/rv/X/alu/*
}

proc wave_RF { } {
    add wave -noupdate -divider "Register File (full)"
    add wave -hex /top_tb/dut/rv/rv/D/register_file_1/*
}

proc wave_Top { } {
    add wave -noupdate -divider "Orca top level (full)"
    add wave -hex /top_tb/dut/rv/rv/*
}

proc recom { t {extra_waves false} } {
    noview wave

    com

    vsim work.top_tb
    add log -r *

    add wave -noupdate /top_tb/dut/rv/rv/clk
    add wave -noupdate /top_tb/dut/rv/rv/reset
    add wave -noupdate -divider Decode
    add wave -hex -noupdate /top_tb/dut/rv/rv/D/register_file_1/registers(28)
    add wave -noupdate -divider Execute
    add wave -noupdate /top_tb/dut/rv/rv/X/valid_instr
    add wave -hex -noupdate /top_tb/dut/rv/rv/X/pc_current
    add wave -hex -noupdate /top_tb/dut/rv/rv/X/instruction
    add wave -decimal -noupdate /top_tb/dut/rv/rv/X/syscall/mscratch

    if { $extra_waves } {
	wave_RF
	wave_Top
	wave_X
	wave_ALU
	wave_LVE
    }

    run $t
}

proc rerun { t } {
    restart -f;
    run $t
}

set DefaultRadix hex

config wave -signalnamewidth 2

recom 0
