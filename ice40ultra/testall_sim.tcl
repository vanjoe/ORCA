do simulate.tcl

set files [lsort [glob ./test/*.mem]]

foreach f $files {
	 file copy -force $f test.mem
	 exec touch test.mem
	 exec make imem.mem dmem.mem
	 restart -f
	 onbreak {resume}
	 when {/top_tb/dut/rv/rv/X/syscall/mtohost /= x"00000000" } {stop}
	 run 2000 us
	 set v [examine -decimal /top_tb/dut/rv/rv/X/syscall/mtohost]
	 puts "$f = $v"
}

exit -f;
