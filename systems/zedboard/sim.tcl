proc reset_sim { } {
    catch { close_sim -force }
    reset_simulation -simset sim_1 -mode behavioral
    reset_target simulation [get_files *design_1.bd]
    exec rm -rf project/project.ip_user_files
    update_ip_catalog -rebuild -scan_changes
    upgrade_ip [get_ips *]
    report_ip_status -name ip_status
    generate_target simulation [get_files *design_1.bd]
#    export_ip_user_files -of_objects [get_files *design_1.bd] -no_script -force -quiet
#    export_simulation -of_objects [get_files *design_1.bd] -directory project/project.ip_user_files/sim_scripts -ip_user_files_dir project/project.ip_user_files -ipstatic_source_dir project.ip_user_files/ipstatic -lib_map_path [list {modelsim=project.cache/compile_simlib/modelsim} {questa=project.cache/compile_simlib/questa} {ies=project.cache/compile_simlib/ies} {vcs=project.cache/compile_simlib/vcs} {riviera=project.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
}

proc start_sim { {run_time 0} } {
    catch { launch_simulation }
    close_wave_config -force

    add_wave_divider "Top level"
    add_wave /design_1_wrapper/design_1_i/processing_system7_0_FCLK_CLK0 /design_1_wrapper/design_1_i/processing_system7_0_FCLK_RESET0_N /design_1_wrapper/design_1_i/clk_wiz_clk_out1 /design_1_wrapper/design_1_i/clock_clk_2x_out /design_1_wrapper/design_1_i/clock_peripheral_reset /design_1_wrapper/design_1_i/rst_clk_wiz_100M_interconnect_aresetn /design_1_wrapper/design_1_i/rst_clk_wiz_100M_peripheral_aresetn /design_1_wrapper/design_1_i/leds_8bits_tri_o

    add_wave_divider "ORCA core status"
    add_wave /design_1_wrapper/design_1_i/orca/U0/core/X/clk /design_1_wrapper/design_1_i/orca/U0/core/X/reset
    add_wave /design_1_wrapper/design_1_i/orca/U0/core/X/valid_input /design_1_wrapper/design_1_i/orca/U0/core/X/pc_current /design_1_wrapper/design_1_i/orca/U0/core/X/instruction 
    add_wave /design_1_wrapper/design_1_i/orca/U0/core/D/register_file_1/registers
    
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
            #puts $byte0
            set_value "/design_1_wrapper/design_1_i/idram/U0/ram/\\idram_gen(0)\\/bram/ram[$i]" -radix hex $byte0 
            set byte1 ""
            append byte1 [string index $word 4]
            append byte1 [string index $word 5]
            #puts $byte1
            set_value "/design_1_wrapper/design_1_i/idram/U0/ram/\\idram_gen(1)\\/bram/ram[$i]" -radix hex $byte1
            set byte2 ""
            append byte2 [string index $word 2]
            append byte2 [string index $word 3]
            #puts $byte2
            set_value "/design_1_wrapper/design_1_i/idram/U0/ram/\\idram_gen(2)\\/bram/ram[$i]" -radix hex $byte2 
            set byte3 "" 
            append byte3 [string index $word 0]
            append byte3 [string index $word 1]
            #puts $byte3
            set_value "/design_1_wrapper/design_1_i/idram/U0/ram/\\idram_gen(3)\\/bram/ram[$i]" -radix hex $byte3 
            set i [expr {$i + 1}]
        }
    }
    run $run_time
}

source sim_waves.tcl
