proc add_wave_data_masters { } {
    add_wave_divider "ORCA DUC Master"
    add_wave /design_1_wrapper/design_1_i/orca/clk /design_1_wrapper/design_1_i/orca/reset
    add_wave /design_1_wrapper/design_1_i/orca/DUC_*
}

proc add_wave_instruction_masters { } {
    add_wave_divider "ORCA IC Master"
    add_wave /design_1_wrapper/design_1_i/orca/clk /design_1_wrapper/design_1_i/orca/reset
    add_wave /design_1_wrapper/design_1_i/orca/IC_*

    add_wave_divider "ORCA IUC Master"
    add_wave /design_1_wrapper/design_1_i/orca/clk /design_1_wrapper/design_1_i/orca/reset
    add_wave /design_1_wrapper/design_1_i/orca/IUC_*
}

proc add_wave_instruction_cache { } {
    add_wave_divider "ORCA ICache Mux"
    add_wave /design_1_wrapper/design_1_i/orca/U0/axi_enabled/instruction_cache/instruction_cache_mux/clk /design_1_wrapper/design_1_i/orca/U0/axi_enabled/instruction_cache/instruction_cache_mux/reset
    add_wave /design_1_wrapper/design_1_i/orca/U0/axi_enabled/instruction_cache/instruction_cache_mux/*

    add_wave_divider "ORCA ICache"
    add_wave /design_1_wrapper/design_1_i/orca/U0/axi_enabled/instruction_cache/instruction_cache/clk /design_1_wrapper/design_1_i/orca/U0/axi_enabled/instruction_cache/instruction_cache/reset
    add_wave /design_1_wrapper/design_1_i/orca/U0/axi_enabled/instruction_cache/instruction_cache/*

    add_wave_divider "ORCA ICache/Cache"
    add_wave /design_1_wrapper/design_1_i/orca/U0/axi_enabled/instruction_cache/instruction_cache/the_cache/clk
    add_wave /design_1_wrapper/design_1_i/orca/U0/axi_enabled/instruction_cache/instruction_cache/the_cache/*
}

proc add_wave_instruction_fetch { } {
    add_wave_divider "ORCA Instruction Fetch"
    add_wave /design_1_wrapper/design_1_i/orca/U0/core/instr_fetch/clk add_wave /design_1_wrapper/design_1_i/orca/U0/core/instr_fetch/reset
    add_wave add_wave /design_1_wrapper/design_1_i/orca/U0/core/instr_fetch/*
}

proc add_wave_syscall { } {
    add_wave_divider "ORCA SysCall"
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/external_interrupts}} 
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/interrupt_pending}} 
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/interrupt_processor}} 
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/mstatus}} 
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/mie}} 
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/meimask}} 
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/meipend}} 
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/pipeline_empty}} 
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/csr_write_val}} 
    add_wave {{/design_1_wrapper/design_1_i/orca/U0/core/X/syscall/instruction}} 
    add_wave {{/design_1_wrapper/design_1_i/fit_timer/U0/Interrupt}} 
    add_wave {{/design_1_wrapper/design_1_i/edge_extender/U0/interrupt_in}} {{/design_1_wrapper/design_1_i/edge_extender/U0/interrupt_out}} 
    add_wave {{/design_1_wrapper/design_1_i/edge_extender/U0/register_bank}} 
    add_wave {{/design_1_wrapper/design_1_i/edge_extender/U0/reset}} 
}

proc add_wave_lsu { } {
    add_wave_divider "ORCA Load Store Unit"
    add_wave /design_1_wrapper/design_1_i/orca/U0/core/X/ls_unit/clk
    add_wave /design_1_wrapper/design_1_i/orca/U0/core/X/ls_unit/reset
    add_wave /design_1_wrapper/design_1_i/orca/U0/core/X/ls_unit/*
}

proc add_wave_all { } {
    add_wave_data_masters
    add_wave_instruction_masters
    add_wave_instruction_cache
    add_wave_instruction_fetch
    add_wave_syscall
    add_wave_lsu
}
