cd  system/testbench/mentor/
do msim_setup.tcl
ld
add wave -position insertpoint  /system_tb/system_inst/riscv_0/coe_to_host

set files [lsort [glob ../../../test/*.qex]]

foreach f $files {
	 file copy -force $f test.hex
	 restart -f
	 onbreak {resume}
	 when {(/system_tb/system_inst/riscv_0/X/instruction == x"00000073" && /system_tb/system_inst/riscv_0/X/valid_input == "1") || (/system_tb/system_inst/riscv_0/coe_to_host == x"00000539")} {stop}
	 run 30 us
	 set v [examine -decimal /system_tb/system_inst/riscv_0/D/register_file_1/t3 ]
	 puts "$f = $v"
}

exit -f;
