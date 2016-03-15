package require -exact qsys 14.0

# module properties
set_module_property NAME {vblox1_export}
set_module_property DISPLAY_NAME {vblox1_export_display}

# default module properties
set_module_property VERSION {1.0}
set_module_property GROUP {default group}
set_module_property DESCRIPTION {default description}
set_module_property AUTHOR {author}

set_module_property COMPOSITION_CALLBACK compose
set_module_property opaque_address_map false

proc compose { } {
    # Instances and instance parameters
    # (disabled instances are intentionally culled)
    add_instance altpll_0 altpll 15.0
    set_instance_parameter_value altpll_0 {HIDDEN_CUSTOM_ELABORATION} {altpll_avalon_elaboration}
    set_instance_parameter_value altpll_0 {HIDDEN_CUSTOM_POST_EDIT} {altpll_avalon_post_edit}
    set_instance_parameter_value altpll_0 {INTENDED_DEVICE_FAMILY} {Cyclone IV E}
    set_instance_parameter_value altpll_0 {WIDTH_CLOCK} {5}
    set_instance_parameter_value altpll_0 {WIDTH_PHASECOUNTERSELECT} {}
    set_instance_parameter_value altpll_0 {PRIMARY_CLOCK} {}
    set_instance_parameter_value altpll_0 {INCLK0_INPUT_FREQUENCY} {20000}
    set_instance_parameter_value altpll_0 {INCLK1_INPUT_FREQUENCY} {}
    set_instance_parameter_value altpll_0 {OPERATION_MODE} {NORMAL}
    set_instance_parameter_value altpll_0 {PLL_TYPE} {AUTO}
    set_instance_parameter_value altpll_0 {QUALIFY_CONF_DONE} {}
    set_instance_parameter_value altpll_0 {COMPENSATE_CLOCK} {CLK0}
    set_instance_parameter_value altpll_0 {SCAN_CHAIN} {}
    set_instance_parameter_value altpll_0 {GATE_LOCK_SIGNAL} {}
    set_instance_parameter_value altpll_0 {GATE_LOCK_COUNTER} {}
    set_instance_parameter_value altpll_0 {LOCK_HIGH} {}
    set_instance_parameter_value altpll_0 {LOCK_LOW} {}
    set_instance_parameter_value altpll_0 {VALID_LOCK_MULTIPLIER} {}
    set_instance_parameter_value altpll_0 {INVALID_LOCK_MULTIPLIER} {}
    set_instance_parameter_value altpll_0 {SWITCH_OVER_ON_LOSSCLK} {}
    set_instance_parameter_value altpll_0 {SWITCH_OVER_ON_GATED_LOCK} {}
    set_instance_parameter_value altpll_0 {ENABLE_SWITCH_OVER_COUNTER} {}
    set_instance_parameter_value altpll_0 {SKIP_VCO} {}
    set_instance_parameter_value altpll_0 {SWITCH_OVER_COUNTER} {}
    set_instance_parameter_value altpll_0 {SWITCH_OVER_TYPE} {}
    set_instance_parameter_value altpll_0 {FEEDBACK_SOURCE} {}
    set_instance_parameter_value altpll_0 {BANDWIDTH} {}
    set_instance_parameter_value altpll_0 {BANDWIDTH_TYPE} {AUTO}
    set_instance_parameter_value altpll_0 {SPREAD_FREQUENCY} {}
    set_instance_parameter_value altpll_0 {DOWN_SPREAD} {}
    set_instance_parameter_value altpll_0 {SELF_RESET_ON_GATED_LOSS_LOCK} {}
    set_instance_parameter_value altpll_0 {SELF_RESET_ON_LOSS_LOCK} {}
    set_instance_parameter_value altpll_0 {CLK0_MULTIPLY_BY} {1}
    set_instance_parameter_value altpll_0 {CLK1_MULTIPLY_BY} {3}
    set_instance_parameter_value altpll_0 {CLK2_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {CLK3_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {CLK4_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {CLK5_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {CLK6_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {CLK7_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {CLK8_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {CLK9_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {EXTCLK0_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {EXTCLK1_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {EXTCLK2_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {EXTCLK3_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {CLK0_DIVIDE_BY} {1}
    set_instance_parameter_value altpll_0 {CLK1_DIVIDE_BY} {1}
    set_instance_parameter_value altpll_0 {CLK2_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {CLK3_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {CLK4_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {CLK5_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {CLK6_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {CLK7_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {CLK8_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {CLK9_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {EXTCLK0_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {EXTCLK1_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {EXTCLK2_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {EXTCLK3_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {CLK0_PHASE_SHIFT} {0}
    set_instance_parameter_value altpll_0 {CLK1_PHASE_SHIFT} {0}
    set_instance_parameter_value altpll_0 {CLK2_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {CLK3_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {CLK4_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {CLK5_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {CLK6_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {CLK7_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {CLK8_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {CLK9_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {EXTCLK0_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {EXTCLK1_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {EXTCLK2_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {EXTCLK3_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {CLK0_DUTY_CYCLE} {50}
    set_instance_parameter_value altpll_0 {CLK1_DUTY_CYCLE} {50}
    set_instance_parameter_value altpll_0 {CLK2_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {CLK3_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {CLK4_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {CLK5_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {CLK6_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {CLK7_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {CLK8_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {CLK9_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {EXTCLK0_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {EXTCLK1_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {EXTCLK2_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {EXTCLK3_DUTY_CYCLE} {}
    set_instance_parameter_value altpll_0 {PORT_clkena0} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clkena1} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clkena2} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clkena3} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clkena4} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clkena5} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_extclkena0} {}
    set_instance_parameter_value altpll_0 {PORT_extclkena1} {}
    set_instance_parameter_value altpll_0 {PORT_extclkena2} {}
    set_instance_parameter_value altpll_0 {PORT_extclkena3} {}
    set_instance_parameter_value altpll_0 {PORT_extclk0} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_extclk1} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_extclk2} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_extclk3} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_CLKBAD0} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_CLKBAD1} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clk0} {PORT_USED}
    set_instance_parameter_value altpll_0 {PORT_clk1} {PORT_USED}
    set_instance_parameter_value altpll_0 {PORT_clk2} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clk3} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clk4} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clk5} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_clk6} {}
    set_instance_parameter_value altpll_0 {PORT_clk7} {}
    set_instance_parameter_value altpll_0 {PORT_clk8} {}
    set_instance_parameter_value altpll_0 {PORT_clk9} {}
    set_instance_parameter_value altpll_0 {PORT_SCANDATA} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_SCANDATAOUT} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_SCANDONE} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_SCLKOUT1} {}
    set_instance_parameter_value altpll_0 {PORT_SCLKOUT0} {}
    set_instance_parameter_value altpll_0 {PORT_ACTIVECLOCK} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_CLKLOSS} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_INCLK1} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_INCLK0} {PORT_USED}
    set_instance_parameter_value altpll_0 {PORT_FBIN} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_PLLENA} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_CLKSWITCH} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_ARESET} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_PFDENA} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_SCANCLK} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_SCANACLR} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_SCANREAD} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_SCANWRITE} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_ENABLE0} {}
    set_instance_parameter_value altpll_0 {PORT_ENABLE1} {}
    set_instance_parameter_value altpll_0 {PORT_LOCKED} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_CONFIGUPDATE} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_FBOUT} {}
    set_instance_parameter_value altpll_0 {PORT_PHASEDONE} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_PHASESTEP} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_PHASEUPDOWN} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_SCANCLKENA} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_PHASECOUNTERSELECT} {PORT_UNUSED}
    set_instance_parameter_value altpll_0 {PORT_VCOOVERRANGE} {}
    set_instance_parameter_value altpll_0 {PORT_VCOUNDERRANGE} {}
    set_instance_parameter_value altpll_0 {DPA_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {DPA_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {DPA_DIVIDER} {}
    set_instance_parameter_value altpll_0 {VCO_MULTIPLY_BY} {}
    set_instance_parameter_value altpll_0 {VCO_DIVIDE_BY} {}
    set_instance_parameter_value altpll_0 {SCLKOUT0_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {SCLKOUT1_PHASE_SHIFT} {}
    set_instance_parameter_value altpll_0 {VCO_FREQUENCY_CONTROL} {}
    set_instance_parameter_value altpll_0 {VCO_PHASE_SHIFT_STEP} {}
    set_instance_parameter_value altpll_0 {USING_FBMIMICBIDIR_PORT} {}
    set_instance_parameter_value altpll_0 {SCAN_CHAIN_MIF_FILE} {}
    set_instance_parameter_value altpll_0 {AVALON_USE_SEPARATE_SYSCLK} {NO}
    set_instance_parameter_value altpll_0 {HIDDEN_CONSTANTS} {CT#PORT_clk5 PORT_UNUSED CT#PORT_clk4 PORT_UNUSED CT#PORT_clk3 PORT_UNUSED CT#PORT_clk2 PORT_UNUSED CT#PORT_clk1 PORT_USED CT#PORT_clk0 PORT_USED CT#CLK0_MULTIPLY_BY 1 CT#PORT_SCANWRITE PORT_UNUSED CT#PORT_SCANACLR PORT_UNUSED CT#PORT_PFDENA PORT_UNUSED CT#PORT_PLLENA PORT_UNUSED CT#PORT_SCANDATA PORT_UNUSED CT#PORT_SCANCLKENA PORT_UNUSED CT#WIDTH_CLOCK 5 CT#PORT_SCANDATAOUT PORT_UNUSED CT#LPM_TYPE altpll CT#PLL_TYPE AUTO CT#CLK0_PHASE_SHIFT 0 CT#CLK1_DUTY_CYCLE 50 CT#PORT_PHASEDONE PORT_UNUSED CT#OPERATION_MODE NORMAL CT#PORT_CONFIGUPDATE PORT_UNUSED CT#CLK1_MULTIPLY_BY 3 CT#COMPENSATE_CLOCK CLK0 CT#PORT_CLKSWITCH PORT_UNUSED CT#INCLK0_INPUT_FREQUENCY 20000 CT#PORT_SCANDONE PORT_UNUSED CT#PORT_CLKLOSS PORT_UNUSED CT#PORT_INCLK1 PORT_UNUSED CT#AVALON_USE_SEPARATE_SYSCLK NO CT#PORT_INCLK0 PORT_USED CT#PORT_clkena5 PORT_UNUSED CT#PORT_clkena4 PORT_UNUSED CT#PORT_clkena3 PORT_UNUSED CT#PORT_clkena2 PORT_UNUSED CT#PORT_clkena1 PORT_UNUSED CT#PORT_clkena0 PORT_UNUSED CT#CLK1_PHASE_SHIFT 0 CT#PORT_ARESET PORT_UNUSED CT#BANDWIDTH_TYPE AUTO CT#INTENDED_DEVICE_FAMILY {Cyclone IV E} CT#PORT_SCANREAD PORT_UNUSED CT#PORT_PHASESTEP PORT_UNUSED CT#PORT_SCANCLK PORT_UNUSED CT#PORT_CLKBAD1 PORT_UNUSED CT#PORT_CLKBAD0 PORT_UNUSED CT#PORT_FBIN PORT_UNUSED CT#PORT_PHASEUPDOWN PORT_UNUSED CT#PORT_extclk3 PORT_UNUSED CT#PORT_extclk2 PORT_UNUSED CT#PORT_extclk1 PORT_UNUSED CT#PORT_PHASECOUNTERSELECT PORT_UNUSED CT#PORT_extclk0 PORT_UNUSED CT#PORT_ACTIVECLOCK PORT_UNUSED CT#CLK0_DUTY_CYCLE 50 CT#CLK0_DIVIDE_BY 1 CT#CLK1_DIVIDE_BY 1 CT#PORT_LOCKED PORT_UNUSED}
    set_instance_parameter_value altpll_0 {HIDDEN_PRIVATES} {PT#GLOCKED_FEATURE_ENABLED 0 PT#SPREAD_FEATURE_ENABLED 0 PT#BANDWIDTH_FREQ_UNIT MHz PT#CUR_DEDICATED_CLK c0 PT#INCLK0_FREQ_EDIT 50.000 PT#BANDWIDTH_PRESET Low PT#PLL_LVDS_PLL_CHECK 0 PT#BANDWIDTH_USE_PRESET 0 PT#AVALON_USE_SEPARATE_SYSCLK NO PT#PLL_ENHPLL_CHECK 0 PT#OUTPUT_FREQ_UNIT1 MHz PT#OUTPUT_FREQ_UNIT0 MHz PT#PHASE_RECONFIG_FEATURE_ENABLED 1 PT#CREATE_CLKBAD_CHECK 0 PT#CLKSWITCH_CHECK 0 PT#INCLK1_FREQ_EDIT 100.000 PT#NORMAL_MODE_RADIO 1 PT#SRC_SYNCH_COMP_RADIO 0 PT#PLL_ARESET_CHECK 0 PT#LONG_SCAN_RADIO 1 PT#SCAN_FEATURE_ENABLED 1 PT#PHASE_RECONFIG_INPUTS_CHECK 0 PT#USE_CLK1 1 PT#USE_CLK0 1 PT#PRIMARY_CLK_COMBO inclk0 PT#BANDWIDTH 1.000 PT#GLOCKED_COUNTER_EDIT_CHANGED 1 PT#PLL_FASTPLL_CHECK 0 PT#SPREAD_FREQ_UNIT KHz PT#PLL_AUTOPLL_CHECK 1 PT#LVDS_PHASE_SHIFT_UNIT1 deg PT#LVDS_PHASE_SHIFT_UNIT0 deg PT#OUTPUT_FREQ_MODE1 0 PT#SWITCHOVER_FEATURE_ENABLED 0 PT#MIG_DEVICE_SPEED_GRADE Any PT#OUTPUT_FREQ_MODE0 0 PT#BANDWIDTH_FEATURE_ENABLED 1 PT#INCLK0_FREQ_UNIT_COMBO MHz PT#ZERO_DELAY_RADIO 0 PT#OUTPUT_FREQ1 100.00000000 PT#OUTPUT_FREQ0 100.00000000 PT#SHORT_SCAN_RADIO 0 PT#LVDS_MODE_DATA_RATE_DIRTY 0 PT#CUR_FBIN_CLK c0 PT#PLL_ADVANCED_PARAM_CHECK 0 PT#CLKBAD_SWITCHOVER_CHECK 0 PT#PHASE_SHIFT_STEP_ENABLED_CHECK 0 PT#DEVICE_SPEED_GRADE Any PT#PLL_FBMIMIC_CHECK 0 PT#LVDS_MODE_DATA_RATE {Not Available} PT#LOCKED_OUTPUT_CHECK 0 PT#SPREAD_PERCENT 0.500 PT#PHASE_SHIFT1 0.00000000 PT#PHASE_SHIFT0 0.00000000 PT#DIV_FACTOR1 1 PT#DIV_FACTOR0 1 PT#CNX_NO_COMPENSATE_RADIO 0 PT#USE_CLKENA1 0 PT#USE_CLKENA0 0 PT#CREATE_INCLK1_CHECK 0 PT#GLOCK_COUNTER_EDIT 1048575 PT#INCLK1_FREQ_UNIT_COMBO MHz PT#EFF_OUTPUT_FREQ_VALUE1 150.000000 PT#EFF_OUTPUT_FREQ_VALUE0 50.000000 PT#SPREAD_FREQ 50.000 PT#USE_MIL_SPEED_GRADE 0 PT#EXPLICIT_SWITCHOVER_COUNTER 0 PT#STICKY_CLK1 1 PT#STICKY_CLK0 1 PT#EXT_FEEDBACK_RADIO 0 PT#MIRROR_CLK1 0 PT#MIRROR_CLK0 0 PT#SWITCHOVER_COUNT_EDIT 1 PT#SELF_RESET_LOCK_LOSS 0 PT#PLL_PFDENA_CHECK 0 PT#INT_FEEDBACK__MODE_RADIO 1 PT#INCLK1_FREQ_EDIT_CHANGED 1 PT#CLKLOSS_CHECK 0 PT#SYNTH_WRAPPER_GEN_POSTFIX 0 PT#PHASE_SHIFT_UNIT1 deg PT#PHASE_SHIFT_UNIT0 deg PT#BANDWIDTH_USE_AUTO 1 PT#HAS_MANUAL_SWITCHOVER 1 PT#MULT_FACTOR1 3 PT#MULT_FACTOR0 1 PT#SPREAD_USE 0 PT#GLOCKED_MODE_CHECK 0 PT#SACN_INPUTS_CHECK 0 PT#DUTY_CYCLE1 50.00000000 PT#INTENDED_DEVICE_FAMILY {Cyclone IV E} PT#DUTY_CYCLE0 50.00000000 PT#PLL_TARGET_HARCOPY_CHECK 0 PT#INCLK1_FREQ_UNIT_CHANGED 1 PT#RECONFIG_FILE ALTPLL1457388433003992.mif PT#ACTIVECLK_CHECK 0}
    set_instance_parameter_value altpll_0 {HIDDEN_USED_PORTS} {UP#locked used UP#c1 used UP#c0 used UP#areset used UP#inclk0 used}
    set_instance_parameter_value altpll_0 {HIDDEN_IS_NUMERIC} {IN#WIDTH_CLOCK 1 IN#CLK0_DUTY_CYCLE 1 IN#PLL_TARGET_HARCOPY_CHECK 1 IN#CLK1_MULTIPLY_BY 1 IN#SWITCHOVER_COUNT_EDIT 1 IN#INCLK0_INPUT_FREQUENCY 1 IN#PLL_LVDS_PLL_CHECK 1 IN#PLL_AUTOPLL_CHECK 1 IN#PLL_FASTPLL_CHECK 1 IN#CLK1_DUTY_CYCLE 1 IN#PLL_ENHPLL_CHECK 1 IN#DIV_FACTOR1 1 IN#DIV_FACTOR0 1 IN#LVDS_MODE_DATA_RATE_DIRTY 1 IN#GLOCK_COUNTER_EDIT 1 IN#CLK0_DIVIDE_BY 1 IN#MULT_FACTOR1 1 IN#MULT_FACTOR0 1 IN#CLK0_MULTIPLY_BY 1 IN#USE_MIL_SPEED_GRADE 1 IN#CLK1_DIVIDE_BY 1}
    set_instance_parameter_value altpll_0 {HIDDEN_MF_PORTS} {MF#areset 1 MF#clk 1 MF#locked 1 MF#inclk 1}
    set_instance_parameter_value altpll_0 {HIDDEN_IF_PORTS} {IF#locked {output 0} IF#reset {input 0} IF#clk {input 0} IF#readdata {output 32} IF#write {input 0} IF#phasedone {output 0} IF#address {input 2} IF#c1 {output 0} IF#c0 {output 0} IF#writedata {input 32} IF#read {input 0} IF#areset {input 0}}
    set_instance_parameter_value altpll_0 {HIDDEN_IS_FIRST_EDIT} {0}

    add_instance clk_0 clock_source 15.0
    set_instance_parameter_value clk_0 {clockFrequency} {50000000.0}
    set_instance_parameter_value clk_0 {clockFrequencyKnown} {1}
    set_instance_parameter_value clk_0 {resetSynchronousEdges} {NONE}

    add_instance hex_0 altera_avalon_pio 15.0
    set_instance_parameter_value hex_0 {bitClearingEdgeCapReg} {0}
    set_instance_parameter_value hex_0 {bitModifyingOutReg} {0}
    set_instance_parameter_value hex_0 {captureEdge} {0}
    set_instance_parameter_value hex_0 {direction} {Output}
    set_instance_parameter_value hex_0 {edgeType} {RISING}
    set_instance_parameter_value hex_0 {generateIRQ} {0}
    set_instance_parameter_value hex_0 {irqType} {LEVEL}
    set_instance_parameter_value hex_0 {resetValue} {0.0}
    set_instance_parameter_value hex_0 {simDoTestBenchWiring} {0}
    set_instance_parameter_value hex_0 {simDrivenValue} {0.0}
    set_instance_parameter_value hex_0 {width} {32}

    add_instance hex_1 altera_avalon_pio 15.0
    set_instance_parameter_value hex_1 {bitClearingEdgeCapReg} {0}
    set_instance_parameter_value hex_1 {bitModifyingOutReg} {0}
    set_instance_parameter_value hex_1 {captureEdge} {0}
    set_instance_parameter_value hex_1 {direction} {Output}
    set_instance_parameter_value hex_1 {edgeType} {RISING}
    set_instance_parameter_value hex_1 {generateIRQ} {0}
    set_instance_parameter_value hex_1 {irqType} {LEVEL}
    set_instance_parameter_value hex_1 {resetValue} {0.0}
    set_instance_parameter_value hex_1 {simDoTestBenchWiring} {0}
    set_instance_parameter_value hex_1 {simDrivenValue} {0.0}
    set_instance_parameter_value hex_1 {width} {32}

    add_instance hex_2 altera_avalon_pio 15.0
    set_instance_parameter_value hex_2 {bitClearingEdgeCapReg} {0}
    set_instance_parameter_value hex_2 {bitModifyingOutReg} {0}
    set_instance_parameter_value hex_2 {captureEdge} {0}
    set_instance_parameter_value hex_2 {direction} {Output}
    set_instance_parameter_value hex_2 {edgeType} {RISING}
    set_instance_parameter_value hex_2 {generateIRQ} {0}
    set_instance_parameter_value hex_2 {irqType} {LEVEL}
    set_instance_parameter_value hex_2 {resetValue} {0.0}
    set_instance_parameter_value hex_2 {simDoTestBenchWiring} {0}
    set_instance_parameter_value hex_2 {simDrivenValue} {0.0}
    set_instance_parameter_value hex_2 {width} {32}

    add_instance hex_3 altera_avalon_pio 15.0
    set_instance_parameter_value hex_3 {bitClearingEdgeCapReg} {0}
    set_instance_parameter_value hex_3 {bitModifyingOutReg} {0}
    set_instance_parameter_value hex_3 {captureEdge} {0}
    set_instance_parameter_value hex_3 {direction} {Output}
    set_instance_parameter_value hex_3 {edgeType} {RISING}
    set_instance_parameter_value hex_3 {generateIRQ} {0}
    set_instance_parameter_value hex_3 {irqType} {LEVEL}
    set_instance_parameter_value hex_3 {resetValue} {0.0}
    set_instance_parameter_value hex_3 {simDoTestBenchWiring} {0}
    set_instance_parameter_value hex_3 {simDrivenValue} {0.0}
    set_instance_parameter_value hex_3 {width} {32}

    add_instance jtag_uart_0 altera_avalon_jtag_uart 15.0
    set_instance_parameter_value jtag_uart_0 {allowMultipleConnections} {0}
    set_instance_parameter_value jtag_uart_0 {hubInstanceID} {0}
    set_instance_parameter_value jtag_uart_0 {readBufferDepth} {64}
    set_instance_parameter_value jtag_uart_0 {readIRQThreshold} {8}
    set_instance_parameter_value jtag_uart_0 {simInputCharacterStream} {}
    set_instance_parameter_value jtag_uart_0 {simInteractiveOptions} {NO_INTERACTIVE_WINDOWS}
    set_instance_parameter_value jtag_uart_0 {useRegistersForReadBuffer} {0}
    set_instance_parameter_value jtag_uart_0 {useRegistersForWriteBuffer} {0}
    set_instance_parameter_value jtag_uart_0 {useRelativePathForSimFile} {0}
    set_instance_parameter_value jtag_uart_0 {writeBufferDepth} {64}
    set_instance_parameter_value jtag_uart_0 {writeIRQThreshold} {8}

    add_instance ledg altera_avalon_pio 15.0
    set_instance_parameter_value ledg {bitClearingEdgeCapReg} {0}
    set_instance_parameter_value ledg {bitModifyingOutReg} {0}
    set_instance_parameter_value ledg {captureEdge} {0}
    set_instance_parameter_value ledg {direction} {Output}
    set_instance_parameter_value ledg {edgeType} {RISING}
    set_instance_parameter_value ledg {generateIRQ} {0}
    set_instance_parameter_value ledg {irqType} {LEVEL}
    set_instance_parameter_value ledg {resetValue} {0.0}
    set_instance_parameter_value ledg {simDoTestBenchWiring} {0}
    set_instance_parameter_value ledg {simDrivenValue} {0.0}
    set_instance_parameter_value ledg {width} {32}

    add_instance ledr altera_avalon_pio 15.0
    set_instance_parameter_value ledr {bitClearingEdgeCapReg} {0}
    set_instance_parameter_value ledr {bitModifyingOutReg} {0}
    set_instance_parameter_value ledr {captureEdge} {0}
    set_instance_parameter_value ledr {direction} {Output}
    set_instance_parameter_value ledr {edgeType} {RISING}
    set_instance_parameter_value ledr {generateIRQ} {0}
    set_instance_parameter_value ledr {irqType} {LEVEL}
    set_instance_parameter_value ledr {resetValue} {0.0}
    set_instance_parameter_value ledr {simDoTestBenchWiring} {0}
    set_instance_parameter_value ledr {simDrivenValue} {0.0}
    set_instance_parameter_value ledr {width} {32}

    add_instance mm_bridge_0 altera_avalon_mm_bridge 15.0
    set_instance_parameter_value mm_bridge_0 {DATA_WIDTH} {32}
    set_instance_parameter_value mm_bridge_0 {SYMBOL_WIDTH} {8}
    set_instance_parameter_value mm_bridge_0 {ADDRESS_WIDTH} {10}
    set_instance_parameter_value mm_bridge_0 {USE_AUTO_ADDRESS_WIDTH} {1}
    set_instance_parameter_value mm_bridge_0 {ADDRESS_UNITS} {SYMBOLS}
    set_instance_parameter_value mm_bridge_0 {MAX_BURST_SIZE} {1}
    set_instance_parameter_value mm_bridge_0 {MAX_PENDING_RESPONSES} {1}
    set_instance_parameter_value mm_bridge_0 {LINEWRAPBURSTS} {0}
    set_instance_parameter_value mm_bridge_0 {PIPELINE_COMMAND} {0}
    set_instance_parameter_value mm_bridge_0 {PIPELINE_RESPONSE} {0}
    set_instance_parameter_value mm_bridge_0 {USE_RESPONSE} {0}

    add_instance onchip_memory2_0 altera_avalon_onchip_memory2 15.0
    set_instance_parameter_value onchip_memory2_0 {allowInSystemMemoryContentEditor} {0}
    set_instance_parameter_value onchip_memory2_0 {blockType} {AUTO}
    set_instance_parameter_value onchip_memory2_0 {dataWidth} {32}
    set_instance_parameter_value onchip_memory2_0 {dualPort} {1}
    set_instance_parameter_value onchip_memory2_0 {initMemContent} {1}
    set_instance_parameter_value onchip_memory2_0 {initializationFileName} {test.hex}
    set_instance_parameter_value onchip_memory2_0 {instanceID} {NONE}
    set_instance_parameter_value onchip_memory2_0 {memorySize} {65536.0}
    set_instance_parameter_value onchip_memory2_0 {readDuringWriteMode} {DONT_CARE}
    set_instance_parameter_value onchip_memory2_0 {simAllowMRAMContentsFile} {0}
    set_instance_parameter_value onchip_memory2_0 {simMemInitOnlyFilename} {0}
    set_instance_parameter_value onchip_memory2_0 {singleClockOperation} {0}
    set_instance_parameter_value onchip_memory2_0 {slave1Latency} {1}
    set_instance_parameter_value onchip_memory2_0 {slave2Latency} {1}
    set_instance_parameter_value onchip_memory2_0 {useNonDefaultInitFile} {1}
    set_instance_parameter_value onchip_memory2_0 {copyInitFile} {0}
    set_instance_parameter_value onchip_memory2_0 {useShallowMemBlocks} {0}
    set_instance_parameter_value onchip_memory2_0 {writable} {1}
    set_instance_parameter_value onchip_memory2_0 {ecc_enabled} {0}
    set_instance_parameter_value onchip_memory2_0 {resetrequest_enabled} {1}

    add_instance pmod_mic_0 pmod_mic 1.0
    set_instance_parameter_value pmod_mic_0 {PORTS} {1}
    set_instance_parameter_value pmod_mic_0 {CLK_FREQ_HZ} {50000000}
    set_instance_parameter_value pmod_mic_0 {SAMPLE_RATE_HZ} {10000}

    add_instance riscv_0 riscv 1.0
    set_instance_parameter_value riscv_0 {REGISTER_SIZE} {32}
    set_instance_parameter_value riscv_0 {MXP_ENABLE} {1}
    set_instance_parameter_value riscv_0 {RESET_VECTOR} {512}
    set_instance_parameter_value riscv_0 {MULTIPLY_ENABLE} {0}
    set_instance_parameter_value riscv_0 {DIVIDE_ENABLE} {0}
    set_instance_parameter_value riscv_0 {SHIFTER_MAX_CYCLES} {1}
    set_instance_parameter_value riscv_0 {FORWARD_ALU_ONLY} {1}
    set_instance_parameter_value riscv_0 {COUNTER_LENGTH} {32}
    set_instance_parameter_value riscv_0 {BRANCH_PREDICTION} {0}
    set_instance_parameter_value riscv_0 {BTB_SIZE} {256}
    set_instance_parameter_value riscv_0 {PIPELINE_STAGES} {4}

    # connections and connection parameters
    add_connection riscv_0.data mm_bridge_0.s0 avalon
    set_connection_parameter_value riscv_0.data/mm_bridge_0.s0 arbitrationPriority {1}
    set_connection_parameter_value riscv_0.data/mm_bridge_0.s0 baseAddress {0x0000}
    set_connection_parameter_value riscv_0.data/mm_bridge_0.s0 defaultConnection {0}

    add_connection riscv_0.instruction onchip_memory2_0.s1 avalon
    set_connection_parameter_value riscv_0.instruction/onchip_memory2_0.s1 arbitrationPriority {1}
    set_connection_parameter_value riscv_0.instruction/onchip_memory2_0.s1 baseAddress {0x0000}
    set_connection_parameter_value riscv_0.instruction/onchip_memory2_0.s1 defaultConnection {0}

    add_connection mm_bridge_0.m0 jtag_uart_0.avalon_jtag_slave avalon
    set_connection_parameter_value mm_bridge_0.m0/jtag_uart_0.avalon_jtag_slave arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/jtag_uart_0.avalon_jtag_slave baseAddress {0x00010270}
    set_connection_parameter_value mm_bridge_0.m0/jtag_uart_0.avalon_jtag_slave defaultConnection {0}

    add_connection mm_bridge_0.m0 pmod_mic_0.avalon_slave avalon
    set_connection_parameter_value mm_bridge_0.m0/pmod_mic_0.avalon_slave arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/pmod_mic_0.avalon_slave baseAddress {0x00010000}
    set_connection_parameter_value mm_bridge_0.m0/pmod_mic_0.avalon_slave defaultConnection {0}

    add_connection mm_bridge_0.m0 altpll_0.pll_slave avalon
    set_connection_parameter_value mm_bridge_0.m0/altpll_0.pll_slave arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/altpll_0.pll_slave baseAddress {0x00010260}
    set_connection_parameter_value mm_bridge_0.m0/altpll_0.pll_slave defaultConnection {0}

    add_connection mm_bridge_0.m0 hex_3.s1 avalon
    set_connection_parameter_value mm_bridge_0.m0/hex_3.s1 arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/hex_3.s1 baseAddress {0x00010250}
    set_connection_parameter_value mm_bridge_0.m0/hex_3.s1 defaultConnection {0}

    add_connection mm_bridge_0.m0 hex_2.s1 avalon
    set_connection_parameter_value mm_bridge_0.m0/hex_2.s1 arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/hex_2.s1 baseAddress {0x00010240}
    set_connection_parameter_value mm_bridge_0.m0/hex_2.s1 defaultConnection {0}

    add_connection mm_bridge_0.m0 hex_1.s1 avalon
    set_connection_parameter_value mm_bridge_0.m0/hex_1.s1 arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/hex_1.s1 baseAddress {0x00010230}
    set_connection_parameter_value mm_bridge_0.m0/hex_1.s1 defaultConnection {0}

    add_connection mm_bridge_0.m0 hex_0.s1 avalon
    set_connection_parameter_value mm_bridge_0.m0/hex_0.s1 arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/hex_0.s1 baseAddress {0x00010220}
    set_connection_parameter_value mm_bridge_0.m0/hex_0.s1 defaultConnection {0}

    add_connection mm_bridge_0.m0 ledr.s1 avalon
    set_connection_parameter_value mm_bridge_0.m0/ledr.s1 arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/ledr.s1 baseAddress {0x00010210}
    set_connection_parameter_value mm_bridge_0.m0/ledr.s1 defaultConnection {0}

    add_connection mm_bridge_0.m0 ledg.s1 avalon
    set_connection_parameter_value mm_bridge_0.m0/ledg.s1 arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/ledg.s1 baseAddress {0x00010200}
    set_connection_parameter_value mm_bridge_0.m0/ledg.s1 defaultConnection {0}

    add_connection mm_bridge_0.m0 onchip_memory2_0.s2 avalon
    set_connection_parameter_value mm_bridge_0.m0/onchip_memory2_0.s2 arbitrationPriority {1}
    set_connection_parameter_value mm_bridge_0.m0/onchip_memory2_0.s2 baseAddress {0x0000}
    set_connection_parameter_value mm_bridge_0.m0/onchip_memory2_0.s2 defaultConnection {0}

    add_connection altpll_0.c0 mm_bridge_0.clk clock

    add_connection altpll_0.c0 hex_3.clk clock

    add_connection altpll_0.c0 hex_2.clk clock

    add_connection altpll_0.c0 hex_1.clk clock

    add_connection altpll_0.c0 hex_0.clk clock

    add_connection altpll_0.c0 ledr.clk clock

    add_connection altpll_0.c0 ledg.clk clock

    add_connection altpll_0.c0 jtag_uart_0.clk clock

    add_connection altpll_0.c0 onchip_memory2_0.clk1 clock

    add_connection altpll_0.c0 onchip_memory2_0.clk2 clock

    add_connection altpll_0.c0 riscv_0.clock clock

    add_connection altpll_0.c0 pmod_mic_0.clock clock

    add_connection altpll_0.c1 riscv_0.scratchpad_clk clock

    add_connection clk_0.clk altpll_0.inclk_interface clock

    add_connection clk_0.clk_reset altpll_0.inclk_interface_reset reset

    add_connection clk_0.clk_reset mm_bridge_0.reset reset

    add_connection clk_0.clk_reset hex_3.reset reset

    add_connection clk_0.clk_reset hex_2.reset reset

    add_connection clk_0.clk_reset hex_1.reset reset

    add_connection clk_0.clk_reset hex_0.reset reset

    add_connection clk_0.clk_reset ledr.reset reset

    add_connection clk_0.clk_reset ledg.reset reset

    add_connection clk_0.clk_reset riscv_0.reset reset

    add_connection clk_0.clk_reset jtag_uart_0.reset reset

    add_connection clk_0.clk_reset pmod_mic_0.reset reset

    add_connection clk_0.clk_reset onchip_memory2_0.reset1 reset

    add_connection clk_0.clk_reset onchip_memory2_0.reset2 reset

    # exported interfaces
    add_interface clk clock sink
    set_interface_property clk EXPORT_OF clk_0.clk_in
    add_interface from_host conduit end
    set_interface_property from_host EXPORT_OF riscv_0.from_host
    add_interface hex0 conduit end
    set_interface_property hex0 EXPORT_OF hex_0.external_connection
    add_interface hex1 conduit end
    set_interface_property hex1 EXPORT_OF hex_1.external_connection
    add_interface hex2 conduit end
    set_interface_property hex2 EXPORT_OF hex_2.external_connection
    add_interface hex3 conduit end
    set_interface_property hex3 EXPORT_OF hex_3.external_connection
    add_interface ledg conduit end
    set_interface_property ledg EXPORT_OF ledg.external_connection
    add_interface ledr conduit end
    set_interface_property ledr EXPORT_OF ledr.external_connection
    add_interface pll_areset conduit end
    set_interface_property pll_areset EXPORT_OF altpll_0.areset_conduit
    add_interface pmod_mic conduit end
    set_interface_property pmod_mic EXPORT_OF pmod_mic_0.pmod_pins
    add_interface program_counter conduit end
    set_interface_property program_counter EXPORT_OF riscv_0.program_counter
    add_interface reset reset sink
    set_interface_property reset EXPORT_OF clk_0.clk_in_reset
    add_interface riscv_0_to_host conduit end
    set_interface_property riscv_0_to_host EXPORT_OF riscv_0.to_host

    # interconnect requirements
    set_interconnect_requirement {$system} {qsys_mm.clockCrossingAdapter} {HANDSHAKE}
    set_interconnect_requirement {$system} {qsys_mm.maxAdditionalLatency} {1}
    set_interconnect_requirement {$system} {qsys_mm.insertDefaultSlave} {FALSE}
}
