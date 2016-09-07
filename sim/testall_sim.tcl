cd system/simulation/mentor
do msim_setup.tcl
ld

add wave /system/vectorblox_orca_0/core/D/register_file_1/t3
set files [lsort [glob ../../../test/*.qex]]

foreach f $files {
	 file copy -force $f test.hex
	 restart -f
	 onbreak {resume}
	 when {system/vectorblox_orca_0/core/X/instruction == x"00000073" && system/vectorblox_orca_0/core/X/valid_input == "1" } {stop}
	 #when {system/vectorblox_orca_0/core/X/syscall/legal_instruction == "0" && system/vectorblox_orca_0/core/X/syscall/valid == "1"  } {stop}

	 run 2000 ns
	 set v [examine -decimal /system/vectorblox_orca_0/core/D/register_file_1/t3]
	 puts "$f = $v"
}

exit -f;
