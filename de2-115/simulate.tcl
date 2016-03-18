cd system/testbench/mentor
exec ln -sf ../../../test.hex .
do msim_setup.tcl
ld

proc re_run { t } {

	 restart -f ;
	 force -freeze sim:/system_tb/system_inst/altpll_0/areset 0 0
	 run $t
}

add log -r *

add wave -noupdate /system_tb/system_inst/vectorblox_orca_0/clk
add wave -noupdate /system_tb/system_inst/vectorblox_orca_0/reset
add wave -noupdate /system_tb/system_inst/vectorblox_orca_0/coe_to_host
add wave -noupdate -divider Decode
add wave -noupdate /system_tb/system_inst/vectorblox_orca_0/D/register_file_1/registers(28)
add wave -noupdate -divider Execute
add wave -noupdate /system_tb/system_inst/vectorblox_orca_0/X/valid_instr
add wave -noupdate /system_tb/system_inst/vectorblox_orca_0/X/pc_current
add wave -noupdate /system_tb/system_inst/vectorblox_orca_0/X/instruction

force -freeze sim:/system_tb/system_inst/altpll_0/areset 0 0
set DefaultRadix hex
