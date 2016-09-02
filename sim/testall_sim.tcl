cd vblox1/simulation/mentor
do msim_setup.tcl
ld

add wave /vblox1/vectorblox_orca_0/core/D/register_file_1/t3
set files [lsort [glob ../../../test/*.qex]]

foreach f $files {
	 file copy -force $f test.hex
	 restart -f
	 onbreak {resume}
	 when {vblox1/vectorblox_orca_0/core/X/instruction == x"00000073" && vblox1/vectorblox_orca_0/core/X/valid_input == "1" } {stop}
	 when {vblox1/vectorblox_orca_0/core/X/syscall/legal_instruction == "0" && vblox1/vectorblox_orca_0/core/X/syscall/valid == "1"  } {stop}

	 run 2000 ns
	 set v [examine -decimal /vblox1/vectorblox_orca_0/core/D/register_file_1/t3]
	 puts "$f = $v"
}

exit -f;
