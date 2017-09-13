source sim_waves.tcl

proc reset_sim { } {
    catch { close_sim -force }
    reset_simulation -simset sim_1 -mode behavioral
    reset_target simulation [get_files *design_1.bd]
    exec rm -rf project/project.ip_user_files
    update_ip_catalog -rebuild -scan_changes
    upgrade_ip [get_ips *]
    report_ip_status -name ip_status
    generate_target simulation [get_files *design_1.bd]
}

proc start_sim { {run_time 0} } {
    catch { launch_simulation }

    reset_waves
    
    restart
    log_wave -r *
    run 1 ps

    add_force /design_1_wrapper/design_1_i/xlconstant_bypass_ps7_uart_dout {1 0ns}

    set coe_file [open "software/test.coe" r]
    set coe_data [read $coe_file]
    close $coe_file

    set i 0
    set data [split $coe_data "\n"]
    foreach line $data {
        set words [regexp -all -inline {\S+} $line]
        #puts $words
        foreach word $words {
            set byte0 ""
            append byte0 [string index $word 6]
            append byte0 [string index $word 7]
            set_value "/design_1_wrapper/design_1_i/idram/U0/ram/\\idram_gen(0)\\/bram/ram[$i]" -radix hex $byte0 
            set byte1 ""
            append byte1 [string index $word 4]
            append byte1 [string index $word 5]
            set_value "/design_1_wrapper/design_1_i/idram/U0/ram/\\idram_gen(1)\\/bram/ram[$i]" -radix hex $byte1
            set byte2 ""
            append byte2 [string index $word 2]
            append byte2 [string index $word 3]
            set_value "/design_1_wrapper/design_1_i/idram/U0/ram/\\idram_gen(2)\\/bram/ram[$i]" -radix hex $byte2 
            set byte3 "" 
            append byte3 [string index $word 0]
            append byte3 [string index $word 1]
            set_value "/design_1_wrapper/design_1_i/idram/U0/ram/\\idram_gen(3)\\/bram/ram[$i]" -radix hex $byte3 
            set i [expr {$i + 1}]
        }
    }
    run $run_time
}
