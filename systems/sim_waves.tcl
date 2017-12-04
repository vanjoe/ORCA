proc orca_reset_waves { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA core status\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/clk $prefix/core/X/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/valid_input $prefix/core/X/pc_current $prefix/core/X/instruction "
    eval "[string trim $add_wave_cmd \"] $prefix/core/D/the_register_file/registers"
}


proc orca_add_wave_axi_data_masters { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA AXI DUC Master\""
    eval "[string trim $add_wave_cmd \"] $prefix/clk $prefix/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/DUC_*"
}

proc orca_add_wave_avalon_data_masters { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Avalon DUC Master\""
    eval "[string trim $add_wave_cmd \"] $prefix/clk $prefix/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/avm_data_*"
}

proc orca_add_wave_axi_instruction_masters { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA AXI IC Master\""
    eval "[string trim $add_wave_cmd \"] $prefix/clk $prefix/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/IC_*"

    eval "[string trim $add_divider_cmd \"] \"ORCA AXI IUC Master\""
    eval "[string trim $add_wave_cmd \"] $prefix/clk $prefix/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/IUC_*"
}

proc orca_add_wave_avalon_instruction_masters { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Avalon IUC Master\""
    eval "[string trim $add_wave_cmd \"] $prefix/clk $prefix/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/avm_instruction_*"
}

proc orca_add_wave_instruction_cache { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA ICache Mux\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_mux/clk $prefix/the_memory_interface/instruction_cache/instruction_cache_mux/reset" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_mux/*" } error

    eval "[string trim $add_divider_cmd \"] \"ORCA ICache\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/instruction_cache/clk $prefix/the_memory_interface/instruction_cache/instruction_cache/reset" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/instruction_cache/*" } error
    catch { eval "[string trim $add_divider_cmd \"] \"ORCA ICache/Cache\"" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/instruction_cache/the_cache/clk" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/instruction_cache/the_cache/*" } error
}

proc orca_add_wave_instruction_fetch { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Instruction Fetch\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/I/clk $prefix/core/I/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/core/I/*"
}

proc orca_add_wave_syscall { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA SysCall\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/syscall/*"
}

proc orca_add_wave_lsu { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Load Store Unit\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/ls_unit/clk"
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/ls_unit/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/ls_unit/*"
}

proc orca_add_wave_execute { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Execute Stage\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/clk"
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/*"
}

proc orca_add_wave_alu { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA ALU\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/clk"
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/alu/*"
    eval "[string trim $add_divider_cmd \"] \"ORCA ALU mul_gen\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/alu/mul_gen/*"
}

proc orca_add_wave_branch { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Branch Unit\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/branch/clk $prefix/core/X/branch/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/branch/*"
}

proc orca_add_wave_all { add_wave_cmd add_divider_cmd prefix axi avalon } {
    if { $axi } {
        orca_add_wave_axi_data_masters $add_wave_cmd $add_divider_cmd $prefix
        orca_add_wave_axi_instruction_masters $add_wave_cmd $add_divider_cmd $prefix
    }
    if { $avalon } {
        orca_add_wave_avalon_data_masters $add_wave_cmd $add_divider_cmd $prefix
        orca_add_wave_avalon_instruction_masters $add_wave_cmd $add_divider_cmd $prefix
    }
    orca_add_wave_instruction_cache $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_instruction_fetch $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_lsu $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_syscall $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_execute $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_alu $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_branch $add_wave_cmd $add_divider_cmd $prefix
}
