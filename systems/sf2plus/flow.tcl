if { $argc != 1 } {
	puts $argc
	puts $argv
	puts $argv0
	puts "This build script requires exactly one argument."
	puts "Exiting."
	exit

} else {
	open_project -file {./sf2plus.prjx} -do_backup_on_convert 1 -backup_file {../sf2plus.zip}
	refresh
	set arg [lindex $argv 0]
	puts "Arg is $arg."

	if {$arg eq "clean"} {
		puts "Cleaning..."
		clean_tool -name {PROGRAMDEVICE} 
		clean_tool -name {GENERATEPROGRAMMINGFILE} 
		clean_tool -name {GENERATEPROGRAMMINGDATA} 
		clean_tool -name {PLACEROUTE} 
		clean_tool -name {COMPILE} 
		clean_tool -name {SYNTHESIZE} 

	} elseif {$arg eq "synthesis"} {
		puts "Synthesizing..."

		# Note: I can't get these commands to work. They are undocumented in the Libero TCL handbook, but they are recognized
		# as commands by the Libero tools. I tried to guess the format of the arguments to this command based on the following
		# stackexchange post and the directory structure of the project:
		# https://electronics.stackexchange.com/questions/151482/tcl-command-in-libero-soc-microsemi-to-generate-the-ip-cores 
		# It's possible that it's a holdover from an older version of Libero, but this seems like the closest I can get to generating
		# the .cxf components from the command line.

		#create_design -id {work:my_mss} -design_name {my_mss}
		#create_design -id {work:my_mss_top} -design_name {my_mss}
		#create_design -id {work:Top_Fabric_Master} -design_name {Top_Fabric_Master}

		run_tool -name {SYNTHESIZE}

	} elseif {$arg eq "compile"} {
		puts "Compiling..."
		organize_tool_files -tool {COMPILE} -file {./constraint/io/Top_Fabric_Master.io.pdc} -module {Top_Fabric_Master::work} \
			-input_type {constraint}
		run_tool -name {COMPILE}

	} elseif {$arg eq "place_and_route"} {
		puts "Placing and Routing..."
		run_tool -name {PLACEROUTE}

	} elseif {$arg eq "verify_timing"} {
		puts "Verifying Timing..."
		run_tool -name {VERIFYTIMING}

	} elseif {$arg eq "gen_prog_data"} {
		puts "Generating Programming Data..."
		run_tool -name {GENERATEPROGRAMMINGDATA}

	} elseif {$arg eq "gen_prog_file"} {
		puts "Generating Programming File..."
		run_tool -name {GENERATEPROGRAMMINGFILE}

	} elseif {$arg eq "program"} {
		puts "Programming Device..."
		run_tool -name {PROGRAMDEVICE}

	} elseif {$arg eq "clean_bit"} {
		puts "Cleaning Programming Tool..."
		clean_tool -name {PROGRAMDEVICE} 

	} else {
		puts "Unrecognized command."
		puts "Exiting."
	}

	close_project -save 1
	exit
}





#open_project -file {./sf2plus.prjx} -do_backup_on_convert 1 -backup_file {../sf2plus.zip}
#refresh
#run_tool -name {SYNTHESIZE}
#organize_tool_files -tool {COMPILE} -file {./constraint/io/Top_Fabric_Master.io.pdc} -module {Top_Fabric_Master::work} -input_type {constraint}
#run_tool -name {COMPILE}
#run_tool -name {PLACEROUTE}
#run_tool -name {GENERATEPROGRAMMINGDATA} 
#run_tool -name {GENERATEPROGRAMMINGFILE} 
#run_tool -name {PROGRAMDEVICE} 
#close_project -save 1
