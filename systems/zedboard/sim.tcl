close_wave_config -force

add_wave_divider "Top level"
add_wave /design_1_wrapper/design_1_i/processing_system7_0_FCLK_CLK0 /design_1_wrapper/design_1_i/processing_system7_0_FCLK_RESET0_N /design_1_wrapper/design_1_i/clk_wiz_clk_out1 /design_1_wrapper/design_1_i/clock_clk_2x_out /design_1_wrapper/design_1_i/clock_peripheral_reset /design_1_wrapper/design_1_i/rst_clk_wiz_100M_interconnect_aresetn /design_1_wrapper/design_1_i/rst_clk_wiz_100M_peripheral_aresetn /design_1_wrapper/design_1_i/leds_8bits_tri_o

add_wave_divider "ORCA core status"
add_wave /design_1_wrapper/design_1_i/Orca/U0/core/X/clk /design_1_wrapper/design_1_i/Orca/U0/core/X/reset
add_wave /design_1_wrapper/design_1_i/Orca/U0/core/X/valid_input /design_1_wrapper/design_1_i/Orca/U0/core/X/pc_current /design_1_wrapper/design_1_i/Orca/U0/core/X/instruction 

add_wave_divider "ORCA DUC Master"
add_wave /design_1_wrapper/design_1_i/Orca/clk /design_1_wrapper/design_1_i/Orca/reset
add_wave /design_1_wrapper/design_1_i/Orca/DUC_*

add_wave_divider "ORCA IC Master"
add_wave /design_1_wrapper/design_1_i/Orca/clk /design_1_wrapper/design_1_i/Orca/reset
add_wave /design_1_wrapper/design_1_i/Orca/IC_*

add_wave_divider "ORCA IUC Master"
add_wave /design_1_wrapper/design_1_i/Orca/clk /design_1_wrapper/design_1_i/Orca/reset
add_wave /design_1_wrapper/design_1_i/Orca/IUC_*

add_wave_divider "ORCA ICache Mux"
add_wave /design_1_wrapper/design_1_i/Orca/U0/axi_enabled/instruction_cache/instruction_cache_mux/clk /design_1_wrapper/design_1_i/Orca/U0/axi_enabled/instruction_cache/instruction_cache_mux/reset
add_wave /design_1_wrapper/design_1_i/Orca/U0/axi_enabled/instruction_cache/instruction_cache_mux/*

add_wave_divider "ORCA ICache"
add_wave /design_1_wrapper/design_1_i/Orca/U0/axi_enabled/instruction_cache/instruction_cache/clk /design_1_wrapper/design_1_i/Orca/U0/axi_enabled/instruction_cache/instruction_cache/reset
add_wave /design_1_wrapper/design_1_i/Orca/U0/axi_enabled/instruction_cache/instruction_cache/*

add_wave_divider "ORCA ICache/Cache"
add_wave /design_1_wrapper/design_1_i/Orca/U0/axi_enabled/instruction_cache/instruction_cache/the_cache/clk
add_wave /design_1_wrapper/design_1_i/Orca/U0/axi_enabled/instruction_cache/instruction_cache/the_cache/*

add_wave_divider "ORCA SysCall"
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/external_interrupts}} 
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/interrupt_pending}} 
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/interrupt_processor}} 
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/mstatus}} 
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/mie}} 
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/meimask}} 
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/meipend}} 
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/pipeline_empty}} 
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/csr_write_val}} 
add_wave {{/design_1_wrapper/design_1_i/Orca/U0/core/X/syscall/instruction}} 
add_wave {{/design_1_wrapper/design_1_i/fit_timer/U0/Interrupt}} 
add_wave {{/design_1_wrapper/design_1_i/edge_extender/U0/interrupt_in}} {{/design_1_wrapper/design_1_i/edge_extender/U0/interrupt_out}} 
add_wave {{/design_1_wrapper/design_1_i/edge_extender/U0/register_bank}} 
add_wave {{/design_1_wrapper/design_1_i/edge_extender/U0/reset}} 

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
