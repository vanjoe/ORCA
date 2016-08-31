do simulate.tcl

set files [lsort [glob ./test/*.mem]]
add wave /top_tb/dut/rv/core/D/register_file_1/t3
foreach f $files {
	 file copy -force $f test.mem
	 exec touch test.mem
	 exec make imem.mem dmem.mem
	 restart -f
	 onbreak {resume}
	 when {/top_tb/dut/rv/core/X/instruction == x"00000073" && /top_tb/dut/rv/core/X/valid_input == "1" } {stop}
	 when {/top_tb/dut/rv/core//X/syscall/legal_instruction == "0" && /top_tb/dut/rv/core//X/syscall/valid == "1"  } {stop}
	 run 2000 us
	 set v [examine -decimal /top_tb/dut/rv/core/D/register_file_1/t3 ]
	 puts "$f = $v"
}

exit -f;
