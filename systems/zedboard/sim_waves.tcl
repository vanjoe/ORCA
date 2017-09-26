source ../sim_waves.tcl

proc reset_waves { } {
    catch { close_wave_config -force } error

    add_wave_divider "Top level"
    add_wave /design_1_wrapper/design_1_i/processing_system7_0_FCLK_CLK0 /design_1_wrapper/design_1_i/processing_system7_0_FCLK_RESET0_N /design_1_wrapper/design_1_i/clk_wiz_clk_out1 /design_1_wrapper/design_1_i/clock_clk_2x_out /design_1_wrapper/design_1_i/clock_peripheral_reset /design_1_wrapper/design_1_i/rst_clk_wiz_100M_interconnect_aresetn /design_1_wrapper/design_1_i/rst_clk_wiz_100M_peripheral_aresetn /design_1_wrapper/design_1_i/leds_8bits_tri_o

    add_wave_divider "Interrupts"
    add_wave /design_1_wrapper/design_1_i/fit_timer/U0/Interrupt 
    add_wave /design_1_wrapper/design_1_i/edge_extender/U0/interrupt_in /design_1_wrapper/design_1_i/edge_extender/U0/interrupt_out 
    add_wave /design_1_wrapper/design_1_i/edge_extender/U0/register_bank 
    add_wave /design_1_wrapper/design_1_i/edge_extender/U0/reset
    
    orca_reset_waves add_wave add_wave_divider /design_1_wrapper/design_1_i/orca
}
    

proc add_wave_data_masters { } {
    orca_add_wave_axi_data_masters add_wave add_wave_divider /design_1_wrapper/design_1_i/orca
}

proc add_wave_instruction_masters { } {
    orca_add_wave_axi_instruction_masters add_wave add_wave_divider /design_1_wrapper/design_1_i/orca
}

proc add_wave_instruction_cache { } {
    orca_add_wave_instruction_cache add_wave add_wave_divider /design_1_wrapper/design_1_i/orca
}

proc add_wave_instruction_fetch { } {
    orca_add_wave_instruction_fetch add_wave add_wave_divider /design_1_wrapper/design_1_i/orca
}

proc add_wave_syscall { } {
    orca_add_wave_syscall add_wave add_wave_divider /design_1_wrapper/design_1_i/orca
}

proc add_wave_lsu { } {
    orca_add_wave_lsu add_wave add_wave_divider /design_1_wrapper/design_1_i/orca
}

proc add_wave_execute { } {
    orca_add_wave_execute add_wave add_wave_divider /design_1_wrapper/design_1_i/orca
}

proc add_wave_alu { } {
    orca_add_wave_alu add_wave add_wave_divider /design_1_wrapper/design_1_i/orca
}

proc add_wave_all { } {
    orca_add_wave_all add_wave add_wave_divider /design_1_wrapper/design_1_i/orca true false
}
