cd system/simulation/mentor
do msim_setup.tcl
ld

add wave /system/vectorblox_orca_0/core/D/the_register_file/t3
set files [lsort [glob ../../../test/*.qex]]

set max_length  0
foreach f $files {
    set len [string length $f ]
    if { $len > $max_length } {
        set max_length $len
    }
}

foreach f $files {
    file copy -force $f test.hex
    restart -f
    onbreak {resume}
    when {system/vectorblox_orca_0/core/X/to_execute_instruction(31:0) == x"00000073" && system/vectorblox_orca_0/core/X/to_execute_valid == "1" } {stop}

    if { [string match "*dhrystone*" $f ] } {
        #Dhrystone does multiple runs to at least 100us
        run 500 us
    } elseif { [string match "*.elf*" $f ] } {
        #some of the unit tests may have to run for a much longer time
        run 60 us
    } else {
        run 30 us
    }
    set instruction [examine -radix hex system/vectorblox_orca_0/core/X/to_execute_instruction(31:0)]
    set valid       [examine system/vectorblox_orca_0/core/X/to_execute_valid]
    if { ($instruction != "00000073") || ($valid != "1") } {
        set validString "valid"
        if { $valid != "1" } {
            set validString "invalid"
        }
        puts [format "%-${max_length}s = Error  FAIL  Instruction $instruction %s" $f $validString ]
    } else {
        set returnValue [examine -radix decimal /system/vectorblox_orca_0/core/D/the_register_file/t3]
        set passfail  ""
        if { $returnValue != 1 } {
            if { [string match "*dhrystone*" $f ] } {
                set passfail "MIPS@100MHz"
            } else {
                set passfail "FAIL"
            }
        }
        puts [format "%-${max_length}s = %-6d %s" $f $returnValue $passfail ]
    }
}

exit -f;
