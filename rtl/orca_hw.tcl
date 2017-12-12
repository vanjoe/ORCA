#
# Orca "Orca" v1.0
#  2015.11.09.13:16:38
#
#

#
# request TCL package from ACDS 15.0
#
package require -exact qsys 15.0

proc log2 { num } {
    set retval 0
    while { $num > 1 } {
        set retval [expr $retval + 1 ]
        set num [expr $num / 2 ]
    }
    return $retval
}
#
# module orca
#
set_module_property DESCRIPTION "Orca, a RISC-V implementation by Vectorblox"
set_module_property NAME vectorblox_orca
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR "VectorBlox Computing Inc."
set_module_property GROUP "VectorBlox Computing Inc./Processors"
set_module_property DISPLAY_NAME "Orca (RISC-V)"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false
set_module_property ELABORATION_CALLBACK elaboration_callback
add_documentation_link "Documentation" https://github.com/VectorBlox/risc-v
#
# file sets
#
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL Orca
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file vblox_orca/utils.vhd VHDL PATH utils.vhd
add_fileset_file vblox_orca/constants_pkg.vhd VHDL PATH constants_pkg.vhd
add_fileset_file vblox_orca/components.vhd VHDL PATH components.vhd
add_fileset_file vblox_orca/alu.vhd VHDL PATH alu.vhd
add_fileset_file vblox_orca/branch_unit.vhd VHDL PATH branch_unit.vhd
add_fileset_file vblox_orca/decode.vhd VHDL PATH decode.vhd
add_fileset_file vblox_orca/execute.vhd VHDL PATH execute.vhd
add_fileset_file vblox_orca/instruction_fetch.vhd VHDL PATH instruction_fetch.vhd
add_fileset_file vblox_orca/load_store_unit.vhd VHDL PATH load_store_unit.vhd
add_fileset_file vblox_orca/register_file.vhd VHDL PATH register_file.vhd
add_fileset_file vblox_orca/orca.vhd VHDL PATH orca.vhd TOP_LEVEL_FILE
add_fileset_file vblox_orca/orca_core.vhd VHDL PATH orca_core.vhd TOP_LEVEL_FILE
add_fileset_file vblox_orca/sys_call.vhd VHDL PATH sys_call.vhd
add_fileset_file vblox_orca/4port_mem.vhd VHDL PATH 4port_mem.vhd
add_fileset_file vblox_orca/lve_top.vhd VHDL PATH lve_top.vhd
add_fileset_file vblox_orca/a4l_master.vhd VHDL PATH a4l_master.vhd
add_fileset_file vblox_orca/axi_master.vhd VHDL PATH axi_master.vhd
add_fileset_file vblox_orca/cache_mux.vhd VHDL PATH cache_mux.vhd
add_fileset_file vblox_orca/oimm_register.vhd VHDL PATH oimm_register.vhd
add_fileset_file vblox_orca/oimm_throttler.vhd VHDL PATH oimm_throttler.vhd
add_fileset_file vblox_orca/memory_interface.vhd VHDL PATH memory_interface.vhd
add_fileset_file vblox_orca/cache_controller.vhd VHDL PATH cache_controller.vhd
add_fileset_file vblox_orca/cache.vhd VHDL PATH cache.vhd
add_fileset_file vblox_orca/bram_sdp_write_first.vhd VHDL PATH bram_sdp_write_first.vhd

add_fileset SIM_VHDL SIM_VHDL "" ""
set_fileset_property SIM_VHDL TOP_LEVEL Orca
set_fileset_property SIM_VHDL ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VHDL ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file vblox_orca/utils.vhd VHDL PATH utils.vhd
add_fileset_file vblox_orca/constants_pkg.vhd VHDL PATH constants_pkg.vhd
add_fileset_file vblox_orca/components.vhd VHDL PATH components.vhd
add_fileset_file vblox_orca/alu.vhd VHDL PATH alu.vhd
add_fileset_file vblox_orca/branch_unit.vhd VHDL PATH branch_unit.vhd
add_fileset_file vblox_orca/decode.vhd VHDL PATH decode.vhd
add_fileset_file vblox_orca/execute.vhd VHDL PATH execute.vhd
add_fileset_file vblox_orca/instruction_fetch.vhd VHDL PATH instruction_fetch.vhd
add_fileset_file vblox_orca/load_store_unit.vhd VHDL PATH load_store_unit.vhd
add_fileset_file vblox_orca/register_file.vhd VHDL PATH register_file.vhd
add_fileset_file vblox_orca/orca.vhd VHDL PATH orca.vhd
add_fileset_file vblox_orca/orca_core.vhd VHDL PATH orca_core.vhd
add_fileset_file vblox_orca/sys_call.vhd VHDL PATH sys_call.vhd
add_fileset_file vblox_orca/4port_mem.vhd VHDL PATH 4port_mem.vhd
add_fileset_file vblox_orca/lve_top.vhd VHDL PATH lve_top.vhd
add_fileset_file vblox_orca/a4l_master.vhd VHDL PATH a4l_master.vhd
add_fileset_file vblox_orca/axi_master.vhd VHDL PATH axi_master.vhd
add_fileset_file vblox_orca/cache_mux.vhd VHDL PATH cache_mux.vhd
add_fileset_file vblox_orca/oimm_register.vhd VHDL PATH oimm_register.vhd
add_fileset_file vblox_orca/oimm_throttler.vhd VHDL PATH oimm_throttler.vhd
add_fileset_file vblox_orca/memory_interface.vhd VHDL PATH memory_interface.vhd
add_fileset_file vblox_orca/cache_controller.vhd VHDL PATH cache_controller.vhd
add_fileset_file vblox_orca/cache.vhd VHDL PATH cache.vhd
add_fileset_file vblox_orca/bram_sdp_write_first.vhd VHDL PATH bram_sdp_write_first.vhd

#
# parameters
#
add_parameter REGISTER_SIZE INTEGER 32
set_parameter_property REGISTER_SIZE DEFAULT_VALUE 32
set_parameter_property REGISTER_SIZE DISPLAY_NAME REGISTER_SIZE
set_parameter_property REGISTER_SIZE TYPE INTEGER
set_parameter_property REGISTER_SIZE UNITS None
set_parameter_property REGISTER_SIZE ALLOWED_RANGES {32}
set_parameter_property REGISTER_SIZE HDL_PARAMETER true
set_parameter_property REGISTER_SIZE visible false

add_parameter          AVALON_AUX natural 1
set_parameter_property AVALON_AUX ALLOWED_RANGES 0:1
set_parameter_property AVALON_AUX HDL_PARAMETER true
set_parameter_property AVALON_AUX visible false
set_parameter_property AVALON_AUX derived true

add_parameter          LMB_AUX natural 0
set_parameter_property LMB_AUX ALLOWED_RANGES 0:1
set_parameter_property LMB_AUX HDL_PARAMETER true
set_parameter_property LMB_AUX visible false
set_parameter_property LMB_AUX derived true

add_parameter          WISHBONE_AUX natural 0
set_parameter_property WISHBONE_AUX ALLOWED_RANGES 0:1
set_parameter_property WISHBONE_AUX HDL_PARAMETER true
set_parameter_property WISHBONE_AUX visible false
set_parameter_property WISHBONE_AUX derived true

add_parameter RESET_VECTOR Std_Logic_Vector 32'h00000000
set_parameter_property RESET_VECTOR DEFAULT_VALUE 32'h00000000
set_parameter_property RESET_VECTOR DISPLAY_NAME "Reset Vector"
set_parameter_property RESET_VECTOR UNITS None
set_parameter_property RESET_VECTOR WIDTH 32
set_parameter_property RESET_VECTOR HDL_PARAMETER true

add_parameter INTERRUPT_VECTOR Std_Logic_Vector 32'h00000200
set_parameter_property INTERRUPT_VECTOR DEFAULT_VALUE 32'h00000200
set_parameter_property INTERRUPT_VECTOR DISPLAY_NAME "Interrupt Vector"
set_parameter_property INTERRUPT_VECTOR UNITS None
set_parameter_property INTERRUPT_VECTOR WIDTH 32
set_parameter_property INTERRUPT_VECTOR HDL_PARAMETER true

add_parameter MAX_IFETCHES_IN_FLIGHT positive 3
set_parameter_property MAX_IFETCHES_IN_FLIGHT DEFAULT_VALUE 3
set_parameter_property MAX_IFETCHES_IN_FLIGHT DISPLAY_NAME "Max IFetches in Flight"
set_parameter_property MAX_IFETCHES_IN_FLIGHT DESCRIPTION "Maximum instructions in flight at one time."
set_parameter_property MAX_IFETCHES_IN_FLIGHT TYPE NATURAL
set_parameter_property MAX_IFETCHES_IN_FLIGHT UNITS None
set_parameter_property MAX_IFETCHES_IN_FLIGHT ALLOWED_RANGES 1:4
set_parameter_property MAX_IFETCHES_IN_FLIGHT HDL_PARAMETER true

add_parameter BTB_ENTRIES natural 16
set_parameter_property BTB_ENTRIES DEFAULT_VALUE 16
set_parameter_property BTB_ENTRIES DISPLAY_NAME "BTB Entries"
set_parameter_property BTB_ENTRIES DESCRIPTION "Branch target buffer entries (0 for no branch prediction)."
set_parameter_property BTB_ENTRIES TYPE NATURAL
set_parameter_property BTB_ENTRIES UNITS None
set_parameter_property BTB_ENTRIES ALLOWED_RANGES 0:64
set_parameter_property BTB_ENTRIES HDL_PARAMETER true

add_parameter MULTIPLY_ENABLE natural 1
set_parameter_property MULTIPLY_ENABLE DEFAULT_VALUE 1
set_parameter_property MULTIPLY_ENABLE DISPLAY_NAME "Hardware Multiply"
set_parameter_property MULTIPLY_ENABLE DESCRIPTION "Enable Multiplier, uses around 100 LUT4s, Shift instruction use the multiplier, 2 cycle operation"
set_parameter_property MULTIPLY_ENABLE TYPE NATURAL
set_parameter_property MULTIPLY_ENABLE UNITS None
set_parameter_property MULTIPLY_ENABLE ALLOWED_RANGES 0:1
set_parameter_property MULTIPLY_ENABLE HDL_PARAMETER true
set_display_item_property MULTIPLY_ENABLE DISPLAY_HINT boolean

add_parameter DIVIDE_ENABLE natural 1
set_parameter_property DIVIDE_ENABLE DEFAULT_VALUE 1
set_parameter_property DIVIDE_ENABLE DISPLAY_NAME "Hardware Divide"
set_parameter_property DIVIDE_ENABLE DESCRIPTION "Enable Divider, uses around 400 LUT4s, 35 cycle operation"
set_parameter_property DIVIDE_ENABLE TYPE NATURAL
set_parameter_property DIVIDE_ENABLE UNITS None
set_parameter_property DIVIDE_ENABLE ALLOWED_RANGES 0:1
set_parameter_property DIVIDE_ENABLE HDL_PARAMETER true
set_display_item_property DIVIDE_ENABLE DISPLAY_HINT boolean

add_parameter SHIFTER_MAX_CYCLES natural 32
set_parameter_property SHIFTER_MAX_CYCLES DISPLAY_NAME "Shifter Max Cycles"
set_parameter_property SHIFTER_MAX_CYCLES TYPE NATURAL
set_parameter_property SHIFTER_MAX_CYCLES UNITS Cycles
set_parameter_property SHIFTER_MAX_CYCLES ALLOWED_RANGES {1 8 32}
set_parameter_property SHIFTER_MAX_CYCLES HDL_PARAMETER true

add_parameter COUNTER_LENGTH natural 64
set_parameter_property COUNTER_LENGTH DISPLAY_NAME "Counters Register Size"
set_parameter_property COUNTER_LENGTH DESCRIPTION "\
rdcycle and rdinstret size. If this is set to zero those \
instructions throw unimplemented exception"
set_parameter_property COUNTER_LENGTH TYPE NATURAL
set_parameter_property COUNTER_LENGTH UNITS None
set_parameter_property COUNTER_LENGTH ALLOWED_RANGES {0 32 64}
set_parameter_property COUNTER_LENGTH HDL_PARAMETER true
set_display_item_property COUNTER_LENGTH DISPLAY_HINT boolean

add_parameter ENABLE_EXCEPTIONS natural 1
set_parameter_property ENABLE_EXCEPTIONS DISPLAY_NAME "Enable Exceptions"
set_parameter_property ENABLE_EXCEPTIONS DESCRIPTION "Enable handling of illegal instructions, external interrupts, and timer interrupts (Recommended)"
set_parameter_property ENABLE_EXCEPTIONS TYPE NATURAL
set_parameter_property ENABLE_EXCEPTIONS UNITS None
set_parameter_property ENABLE_EXCEPTIONS ALLOWED_RANGES 0:1
set_parameter_property ENABLE_EXCEPTIONS HDL_PARAMETER true
set_display_item_property ENABLE_EXCEPTIONS DISPLAY_HINT boolean

add_parameter ENABLE_EXT_INTERRUPTS natural 0
set_parameter_property ENABLE_EXT_INTERRUPTS DISPLAY_NAME "Enable Interrupts"
set_parameter_property ENABLE_EXT_INTERRUPTS DESCRIPTION "Enable handling of external interrupts" 
set_parameter_property ENABLE_EXT_INTERRUPTS TYPE NATURAL
set_parameter_property ENABLE_EXT_INTERRUPTS UNITS None
set_parameter_property ENABLE_EXT_INTERRUPTS ALLOWED_RANGES 0:1
set_parameter_property ENABLE_EXT_INTERRUPTS HDL_PARAMETER true
set_display_item_property ENABLE_EXT_INTERRUPTS DISPLAY_HINT boolean

add_parameter          NUM_EXT_INTERRUPTS POSITIVE 1
set_parameter_property NUM_EXT_INTERRUPTS HDL_PARAMETER true
set_parameter_property NUM_EXT_INTERRUPTS ALLOWED_RANGES 1:32
set_parameter_property NUM_EXT_INTERRUPTS DISPLAY_NAME "       External Interrupts"
set_parameter_property NUM_EXT_INTERRUPTS DESCRIPTION "The number of connected external interrupts (maximum 32)."
set_parameter_property NUM_EXT_INTERRUPTS visible false

add_parameter          DATA_REQUEST_REGISTER natural 0
set_parameter_property DATA_REQUEST_REGISTER DEFAULT_VALUE 0
set_parameter_property DATA_REQUEST_REGISTER HDL_PARAMETER true
set_parameter_property DATA_REQUEST_REGISTER DISPLAY_NAME "Data Request Register"
set_parameter_property DATA_REQUEST_REGISTER DESCRIPTION "Register data master request for higher fmax.  \
0/Off, 1/Light, 2/Full."
set_parameter_property DATA_REQUEST_REGISTER ALLOWED_RANGES {0,1,2}

add_parameter          DATA_RETURN_REGISTER natural 0
set_parameter_property DATA_RETURN_REGISTER DEFAULT_VALUE 0
set_parameter_property DATA_RETURN_REGISTER HDL_PARAMETER true
set_parameter_property DATA_RETURN_REGISTER DISPLAY_NAME "Data Return Register"
set_parameter_property DATA_RETURN_REGISTER DESCRIPTION "Register data master readdata for higher fmax \
at the cost of higher load latency."
set_parameter_property DATA_RETURN_REGISTER ALLOWED_RANGES {0,1}

add_parameter          DUC_REQUEST_REGISTER natural 2
set_parameter_property DUC_REQUEST_REGISTER DEFAULT_VALUE 2
set_parameter_property DUC_REQUEST_REGISTER HDL_PARAMETER true
set_parameter_property DUC_REQUEST_REGISTER DISPLAY_NAME "DUC Request Register"
set_parameter_property DUC_REQUEST_REGISTER DESCRIPTION "Register DUC master request for higher fmax.  \
0/Off, 1/Light, 2/Full."
set_parameter_property DUC_REQUEST_REGISTER ALLOWED_RANGES {0,1,2}

add_parameter          DUC_RETURN_REGISTER natural 1
set_parameter_property DUC_RETURN_REGISTER DEFAULT_VALUE 1
set_parameter_property DUC_RETURN_REGISTER HDL_PARAMETER true
set_parameter_property DUC_RETURN_REGISTER DISPLAY_NAME "DUC Return Register"
set_parameter_property DUC_RETURN_REGISTER DESCRIPTION "Register DUC master readdata for higher fmax \
at the cost of higher load latency."
set_parameter_property DUC_RETURN_REGISTER ALLOWED_RANGES {0,1}

add_parameter          DAUX_REQUEST_REGISTER natural 2
set_parameter_property DAUX_REQUEST_REGISTER DEFAULT_VALUE 2
set_parameter_property DAUX_REQUEST_REGISTER HDL_PARAMETER true
set_parameter_property DAUX_REQUEST_REGISTER DISPLAY_NAME "Data avalon Request Register"
set_parameter_property DAUX_REQUEST_REGISTER DESCRIPTION "Register data avalon master request for higher fmax.  \
0/Off, 1/Light, 2/Full."
set_parameter_property DAUX_REQUEST_REGISTER ALLOWED_RANGES {0,1,2}

add_parameter          DAUX_RETURN_REGISTER natural 1
set_parameter_property DAUX_RETURN_REGISTER DEFAULT_VALUE 1
set_parameter_property DAUX_RETURN_REGISTER HDL_PARAMETER true
set_parameter_property DAUX_RETURN_REGISTER DISPLAY_NAME "Data avalon Return Register"
set_parameter_property DAUX_RETURN_REGISTER DESCRIPTION "Register data avalon master readdata for higher fmax \
at the cost of higher load latency."
set_parameter_property DAUX_RETURN_REGISTER ALLOWED_RANGES {0,1}

add_parameter          INSTRUCTION_REQUEST_REGISTER natural 0
set_parameter_property INSTRUCTION_REQUEST_REGISTER DEFAULT_VALUE 0
set_parameter_property INSTRUCTION_REQUEST_REGISTER HDL_PARAMETER true
set_parameter_property INSTRUCTION_REQUEST_REGISTER DISPLAY_NAME "Instruction Request Register"
set_parameter_property INSTRUCTION_REQUEST_REGISTER DESCRIPTION "Register instruction master request for higher fmax.  \
0/Off, 1/Light, 2/Full."
set_parameter_property INSTRUCTION_REQUEST_REGISTER ALLOWED_RANGES {0,1,2}

add_parameter          INSTRUCTION_RETURN_REGISTER natural 0
set_parameter_property INSTRUCTION_RETURN_REGISTER DEFAULT_VALUE 0
set_parameter_property INSTRUCTION_RETURN_REGISTER HDL_PARAMETER true
set_parameter_property INSTRUCTION_RETURN_REGISTER DISPLAY_NAME "Instruction Return Register"
set_parameter_property INSTRUCTION_RETURN_REGISTER DESCRIPTION "Register instruction master readdata for higher fmax \
at the cost of higher load latency."
set_parameter_property INSTRUCTION_RETURN_REGISTER ALLOWED_RANGES {0,1}

add_parameter          IUC_REQUEST_REGISTER natural 1
set_parameter_property IUC_REQUEST_REGISTER DEFAULT_VALUE 1
set_parameter_property IUC_REQUEST_REGISTER HDL_PARAMETER true
set_parameter_property IUC_REQUEST_REGISTER DISPLAY_NAME "IUC Request Register"
set_parameter_property IUC_REQUEST_REGISTER DESCRIPTION "Register IUC master request for higher fmax.  \
0/Off, 1/Light, 2/Full."
set_parameter_property IUC_REQUEST_REGISTER ALLOWED_RANGES {0,1,2}

add_parameter          IUC_RETURN_REGISTER natural 0
set_parameter_property IUC_RETURN_REGISTER DEFAULT_VALUE 0
set_parameter_property IUC_RETURN_REGISTER HDL_PARAMETER true
set_parameter_property IUC_RETURN_REGISTER DISPLAY_NAME "IUC Return Register"
set_parameter_property IUC_RETURN_REGISTER DESCRIPTION "Register IUC master readdata for higher fmax \
at the cost of higher load latency."
set_parameter_property IUC_RETURN_REGISTER ALLOWED_RANGES {0,1}

add_parameter          IAUX_REQUEST_REGISTER natural 1
set_parameter_property IAUX_REQUEST_REGISTER DEFAULT_VALUE 1
set_parameter_property IAUX_REQUEST_REGISTER HDL_PARAMETER true
set_parameter_property IAUX_REQUEST_REGISTER DISPLAY_NAME "Instruction Avalon Request Register"
set_parameter_property IAUX_REQUEST_REGISTER DESCRIPTION "Register instruction avalon master request for higher fmax.  \
0/Off, 1/Light, 2/Full."
set_parameter_property IAUX_REQUEST_REGISTER ALLOWED_RANGES {0,1,2}

add_parameter          IAUX_RETURN_REGISTER natural 0
set_parameter_property IAUX_RETURN_REGISTER DEFAULT_VALUE 0
set_parameter_property IAUX_RETURN_REGISTER HDL_PARAMETER true
set_parameter_property IAUX_RETURN_REGISTER DISPLAY_NAME "Instruction Avalon Return Register"
set_parameter_property IAUX_RETURN_REGISTER DESCRIPTION "Register instruction avalon master readdata for higher fmax \
at the cost of higher load latency."
set_parameter_property IAUX_RETURN_REGISTER ALLOWED_RANGES {0,1}

add_parameter          PIPELINE_STAGES natural 5
set_parameter_property PIPELINE_STAGES HDL_PARAMETER true
set_parameter_property PIPELINE_STAGES DISPLAY_NAME "Pipeline Stages"
set_parameter_property PIPELINE_STAGES DESCRIPTION "Choose the number of pipeline stages, 4 stages is smaller\
but 5 stages has a higher fmax"
set_parameter_property PIPELINE_STAGES ALLOWED_RANGES {4,5}

add_parameter LVE_ENABLE natural 0
set_parameter_property LVE_ENABLE DEFAULT_VALUE 0
set_parameter_property LVE_ENABLE DISPLAY_NAME "Vector Extensions"
set_parameter_property LVE_ENABLE DESCRIPTION "Enable Vector Extensions"
set_parameter_property LVE_ENABLE TYPE NATURAL
set_parameter_property LVE_ENABLE UNITS None
set_parameter_property LVE_ENABLE ALLOWED_RANGES 0:1
set_parameter_property LVE_ENABLE HDL_PARAMETER true
set_display_item_property LVE_ENABLE DISPLAY_HINT boolean

add_parameter SCRATCHPAD_SIZE integer 64
set_parameter_property SCRATCHPAD_SIZE DISPLAY_NAME "        Scratchpad size"
set_parameter_property SCRATCHPAD_SIZE DESCRIPTION "        Scratchpad size"
set_parameter_property SCRATCHPAD_SIZE UNITS kilobytes
set_parameter_property SCRATCHPAD_SIZE HDL_PARAMETER false
set_parameter_property SCRATCHPAD_SIZE visible true 

add_parameter SCRATCHPAD_ADDR_BITS integer 10
set_parameter_property SCRATCHPAD_ADDR_BITS HDL_PARAMETER true
set_parameter_property SCRATCHPAD_ADDR_BITS visible false 
set_parameter_property SCRATCHPAD_ADDR_BITS derived true

add_parameter IUC_ADDR_BASE Std_Logic_Vector 32'h00000000
set_parameter_property IUC_ADDR_BASE DEFAULT_VALUE 32'h00000000
set_parameter_property IUC_ADDR_BASE DISPLAY_NAME "Uncached Instruction AXI4-Lite Start Address"
set_parameter_property IUC_ADDR_BASE UNITS None
set_parameter_property IUC_ADDR_BASE WIDTH 32
set_parameter_property IUC_ADDR_BASE HDL_PARAMETER true
set_parameter_property IUC_ADDR_BASE visible true

add_parameter IUC_ADDR_LAST Std_Logic_Vector 32'h00000000
set_parameter_property IUC_ADDR_LAST DEFAULT_VALUE 32'h00000000
set_parameter_property IUC_ADDR_LAST DISPLAY_NAME "Uncached Instruction AXI4-Lite End Address"
set_parameter_property IUC_ADDR_LAST UNITS None
set_parameter_property IUC_ADDR_LAST WIDTH 32
set_parameter_property IUC_ADDR_LAST HDL_PARAMETER true
set_parameter_property IUC_ADDR_LAST visible true

add_parameter IAUX_ADDR_BASE Std_Logic_Vector 32'h00000000
set_parameter_property IAUX_ADDR_BASE DEFAULT_VALUE 32'h00000000
set_parameter_property IAUX_ADDR_BASE DISPLAY_NAME "Uncached Instruction Auxiliary Interface Start Address"
set_parameter_property IAUX_ADDR_BASE UNITS None
set_parameter_property IAUX_ADDR_BASE WIDTH 32
set_parameter_property IAUX_ADDR_BASE HDL_PARAMETER true
set_parameter_property IAUX_ADDR_BASE visible true

add_parameter IAUX_ADDR_LAST Std_Logic_Vector 32'hFFFFFFFF
set_parameter_property IAUX_ADDR_LAST DEFAULT_VALUE 32'hFFFFFFFF
set_parameter_property IAUX_ADDR_LAST DISPLAY_NAME "Uncached Instruction Auxiliary Interface End Address"
set_parameter_property IAUX_ADDR_LAST UNITS None
set_parameter_property IAUX_ADDR_LAST WIDTH 32
set_parameter_property IAUX_ADDR_LAST HDL_PARAMETER true
set_parameter_property IAUX_ADDR_LAST visible true

add_parameter ICACHE_SIZE NATURAL 0
set_parameter_property ICACHE_SIZE HDL_PARAMETER true
set_parameter_property ICACHE_SIZE visible true

add_parameter ICACHE_LINE_SIZE NATURAL 32
set_parameter_property ICACHE_LINE_SIZE HDL_PARAMETER true
set_parameter_property ICACHE_LINE_SIZE visible true

add_parameter ICACHE_EXTERNAL_WIDTH integer 32 
set_parameter_property ICACHE_EXTERNAL_WIDTH HDL_PARAMETER true
set_parameter_property ICACHE_EXTERNAL_WIDTH visible true

add_parameter ICACHE_BURST_EN integer 0 
set_parameter_property ICACHE_BURST_EN HDL_PARAMETER true
set_parameter_property ICACHE_BURST_EN ALLOWED_RANGES 0:1
set_parameter_property ICACHE_BURST_EN visible true

add_parameter DUC_ADDR_BASE Std_Logic_Vector 32'h00000000
set_parameter_property DUC_ADDR_BASE DEFAULT_VALUE 32'h00000000
set_parameter_property DUC_ADDR_BASE DISPLAY_NAME "Uncached Data AXI4-Lite Start Address"
set_parameter_property DUC_ADDR_BASE UNITS None
set_parameter_property DUC_ADDR_BASE WIDTH 32
set_parameter_property DUC_ADDR_BASE HDL_PARAMETER true
set_parameter_property DUC_ADDR_BASE visible true

add_parameter DUC_ADDR_LAST Std_Logic_Vector 32'h00000000
set_parameter_property DUC_ADDR_LAST DEFAULT_VALUE 32'h00000000
set_parameter_property DUC_ADDR_LAST DISPLAY_NAME "Uncached Data AXI4-Lite End Address"
set_parameter_property DUC_ADDR_LAST UNITS None
set_parameter_property DUC_ADDR_LAST WIDTH 32
set_parameter_property DUC_ADDR_LAST HDL_PARAMETER true
set_parameter_property DUC_ADDR_LAST visible true

add_parameter DAUX_ADDR_BASE Std_Logic_Vector 32'h00000000
set_parameter_property DAUX_ADDR_BASE DEFAULT_VALUE 32'h00000000
set_parameter_property DAUX_ADDR_BASE DISPLAY_NAME "Uncached Data Auxiliary Interface Start Address"
set_parameter_property DAUX_ADDR_BASE UNITS None
set_parameter_property DAUX_ADDR_BASE WIDTH 32
set_parameter_property DAUX_ADDR_BASE HDL_PARAMETER true
set_parameter_property DAUX_ADDR_BASE visible true

add_parameter DAUX_ADDR_LAST Std_Logic_Vector 32'hFFFFFFFF
set_parameter_property DAUX_ADDR_LAST DEFAULT_VALUE 32'hFFFFFFFF
set_parameter_property DAUX_ADDR_LAST DISPLAY_NAME "Uncached Data Auxiliary Interface End Address"
set_parameter_property DAUX_ADDR_LAST UNITS None
set_parameter_property DAUX_ADDR_LAST WIDTH 32
set_parameter_property DAUX_ADDR_LAST HDL_PARAMETER true
set_parameter_property DAUX_ADDR_LAST visible true

add_parameter DCACHE_SIZE NATURAL 0
set_parameter_property DCACHE_SIZE HDL_PARAMETER true
set_parameter_property DCACHE_SIZE visible true

add_parameter DCACHE_LINE_SIZE NATURAL 32
set_parameter_property DCACHE_LINE_SIZE HDL_PARAMETER true
set_parameter_property DCACHE_LINE_SIZE visible true

add_parameter DCACHE_EXTERNAL_WIDTH integer 32 
set_parameter_property DCACHE_EXTERNAL_WIDTH HDL_PARAMETER true
set_parameter_property DCACHE_EXTERNAL_WIDTH visible true

add_parameter DCACHE_BURST_EN integer 0 
set_parameter_property DCACHE_BURST_EN HDL_PARAMETER true
set_parameter_property DCACHE_BURST_EN ALLOWED_RANGES 0:1
set_parameter_property DCACHE_BURST_EN visible true

add_parameter POWER_OPTIMIZED natural
set_parameter_property POWER_OPTIMIZED DEFAULT_VALUE 0
set_parameter_property POWER_OPTIMIZED DISPLAY_NAME "Optimize for Power"
set_parameter_property POWER_OPTIMIZED DESCRIPTION "Improve power usage at the expense of area"
set_parameter_property POWER_OPTIMIZED HDL_PARAMETER true
set_parameter_property POWER_OPTIMIZED ALLOWED_RANGES 0:1
set_display_item_property POWER_OPTIMIZED DISPLAY_HINT boolean

add_parameter FAMILY string ALTERA 
set_parameter_property FAMILY HDL_PARAMETER true
set_parameter_property FAMILY visible false 

#
# display items
#

#
# connection point clock
#
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1

add_interface scratchpad_clk clock end
set_interface_property scratchpad_clk clockRate 0
set_interface_property scratchpad_clk EXPORT_OF ""
set_interface_property scratchpad_clk PORT_NAME_MAP ""
set_interface_property scratchpad_clk CMSIS_SVD_VARIABLES ""
set_interface_property scratchpad_clk SVD_ADDRESS_GROUP ""

add_interface_port scratchpad_clk scratchpad_clk clk Input 1

#
# connection point reset
#
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1

#
# DUC Avalon port
#
add_interface data avalon start
set_interface_property data addressUnits SYMBOLS
set_interface_property data associatedClock clock
set_interface_property data associatedReset reset
set_interface_property data bitsPerSymbol 8
set_interface_property data burstOnBurstBoundariesOnly false
set_interface_property data burstcountUnits WORDS
set_interface_property data doStreamReads false
set_interface_property data doStreamWrites false
set_interface_property data holdTime 0
set_interface_property data linewrapBursts false
set_interface_property data maximumPendingReadTransactions 0
set_interface_property data maximumPendingWriteTransactions 0
set_interface_property data readLatency 0
set_interface_property data readWaitTime 1
set_interface_property data setupTime 0
set_interface_property data timingUnits Cycles
set_interface_property data writeWaitTime 0
set_interface_property data ENABLED true
set_interface_property data EXPORT_OF ""
set_interface_property data PORT_NAME_MAP ""
set_interface_property data CMSIS_SVD_VARIABLES ""
set_interface_property data SVD_ADDRESS_GROUP ""

add_interface_port data avm_data_address address Output register_size
add_interface_port data avm_data_byteenable byteenable Output register_size/8
add_interface_port data avm_data_read read Output 1
add_interface_port data avm_data_readdata readdata Input register_size
add_interface_port data avm_data_write write Output 1
add_interface_port data avm_data_writedata writedata Output register_size
add_interface_port data avm_data_waitrequest waitrequest Input 1
add_interface_port data avm_data_readdatavalid readdatavalid Input 1

#
# DUC AXI port
#
add_interface axi_duc axi start
set_interface_property axi_duc associatedClock clock
set_interface_property axi_duc associatedReset reset
set_interface_property axi_duc readIssuingCapability 1
set_interface_property axi_duc writeIssuingCapability 4
set_interface_property axi_duc combinedIssuingCapability 4
set_interface_property axi_duc ENABLED true
set_interface_property axi_duc EXPORT_OF ""
set_interface_property axi_duc PORT_NAME_MAP ""
set_interface_property axi_duc CMSIS_SVD_VARIABLES ""
set_interface_property axi_duc SVD_ADDRESS_GROUP ""

add_interface_port axi_duc DUC_ARADDR araddr Output register_size
add_interface_port axi_duc DUC_ARBURST arburst Output 2
add_interface_port axi_duc DUC_ARCACHE arcache Output 4
add_interface_port axi_duc DUC_ARID arid Output 4
add_interface_port axi_duc DUC_ARLEN arlen Output 4
add_interface_port axi_duc DUC_ARLOCK arlock Output 2
add_interface_port axi_duc DUC_ARPROT arprot Output 3
add_interface_port axi_duc DUC_ARREADY arready Input 1
add_interface_port axi_duc DUC_ARSIZE arsize Output 3
add_interface_port axi_duc DUC_ARVALID arvalid Output 1
add_interface_port axi_duc DUC_AWADDR awaddr Output register_size
add_interface_port axi_duc DUC_AWBURST awburst Output 2
add_interface_port axi_duc DUC_AWCACHE awcache Output 4
add_interface_port axi_duc DUC_AWID awid Output 4
add_interface_port axi_duc DUC_AWLEN awlen Output 4
add_interface_port axi_duc DUC_AWLOCK awlock Output 2
add_interface_port axi_duc DUC_AWPROT awprot Output 3
add_interface_port axi_duc DUC_AWREADY awready Input 1
add_interface_port axi_duc DUC_AWSIZE awsize Output 3
add_interface_port axi_duc DUC_AWVALID awvalid Output 1
add_interface_port axi_duc DUC_BID bid Input 4
add_interface_port axi_duc DUC_BREADY bready Output 1
add_interface_port axi_duc DUC_BRESP bresp Input 2
add_interface_port axi_duc DUC_BVALID bvalid Input 1
add_interface_port axi_duc DUC_RDATA rdata Input register_size
add_interface_port axi_duc DUC_RID rid Input 4
add_interface_port axi_duc DUC_RLAST rlast Input 1
add_interface_port axi_duc DUC_RREADY rready Output 1
add_interface_port axi_duc DUC_RRESP rresp Input 2
add_interface_port axi_duc DUC_RVALID rvalid Input 1
add_interface_port axi_duc DUC_WDATA wdata Output register_size
add_interface_port axi_duc DUC_WID wid Output 4
add_interface_port axi_duc DUC_WLAST wlast Output 1
add_interface_port axi_duc DUC_WREADY wready Input 1
add_interface_port axi_duc DUC_WSTRB wstrb Output register_size/8
add_interface_port axi_duc DUC_WVALID wvalid Output 1

#
# IUC AXI Port
#
add_interface axi_iuc axi start
set_interface_property axi_iuc associatedClock clock
set_interface_property axi_iuc associatedReset reset
set_interface_property axi_iuc readIssuingCapability 3
set_interface_property axi_iuc writeIssuingCapability 1
set_interface_property axi_iuc combinedIssuingCapability 3
set_interface_property axi_iuc ENABLED true
set_interface_property axi_iuc EXPORT_OF ""
set_interface_property axi_iuc PORT_NAME_MAP ""
set_interface_property axi_iuc CMSIS_SVD_VARIABLES ""
set_interface_property axi_iuc SVD_ADDRESS_GROUP ""

add_interface_port axi_iuc IUC_ARADDR araddr Output register_size
add_interface_port axi_iuc IUC_ARBURST arburst Output 2
add_interface_port axi_iuc IUC_ARCACHE arcache Output 4
add_interface_port axi_iuc IUC_ARID arid Output 4
add_interface_port axi_iuc IUC_ARLEN arlen Output 4
add_interface_port axi_iuc IUC_ARLOCK arlock Output 2
add_interface_port axi_iuc IUC_ARPROT arprot Output 3
add_interface_port axi_iuc IUC_ARREADY arready Input 1
add_interface_port axi_iuc IUC_ARSIZE arsize Output 3
add_interface_port axi_iuc IUC_ARVALID arvalid Output 1
add_interface_port axi_iuc IUC_AWADDR awaddr Output register_size
add_interface_port axi_iuc IUC_AWBURST awburst Output 2
add_interface_port axi_iuc IUC_AWCACHE awcache Output 4
add_interface_port axi_iuc IUC_AWID awid Output 4
add_interface_port axi_iuc IUC_AWLEN awlen Output 4
add_interface_port axi_iuc IUC_AWLOCK awlock Output 2
add_interface_port axi_iuc IUC_AWPROT awprot Output 3
add_interface_port axi_iuc IUC_AWREADY awready Input 1
add_interface_port axi_iuc IUC_AWSIZE awsize Output 3
add_interface_port axi_iuc IUC_AWVALID awvalid Output 1
add_interface_port axi_iuc IUC_BID bid Input 4
add_interface_port axi_iuc IUC_BREADY bready Output 1
add_interface_port axi_iuc IUC_BRESP bresp Input 2
add_interface_port axi_iuc IUC_BVALID bvalid Input 1
add_interface_port axi_iuc IUC_RDATA rdata Input register_size
add_interface_port axi_iuc IUC_RID rid Input 4
add_interface_port axi_iuc IUC_RLAST rlast Input 1
add_interface_port axi_iuc IUC_RREADY rready Output 1
add_interface_port axi_iuc IUC_RRESP rresp Input 2
add_interface_port axi_iuc IUC_RVALID rvalid Input 1
add_interface_port axi_iuc IUC_WDATA wdata Output register_size
add_interface_port axi_iuc IUC_WID wid Output 4
add_interface_port axi_iuc IUC_WLAST wlast Output 1
add_interface_port axi_iuc IUC_WREADY wready Input 1
add_interface_port axi_iuc IUC_WSTRB wstrb Output register_size/8
add_interface_port axi_iuc IUC_WVALID wvalid Output 1

#
# IC AXI Port
#
add_interface axi_ic_master axi start
set_interface_property axi_ic_master associatedClock clock
set_interface_property axi_ic_master associatedReset reset
set_interface_property axi_ic_master readIssuingCapability 3
set_interface_property axi_ic_master writeIssuingCapability 1
set_interface_property axi_ic_master combinedIssuingCapability 3
set_interface_property axi_ic_master ENABLED true
set_interface_property axi_ic_master EXPORT_OF ""
set_interface_property axi_ic_master PORT_NAME_MAP ""
set_interface_property axi_ic_master CMSIS_SVD_VARIABLES ""
set_interface_property axi_ic_master SVD_ADDRESS_GROUP ""

add_interface_port axi_ic_master IC_ARADDR araddr Output register_size
add_interface_port axi_ic_master IC_ARBURST arburst Output 2
add_interface_port axi_ic_master IC_ARCACHE arcache Output 4
add_interface_port axi_ic_master IC_ARID arid Output 4
add_interface_port axi_ic_master IC_ARLEN arlen Output 4
add_interface_port axi_ic_master IC_ARLOCK arlock Output 2
add_interface_port axi_ic_master IC_ARPROT arprot Output 3
add_interface_port axi_ic_master IC_ARREADY arready Input 1
add_interface_port axi_ic_master IC_ARSIZE arsize Output 3
add_interface_port axi_ic_master IC_ARVALID arvalid Output 1
add_interface_port axi_ic_master IC_AWADDR awaddr Output register_size
add_interface_port axi_ic_master IC_AWBURST awburst Output 2
add_interface_port axi_ic_master IC_AWCACHE awcache Output 4
add_interface_port axi_ic_master IC_AWID awid Output 4
add_interface_port axi_ic_master IC_AWLEN awlen Output 4
add_interface_port axi_ic_master IC_AWLOCK awlock Output 2
add_interface_port axi_ic_master IC_AWPROT awprot Output 3
add_interface_port axi_ic_master IC_AWREADY awready Input 1
add_interface_port axi_ic_master IC_AWSIZE awsize Output 3
add_interface_port axi_ic_master IC_AWVALID awvalid Output 1
add_interface_port axi_ic_master IC_BID bid Input 4
add_interface_port axi_ic_master IC_BREADY bready Output 1
add_interface_port axi_ic_master IC_BRESP bresp Input 2
add_interface_port axi_ic_master IC_BVALID bvalid Input 1
add_interface_port axi_ic_master IC_RDATA rdata Input register_size
add_interface_port axi_ic_master IC_RID rid Input 4
add_interface_port axi_ic_master IC_RLAST rlast Input 1
add_interface_port axi_ic_master IC_RREADY rready Output 1
add_interface_port axi_ic_master IC_RRESP rresp Input 2
add_interface_port axi_ic_master IC_RVALID rvalid Input 1
add_interface_port axi_ic_master IC_WDATA wdata Output register_size
add_interface_port axi_ic_master IC_WID wid Output 4
add_interface_port axi_ic_master IC_WLAST wlast Output 1
add_interface_port axi_ic_master IC_WREADY wready Input 1
add_interface_port axi_ic_master IC_WSTRB wstrb Output register_size/8
add_interface_port axi_ic_master IC_WVALID wvalid Output 1

#
# DC AXI Port
#
add_interface axi_dc_master axi start
set_interface_property axi_dc_master associatedClock clock
set_interface_property axi_dc_master associatedReset reset
set_interface_property axi_dc_master readIssuingCapability 1
set_interface_property axi_dc_master writeIssuingCapability 4
set_interface_property axi_dc_master combinedIssuingCapability 4
set_interface_property axi_dc_master ENABLED true
set_interface_property axi_dc_master EXPORT_OF ""
set_interface_property axi_dc_master PORT_NAME_MAP ""
set_interface_property axi_dc_master CMSIS_SVD_VARIABLES ""
set_interface_property axi_dc_master SVD_ADDRESS_GROUP ""

add_interface_port axi_dc_master DC_ARADDR araddr Output register_size
add_interface_port axi_dc_master DC_ARBURST arburst Output 2
add_interface_port axi_dc_master DC_ARCACHE arcache Output 4
add_interface_port axi_dc_master DC_ARID arid Output 4
add_interface_port axi_dc_master DC_ARLEN arlen Output 4
add_interface_port axi_dc_master DC_ARLOCK arlock Output 2
add_interface_port axi_dc_master DC_ARPROT arprot Output 3
add_interface_port axi_dc_master DC_ARREADY arready Input 1
add_interface_port axi_dc_master DC_ARSIZE arsize Output 3
add_interface_port axi_dc_master DC_ARVALID arvalid Output 1
add_interface_port axi_dc_master DC_AWADDR awaddr Output register_size
add_interface_port axi_dc_master DC_AWBURST awburst Output 2
add_interface_port axi_dc_master DC_AWCACHE awcache Output 4
add_interface_port axi_dc_master DC_AWID awid Output 4
add_interface_port axi_dc_master DC_AWLEN awlen Output 4
add_interface_port axi_dc_master DC_AWLOCK awlock Output 2
add_interface_port axi_dc_master DC_AWPROT awprot Output 3
add_interface_port axi_dc_master DC_AWREADY awready Input 1
add_interface_port axi_dc_master DC_AWSIZE awsize Output 3
add_interface_port axi_dc_master DC_AWVALID awvalid Output 1
add_interface_port axi_dc_master DC_BID bid Input 4
add_interface_port axi_dc_master DC_BREADY bready Output 1
add_interface_port axi_dc_master DC_BRESP bresp Input 2
add_interface_port axi_dc_master DC_BVALID bvalid Input 1
add_interface_port axi_dc_master DC_RDATA rdata Input register_size
add_interface_port axi_dc_master DC_RID rid Input 4
add_interface_port axi_dc_master DC_RLAST rlast Input 1
add_interface_port axi_dc_master DC_RREADY rready Output 1
add_interface_port axi_dc_master DC_RRESP rresp Input 2
add_interface_port axi_dc_master DC_RVALID rvalid Input 1
add_interface_port axi_dc_master DC_WDATA wdata Output register_size
add_interface_port axi_dc_master DC_WID wid Output 4
add_interface_port axi_dc_master DC_WLAST wlast Output 1
add_interface_port axi_dc_master DC_WREADY wready Input 1
add_interface_port axi_dc_master DC_WSTRB wstrb Output register_size/8
add_interface_port axi_dc_master DC_WVALID wvalid Output 1

#
# connection point instruction
#
add_interface instruction avalon start
set_interface_property instruction addressUnits SYMBOLS
set_interface_property instruction associatedClock clock
set_interface_property instruction associatedReset reset
set_interface_property instruction bitsPerSymbol 8
set_interface_property instruction burstOnBurstBoundariesOnly false
set_interface_property instruction burstcountUnits WORDS
set_interface_property instruction doStreamReads false
set_interface_property instruction doStreamWrites false
set_interface_property instruction holdTime 0
set_interface_property instruction linewrapBursts false
set_interface_property instruction maximumPendingReadTransactions 0
set_interface_property instruction maximumPendingWriteTransactions 0
set_interface_property instruction readLatency 0
set_interface_property instruction readWaitTime 1
set_interface_property instruction setupTime 0
set_interface_property instruction timingUnits Cycles
set_interface_property instruction writeWaitTime 0
set_interface_property instruction ENABLED true
set_interface_property instruction EXPORT_OF ""
set_interface_property instruction PORT_NAME_MAP ""
set_interface_property instruction CMSIS_SVD_VARIABLES ""
set_interface_property instruction SVD_ADDRESS_GROUP ""

add_interface_port instruction avm_instruction_address address Output register_size
add_interface_port instruction avm_instruction_read read Output 1
add_interface_port instruction avm_instruction_readdata readdata Input register_size
add_interface_port instruction avm_instruction_waitrequest waitrequest Input 1
add_interface_port instruction avm_instruction_readdatavalid readdatavalid Input 1

#
# connection point scratch
#
add_interface scratch avalon slave

set_interface_property scratch addressUnits SYMBOLS
set_interface_property scratch associatedClock clock
set_interface_property scratch associatedReset reset
set_interface_property scratch bitsPerSymbol 8
set_interface_property scratch burstOnBurstBoundariesOnly false
set_interface_property scratch burstcountUnits WORDS
set_interface_property scratch holdTime 0
set_interface_property scratch linewrapBursts false
set_interface_property scratch maximumPendingReadTransactions 1
set_interface_property scratch maximumPendingWriteTransactions 0
set_interface_property scratch readLatency 0
set_interface_property scratch readWaitTime 1
set_interface_property scratch setupTime 0
set_interface_property scratch timingUnits Cycles
set_interface_property scratch writeWaitTime 0
set_interface_property scratch ENABLED true
set_interface_property scratch EXPORT_OF ""
set_interface_property scratch PORT_NAME_MAP ""
set_interface_property scratch CMSIS_SVD_VARIABLES ""
set_interface_property scratch SVD_ADDRESS_GROUP ""

add_interface_port scratch avm_scratch_address address Input scratchpad_addr_bits
add_interface_port scratch avm_scratch_byteenable byteenable Input register_size/8
add_interface_port scratch avm_scratch_read read Input 1
add_interface_port scratch avm_scratch_readdata readdata Output register_size
add_interface_port scratch avm_scratch_write write Input 1
add_interface_port scratch avm_scratch_writedata writedata Input register_size
add_interface_port scratch avm_scratch_waitrequest waitrequest Output 1
add_interface_port scratch avm_scratch_readdatavalid readdatavalid Output 1

#
# connection point global_interrupts
#

add_interface global_interrupts interrupt receiver
set_interface_property global_interrupts associatedClock clock
set_interface_property global_interrupts associatedReset reset
set_interface_property global_interrupts associatedAddressablePoint data
set_interface_property global_interrupts ENABLED true
set_interface_property global_interrupts EXPORT_OF ""
set_interface_property global_interrupts PORT_NAME_MAP ""
set_interface_property global_interrupts CMSIS_SVD_VARIABLES ""
set_interface_property global_interrupts SVD_ADDRESS_GROUP ""

add_interface_port global_interrupts global_interrupts irq input num_ext_interrupts

#
# connection point wishbone_duc (disabled)
#
add_interface wishbone_duc conduit end
set_interface_property wishbone_duc associatedClock ""
set_interface_property wishbone_duc associatedReset ""
set_interface_property wishbone_duc ENABLED false
set_interface_property wishbone_duc EXPORT_OF ""
set_interface_property wishbone_duc PORT_NAME_MAP ""
set_interface_property wishbone_duc CMSIS_SVD_VARIABLES ""
set_interface_property wishbone_duc SVD_ADDRESS_GROUP ""

add_interface_port wishbone_duc       data_ADR_O     ADR_O     output REGISTER_SIZE
add_interface_port wishbone_duc       data_DAT_I     DAT_I     input  REGISTER_SIZE
add_interface_port wishbone_duc       data_DAT_O     DAT_O     output REGISTER_SIZE
add_interface_port wishbone_duc       data_WE_O      WE_O      output 1
add_interface_port wishbone_duc       data_SEL_O     SEL_O     output REGISTER_SIZE/8
add_interface_port wishbone_duc       data_STB_O     STB_O     output 1
add_interface_port wishbone_duc       data_ACK_I     ACK_I     input  1
add_interface_port wishbone_duc       data_CYC_O     CYC_O     output 1
add_interface_port wishbone_duc       data_CTI_O     CTI_O     output 3
add_interface_port wishbone_duc       data_STALL_I   STALL_I   input  1

#
# connection point wishbone_iuc (disabled)
#
add_interface wishbone_iuc conduit end
set_interface_property wishbone_iuc associatedClock ""
set_interface_property wishbone_iuc associatedReset ""
set_interface_property wishbone_iuc ENABLED false
set_interface_property wishbone_iuc EXPORT_OF ""
set_interface_property wishbone_iuc PORT_NAME_MAP ""
set_interface_property wishbone_iuc CMSIS_SVD_VARIABLES ""
set_interface_property wishbone_iuc SVD_ADDRESS_GROUP ""

add_interface_port wishbone_iuc       instr_ADR_O    ADR_O     output REGISTER_SIZE
add_interface_port wishbone_iuc       instr_DAT_I    DAT_I     input  REGISTER_SIZE
add_interface_port wishbone_iuc       instr_STB_O    STB_O     output 1
add_interface_port wishbone_iuc       instr_ACK_I    ACK_I     input  1
add_interface_port wishbone_iuc       instr_CYC_O    CYC_O     output 1
add_interface_port wishbone_iuc       instr_CTI_O    CTI_O     output 3
add_interface_port wishbone_iuc       instr_STALL_I  STALL_I   input  1

#
# connection point sp_wishbone (disabled)
#
add_interface sp_wishbone conduit end
set_interface_property sp_wishbone associatedClock ""
set_interface_property sp_wishbone associatedReset ""
set_interface_property sp_wishbone ENABLED false
set_interface_property sp_wishbone EXPORT_OF ""
set_interface_property sp_wishbone PORT_NAME_MAP ""
set_interface_property sp_wishbone CMSIS_SVD_VARIABLES ""
set_interface_property sp_wishbone SVD_ADDRESS_GROUP ""

add_interface_port sp_wishbone       sp_ADR_I     ADR_O     input  scratchpad_addr_bits
add_interface_port sp_wishbone       sp_DAT_O     DAT_I     output REGISTER_SIZE
add_interface_port sp_wishbone       sp_DAT_I     DAT_O     input  REGISTER_SIZE
add_interface_port sp_wishbone       sp_WE_I      WE_O      input  1
add_interface_port sp_wishbone       sp_SEL_I     SEL_O     input  REGISTER_SIZE/8
add_interface_port sp_wishbone       sp_STB_I     STB_O     input  1
add_interface_port sp_wishbone       sp_ACK_O     ACK_I     output 1
add_interface_port sp_wishbone       sp_CYC_I     CYC_O     input  1
add_interface_port sp_wishbone       sp_CTI_I     CTI_O     input  3
add_interface_port sp_wishbone       sp_STALL_O   STALL_I   output 1

#
# connection point lmb_iuc (disabled)
#
add_interface lmb_iuc conduit end
set_interface_property lmb_iuc associatedClock ""
set_interface_property lmb_iuc associatedReset ""
set_interface_property lmb_iuc ENABLED false
set_interface_property lmb_iuc EXPORT_OF ""
set_interface_property lmb_iuc PORT_NAME_MAP ""
set_interface_property lmb_iuc CMSIS_SVD_VARIABLES ""
set_interface_property lmb_iuc SVD_ADDRESS_GROUP ""

add_interface_port lmb_iuc ILMB_Addr         Addr         output REGISTER_SIZE
add_interface_port lmb_iuc ILMB_Byte_Enable  Byte_Enable  output REGISTER_SIZE/8
add_interface_port lmb_iuc ILMB_Data_Write   Data_Write   output REGISTER_SIZE
add_interface_port lmb_iuc ILMB_AS           AS           output 1
add_interface_port lmb_iuc ILMB_Read_Strobe  Read_Strobe  output 1
add_interface_port lmb_iuc ILMB_Write_Strobe Write_Strobe output 1
add_interface_port lmb_iuc ILMB_Data_Read    Data_Read    input  REGISTER_SIZE
add_interface_port lmb_iuc ILMB_Ready        Ready        input  1
add_interface_port lmb_iuc ILMB_Wait         Wait         input  1
add_interface_port lmb_iuc ILMB_CE           CE           input  1
add_interface_port lmb_iuc ILMB_UE           UE           input  1

#
# connection point lmb_duc (disabled)
#
add_interface lmb_duc conduit end
set_interface_property lmb_duc associatedClock ""
set_interface_property lmb_duc associatedReset ""
set_interface_property lmb_duc ENABLED false
set_interface_property lmb_duc EXPORT_OF ""
set_interface_property lmb_duc PORT_NAME_MAP ""
set_interface_property lmb_duc CMSIS_SVD_VARIABLES ""
set_interface_property lmb_duc SVD_ADDRESS_GROUP ""

add_interface_port lmb_duc DLMB_Addr         Addr         output REGISTER_SIZE
add_interface_port lmb_duc DLMB_Byte_Enable  Byte_Enable  output REGISTER_SIZE/8
add_interface_port lmb_duc DLMB_Data_Write   Data_Write   output REGISTER_SIZE
add_interface_port lmb_duc DLMB_AS           AS           output 1
add_interface_port lmb_duc DLMB_Read_Strobe  Read_Strobe  output 1
add_interface_port lmb_duc DLMB_Write_Strobe Write_Strobe output 1
add_interface_port lmb_duc DLMB_Data_Read    Data_Read    input  REGISTER_SIZE
add_interface_port lmb_duc DLMB_Ready        Ready        input  1
add_interface_port lmb_duc DLMB_Wait         Wait         input  1
add_interface_port lmb_duc DLMB_CE           CE           input  1
add_interface_port lmb_duc DLMB_UE           UE           input  1


proc log_out {out_str} {
    set chan [open ~/orca_hw_log.txt a]
    set timestamp [clock format [clock seconds]]
    puts $chan "$timestamp $out_str"
    close $chan
}

proc elaboration_callback {} {
    if { [get_parameter_value MULTIPLY_ENABLE] } {
        set_display_item_property SHIFTER_MAX_CYCLES ENABLED false
    } else {
        set_display_item_property SHIFTER_MAX_CYCLES ENABLED true
    }

    set_interface_property axi_ic_master readIssuingCapability [get_parameter_value MAX_IFETCHES_IN_FLIGHT]
    set_interface_property axi_ic_master combinedIssuingCapability [get_parameter_value MAX_IFETCHES_IN_FLIGHT]
    set_interface_property axi_iuc       readIssuingCapability [get_parameter_value MAX_IFETCHES_IN_FLIGHT]
    set_interface_property axi_iuc       combinedIssuingCapability [get_parameter_value MAX_IFETCHES_IN_FLIGHT]

    if { [get_parameter_value LVE_ENABLE] } {
        set_interface_property scratchpad_clk ENABLED true
        set_interface_property scratch ENABLED true
        set_parameter_property SCRATCHPAD_SIZE visible true
    } else {
        set_interface_property scratchpad_clk ENABLED false
        set_interface_property scratch ENABLED false
        set_parameter_property SCRATCHPAD_SIZE visible false
    }
    set sp_size [expr 1024*[get_parameter_value SCRATCHPAD_SIZE ] ]
    set log_size [log2 $sp_size]
    set_parameter_value SCRATCHPAD_ADDR_BITS $log_size
    if { [expr 2**$log_size != $sp_size ] } {
        send_message Error "Scratchpad size is not a power of two"
    }

    if { [get_parameter_value ENABLE_EXCEPTIONS] } {
        set_parameter_property ENABLE_EXT_INTERRUPTS visible true
        if { [get_parameter_value ENABLE_EXT_INTERRUPTS] } {
            set_parameter_property NUM_EXT_INTERRUPTS visible true
            set_interface_property global_interrupts enabled true
        } else {
            set_parameter_property NUM_EXT_INTERRUPTS visible false
            set_interface_property global_interrupts enabled false
        }
    } else {
        set_parameter_property ENABLE_EXT_INTERRUPTS visible false
        set_parameter_property NUM_EXT_INTERRUPTS visible false
        set_interface_property global_interrupts enabled false
    }

    if { [get_parameter_value ICACHE_SIZE] != 0 } {
        set_interface_property axi_ic_master ENABLED true
    } else {
        set_interface_property axi_ic_master ENABLED false
    }
    if { [get_parameter_value DCACHE_SIZE] != 0 } {
        set_interface_property axi_dc_master ENABLED true
    } else {
        set_interface_property axi_dc_master ENABLED false
    }
    if { [get_parameter_value IUC_ADDR_BASE] != [get_parameter_value IUC_ADDR_LAST] } {
        set_interface_property axi_iuc ENABLED true
    } else {
        set_interface_property axi_iuc ENABLED false
    }
    if { [get_parameter_value DUC_ADDR_BASE] != [get_parameter_value DUC_ADDR_LAST] } {
        set_interface_property axi_duc ENABLED true
    } else {
        set_interface_property axi_duc ENABLED false
    }
    if { [get_parameter_value IAUX_ADDR_BASE] != [get_parameter_value IAUX_ADDR_LAST] } {
        set_interface_property instruction ENABLED true
    } else {
        set_interface_property instruction ENABLED false
    }
    if { [get_parameter_value DAUX_ADDR_BASE] != [get_parameter_value DAUX_ADDR_LAST] } {
        set_interface_property data ENABLED true
    } else {
        set_interface_property data ENABLED false
    }
}
