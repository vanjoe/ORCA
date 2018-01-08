proc orca_reset_waves { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA core status\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/clk $prefix/core/X/reset"
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/to_execute_valid $prefix/core/X/to_execute_program_counter $prefix/core/X/to_execute_instruction "
    eval "[string trim $add_wave_cmd \"] $prefix/core/D/the_register_file/registers"
}


proc orca_add_wave_data_masters { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA AXI DC Master\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/data_cache_gen/dc_master/*" } error
    eval "[string trim $add_divider_cmd \"] \"ORCA AXI DC Throttler\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/data_cache_gen/dc_master/request_throttler/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/data_cache_gen/dc_master/request_throttler/throttle_gen/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/data_cache_gen/dc_master/request_throttler/throttle_gen/one_outstanding_request_gen/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/data_cache_gen/dc_master/request_throttler/throttle_gen/multiple_outstanding_requests_gen/*" } error

    eval "[string trim $add_divider_cmd \"] \"ORCA AXI DUC Master\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/duc_master/*" } error
    eval "[string trim $add_divider_cmd \"] \"ORCA AXI DUC Throttler\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/duc_master/request_throttler/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/duc_master/request_throttler/throttle_gen/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/duc_master/request_throttler/throttle_gen/one_outstanding_request_gen/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/duc_master/request_throttler/throttle_gen/multiple_outstanding_requests_gen/*" } error

    eval "[string trim $add_divider_cmd \"] \"ORCA Avalon AUX Master\""
    eval "[string trim $add_wave_cmd \"] $prefix/avm_data_*"
}

proc orca_add_wave_instruction_masters { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA AXI IC Master\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/ic_master/*" } error
    eval "[string trim $add_divider_cmd \"] \"ORCA AXI IC Throttler\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/ic_master/request_throttler/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/ic_master/request_throttler/throttle_gen/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/ic_master/request_throttler/throttle_gen/one_outstanding_request_gen/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/ic_master/request_throttler/throttle_gen/multiple_outstanding_requests_gen/*" } error

    eval "[string trim $add_divider_cmd \"] \"ORCA AXI IUC Master\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/iuc_master/*" } error
    eval "[string trim $add_divider_cmd \"] \"ORCA AXI IUC Throttler\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/iuc_master/request_throttler/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/iuc_master/request_throttler/throttle_gen/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/iuc_master/request_throttler/throttle_gen/one_outstanding_request_gen/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/uc_masters_gen/iuc_master/request_throttler/throttle_gen/multiple_outstanding_requests_gen/*" } error

    eval "[string trim $add_divider_cmd \"] \"ORCA Avalon IUC Master\""
    eval "[string trim $add_wave_cmd \"] $prefix/avm_instruction_*"
}

proc orca_add_wave_instruction_cache { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA ICache Mux\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_mux/*" } error

    eval "[string trim $add_divider_cmd \"] \"ORCA ICache\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/instruction_cache/*" } error
    catch { eval "[string trim $add_divider_cmd \"] \"ORCA ICache/Cache\"" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/instruction_cache_gen/instruction_cache/the_cache/*" } error
}

proc orca_add_wave_data_cache { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA DCache Mux\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/data_cache_mux/*" } error

    eval "[string trim $add_divider_cmd \"] \"ORCA DCache\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/data_cache_gen/data_cache/*" } error
    catch { eval "[string trim $add_divider_cmd \"] \"ORCA DCache/Cache\"" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/the_memory_interface/data_cache_gen/data_cache/the_cache/*" } error
}

proc orca_add_wave_instruction_fetch { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Instruction Fetch\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/I/*"
    eval "[string trim $add_divider_cmd \"] \"ORCA BTB\""
    catch { eval "[string trim $add_wave_cmd \"] $prefix/core/I/btb_gen/*" } error
    catch { eval "[string trim $add_wave_cmd \"] $prefix/core/I/btb_gen/multiple_entries_gen/*" } error
}

proc orca_add_wave_syscall { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA SysCall\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/syscall/*"
}

proc orca_add_wave_lsu { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Load Store Unit\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/ls_unit/*"
}

proc orca_add_wave_execute { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Execute Stage\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/*"
}

proc orca_add_wave_alu { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA ALU\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/alu/*"
    eval "[string trim $add_divider_cmd \"] \"ORCA ALU mul_gen\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/alu/mul_gen/*"
}

proc orca_add_wave_branch { add_wave_cmd add_divider_cmd prefix } {
    eval "[string trim $add_divider_cmd \"] \"ORCA Branch Unit\""
    eval "[string trim $add_wave_cmd \"] $prefix/core/X/branch/*"
    catch { eval "[string trim $add_wave_cmd \"] $prefix/core/X/branch/has_predictor_gen/*" } error
}

proc orca_add_wave_all { add_wave_cmd add_divider_cmd prefix } {
    orca_add_wave_instruction_masters $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_instruction_cache $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_data_masters $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_data_cache $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_instruction_fetch $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_execute $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_alu $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_branch $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_lsu $add_wave_cmd $add_divider_cmd $prefix
    orca_add_wave_syscall $add_wave_cmd $add_divider_cmd $prefix
}
