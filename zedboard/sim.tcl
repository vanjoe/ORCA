add_wave {{/design_1_wrapper/design_1_i/Orca_0/U0/core/X/clk}} {{/design_1_wrapper/design_1_i/Orca_0/U0/core/X/reset}} {{/design_1_wrapper/design_1_i/Orca_0/U0/core/X/valid_input}} {{/design_1_wrapper/design_1_i/Orca_0/U0/core/X/pc_current}} {{/design_1_wrapper/design_1_i/Orca_0/U0/core/X/instruction}} 

restart
run 1 ps

set coe_file [open "software/test.coe" r]
set coe_data [read $coe_file]
close $coe_file

set i 0
set data [split $coe_data "\n"]
foreach line $data {
  set words [regexp -all -inline {\S+} $line]
  puts $words
  foreach word $words {
    puts $word
    set_value "/design_1_wrapper/design_1_i/BRAM/blk_mem_gen_0/inst/\\native_mem_mapped_module.blk_mem_gen_v8_3_6_inst /memory[$i]" -radix hex $word 
    set i [expr {$i + 1}]
  }
}

run 1500 us
