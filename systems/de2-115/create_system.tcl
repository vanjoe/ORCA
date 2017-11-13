

# module properties



# default module properties








proc compose { } {
    # Instances and instance parameters
    # (disabled instances are intentionally culled)
    add_instance hex_0 altera_avalon_pio 15.1
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

    add_instance hex_1 altera_avalon_pio 15.1
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

    add_instance hex_2 altera_avalon_pio 15.1
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

    add_instance hex_3 altera_avalon_pio 15.1
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

    add_instance ledg altera_avalon_pio 15.1
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

    add_instance ledr altera_avalon_pio 15.1
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

    add_instance the_clk clock_source 15.1
    set_instance_parameter_value the_clk {clockFrequency} {50000000.0}
    set_instance_parameter_value the_clk {clockFrequencyKnown} {1}
    set_instance_parameter_value the_clk {resetSynchronousEdges} {NONE}

    add_instance the_jtag_uart altera_avalon_jtag_uart 15.1
    set_instance_parameter_value the_jtag_uart {allowMultipleConnections} {0}
    set_instance_parameter_value the_jtag_uart {hubInstanceID} {0}
    set_instance_parameter_value the_jtag_uart {readBufferDepth} {64}
    set_instance_parameter_value the_jtag_uart {readIRQThreshold} {8}
    set_instance_parameter_value the_jtag_uart {simInputCharacterStream} {}
    set_instance_parameter_value the_jtag_uart {simInteractiveOptions} {NO_INTERACTIVE_WINDOWS}
    set_instance_parameter_value the_jtag_uart {useRegistersForReadBuffer} {0}
    set_instance_parameter_value the_jtag_uart {useRegistersForWriteBuffer} {0}
    set_instance_parameter_value the_jtag_uart {useRelativePathForSimFile} {0}
    set_instance_parameter_value the_jtag_uart {writeBufferDepth} {64}
    set_instance_parameter_value the_jtag_uart {writeIRQThreshold} {8}

    add_instance the_master altera_jtag_avalon_master 15.1
    set_instance_parameter_value the_master {USE_PLI} {0}
    set_instance_parameter_value the_master {PLI_PORT} {50000}
    set_instance_parameter_value the_master {FAST_VER} {0}
    set_instance_parameter_value the_master {FIFO_DEPTHS} {2}

    add_instance the_memory_mapped_reset memory_mapped_reset 1.0
    set_instance_parameter_value the_memory_mapped_reset {ADDR_WIDTH} {2}
    set_instance_parameter_value the_memory_mapped_reset {REGISTER_SIZE} {32}

    add_instance the_mm_bridge altera_avalon_mm_bridge 15.1
    set_instance_parameter_value the_mm_bridge {DATA_WIDTH} {32}
    set_instance_parameter_value the_mm_bridge {SYMBOL_WIDTH} {8}
    set_instance_parameter_value the_mm_bridge {ADDRESS_WIDTH} {11}
    set_instance_parameter_value the_mm_bridge {USE_AUTO_ADDRESS_WIDTH} {1}
    set_instance_parameter_value the_mm_bridge {ADDRESS_UNITS} {SYMBOLS}
    set_instance_parameter_value the_mm_bridge {MAX_BURST_SIZE} {1}
    set_instance_parameter_value the_mm_bridge {MAX_PENDING_RESPONSES} {1}
    set_instance_parameter_value the_mm_bridge {LINEWRAPBURSTS} {0}
    set_instance_parameter_value the_mm_bridge {PIPELINE_COMMAND} {0}
    set_instance_parameter_value the_mm_bridge {PIPELINE_RESPONSE} {0}
    set_instance_parameter_value the_mm_bridge {USE_RESPONSE} {0}

    add_instance the_onchip_memory2 altera_avalon_onchip_memory2 15.1
    set_instance_parameter_value the_onchip_memory2 {allowInSystemMemoryContentEditor} {0}
    set_instance_parameter_value the_onchip_memory2 {blockType} {AUTO}
    set_instance_parameter_value the_onchip_memory2 {dataWidth} {32}
    set_instance_parameter_value the_onchip_memory2 {dualPort} {1}
    set_instance_parameter_value the_onchip_memory2 {initMemContent} {1}
    set_instance_parameter_value the_onchip_memory2 {initializationFileName} {test.hex}
    set_instance_parameter_value the_onchip_memory2 {instanceID} {NONE}
    set_instance_parameter_value the_onchip_memory2 {memorySize} {65536.0}
    set_instance_parameter_value the_onchip_memory2 {readDuringWriteMode} {DONT_CARE}
    set_instance_parameter_value the_onchip_memory2 {simAllowMRAMContentsFile} {0}
    set_instance_parameter_value the_onchip_memory2 {simMemInitOnlyFilename} {0}
    set_instance_parameter_value the_onchip_memory2 {singleClockOperation} {0}
    set_instance_parameter_value the_onchip_memory2 {slave1Latency} {1}
    set_instance_parameter_value the_onchip_memory2 {slave2Latency} {1}
    set_instance_parameter_value the_onchip_memory2 {useNonDefaultInitFile} {1}
    set_instance_parameter_value the_onchip_memory2 {copyInitFile} {0}
    set_instance_parameter_value the_onchip_memory2 {useShallowMemBlocks} {0}
    set_instance_parameter_value the_onchip_memory2 {writable} {1}
    set_instance_parameter_value the_onchip_memory2 {ecc_enabled} {0}
    set_instance_parameter_value the_onchip_memory2 {resetrequest_enabled} {1}

    add_instance the_reset_controller altera_reset_controller 15.1
    set_instance_parameter_value the_reset_controller {NUM_RESET_INPUTS} {2}
    set_instance_parameter_value the_reset_controller {OUTPUT_RESET_SYNC_EDGES} {deassert}
    set_instance_parameter_value the_reset_controller {SYNC_DEPTH} {2}
    set_instance_parameter_value the_reset_controller {RESET_REQUEST_PRESENT} {0}
    set_instance_parameter_value the_reset_controller {RESET_REQ_WAIT_TIME} {1}
    set_instance_parameter_value the_reset_controller {MIN_RST_ASSERTION_TIME} {3}
    set_instance_parameter_value the_reset_controller {RESET_REQ_EARLY_DSRT_TIME} {1}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN0} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN1} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN2} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN3} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN4} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN5} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN6} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN7} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN8} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN9} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN10} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN11} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN12} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN13} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN14} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_IN15} {0}
    set_instance_parameter_value the_reset_controller {USE_RESET_REQUEST_INPUT} {0}

    add_instance the_vectorblox_orca vectorblox_orca 1.0
    set_instance_parameter_value the_vectorblox_orca {REGISTER_SIZE} {32}
    set_instance_parameter_value the_vectorblox_orca {RESET_VECTOR} {0}
    set_instance_parameter_value the_vectorblox_orca {INTERRUPT_VECTOR} {512}
    set_instance_parameter_value the_vectorblox_orca {MULTIPLY_ENABLE} {1}
    set_instance_parameter_value the_vectorblox_orca {DIVIDE_ENABLE} {1}
    set_instance_parameter_value the_vectorblox_orca {SHIFTER_MAX_CYCLES} {1}
    set_instance_parameter_value the_vectorblox_orca {COUNTER_LENGTH} {64}
    set_instance_parameter_value the_vectorblox_orca {ENABLE_EXCEPTIONS} {1}
    set_instance_parameter_value the_vectorblox_orca {ENABLE_EXT_INTERRUPTS} {1}
    set_instance_parameter_value the_vectorblox_orca {NUM_EXT_INTERRUPTS} {1}
    set_instance_parameter_value the_vectorblox_orca {PIPELINE_STAGES} {5}
    set_instance_parameter_value the_vectorblox_orca {LVE_ENABLE} {0}
    set_instance_parameter_value the_vectorblox_orca {SCRATCHPAD_SIZE} {64}
    set_instance_parameter_value the_vectorblox_orca {IUC_ADDR_BASE} {0}
    set_instance_parameter_value the_vectorblox_orca {IUC_ADDR_LAST} {0}
    set_instance_parameter_value the_vectorblox_orca {IAUX_ADDR_BASE} {0}
    set_instance_parameter_value the_vectorblox_orca {IAUX_ADDR_LAST} {4294967295}
    set_instance_parameter_value the_vectorblox_orca {ICACHE_SIZE} {0}
    set_instance_parameter_value the_vectorblox_orca {ICACHE_LINE_SIZE} {32}
    set_instance_parameter_value the_vectorblox_orca {ICACHE_EXTERNAL_WIDTH} {32}
    set_instance_parameter_value the_vectorblox_orca {ICACHE_BURST_EN} {0}
    set_instance_parameter_value the_vectorblox_orca {DUC_ADDR_BASE} {0}
    set_instance_parameter_value the_vectorblox_orca {DUC_ADDR_LAST} {0}
    set_instance_parameter_value the_vectorblox_orca {DAUX_ADDR_BASE} {0}
    set_instance_parameter_value the_vectorblox_orca {DAUX_ADDR_LAST} {4294967295}
    set_instance_parameter_value the_vectorblox_orca {DCACHE_SIZE} {0}
    set_instance_parameter_value the_vectorblox_orca {DCACHE_LINE_SIZE} {32}
    set_instance_parameter_value the_vectorblox_orca {DCACHE_EXTERNAL_WIDTH} {32}
    set_instance_parameter_value the_vectorblox_orca {DCACHE_BURST_EN} {0}
    set_instance_parameter_value the_vectorblox_orca {POWER_OPTIMIZED} {0}
    set_instance_parameter_value the_vectorblox_orca {FAMILY} {ALTERA}

    # connections and connection parameters
    add_connection the_vectorblox_orca.data the_mm_bridge.s0 avalon
    set_connection_parameter_value the_vectorblox_orca.data/the_mm_bridge.s0 arbitrationPriority {1}
    set_connection_parameter_value the_vectorblox_orca.data/the_mm_bridge.s0 baseAddress {0x01000000}
    set_connection_parameter_value the_vectorblox_orca.data/the_mm_bridge.s0 defaultConnection {0}

    add_connection the_vectorblox_orca.data the_onchip_memory2.s2 avalon
    set_connection_parameter_value the_vectorblox_orca.data/the_onchip_memory2.s2 arbitrationPriority {1}
    set_connection_parameter_value the_vectorblox_orca.data/the_onchip_memory2.s2 baseAddress {0x0000}
    set_connection_parameter_value the_vectorblox_orca.data/the_onchip_memory2.s2 defaultConnection {0}

    add_connection the_vectorblox_orca.instruction the_onchip_memory2.s1 avalon
    set_connection_parameter_value the_vectorblox_orca.instruction/the_onchip_memory2.s1 arbitrationPriority {1}
    set_connection_parameter_value the_vectorblox_orca.instruction/the_onchip_memory2.s1 baseAddress {0x0000}
    set_connection_parameter_value the_vectorblox_orca.instruction/the_onchip_memory2.s1 defaultConnection {0}

    add_connection the_mm_bridge.m0 the_jtag_uart.avalon_jtag_slave avalon
    set_connection_parameter_value the_mm_bridge.m0/the_jtag_uart.avalon_jtag_slave arbitrationPriority {1}
    set_connection_parameter_value the_mm_bridge.m0/the_jtag_uart.avalon_jtag_slave baseAddress {0x0070}
    set_connection_parameter_value the_mm_bridge.m0/the_jtag_uart.avalon_jtag_slave defaultConnection {0}

    add_connection the_mm_bridge.m0 hex_1.s1 avalon
    set_connection_parameter_value the_mm_bridge.m0/hex_1.s1 arbitrationPriority {1}
    set_connection_parameter_value the_mm_bridge.m0/hex_1.s1 baseAddress {0x0040}
    set_connection_parameter_value the_mm_bridge.m0/hex_1.s1 defaultConnection {0}

    add_connection the_mm_bridge.m0 hex_0.s1 avalon
    set_connection_parameter_value the_mm_bridge.m0/hex_0.s1 arbitrationPriority {1}
    set_connection_parameter_value the_mm_bridge.m0/hex_0.s1 baseAddress {0x0030}
    set_connection_parameter_value the_mm_bridge.m0/hex_0.s1 defaultConnection {0}

    add_connection the_mm_bridge.m0 ledr.s1 avalon
    set_connection_parameter_value the_mm_bridge.m0/ledr.s1 arbitrationPriority {1}
    set_connection_parameter_value the_mm_bridge.m0/ledr.s1 baseAddress {0x0010}
    set_connection_parameter_value the_mm_bridge.m0/ledr.s1 defaultConnection {0}

    add_connection the_mm_bridge.m0 ledg.s1 avalon
    set_connection_parameter_value the_mm_bridge.m0/ledg.s1 arbitrationPriority {1}
    set_connection_parameter_value the_mm_bridge.m0/ledg.s1 baseAddress {0x0020}
    set_connection_parameter_value the_mm_bridge.m0/ledg.s1 defaultConnection {0}

    add_connection the_mm_bridge.m0 hex_2.s1 avalon
    set_connection_parameter_value the_mm_bridge.m0/hex_2.s1 arbitrationPriority {1}
    set_connection_parameter_value the_mm_bridge.m0/hex_2.s1 baseAddress {0x0050}
    set_connection_parameter_value the_mm_bridge.m0/hex_2.s1 defaultConnection {0}

    add_connection the_mm_bridge.m0 hex_3.s1 avalon
    set_connection_parameter_value the_mm_bridge.m0/hex_3.s1 arbitrationPriority {1}
    set_connection_parameter_value the_mm_bridge.m0/hex_3.s1 baseAddress {0x0060}
    set_connection_parameter_value the_mm_bridge.m0/hex_3.s1 defaultConnection {0}

    add_connection the_master.master the_memory_mapped_reset.avalon_slave avalon
    set_connection_parameter_value the_master.master/the_memory_mapped_reset.avalon_slave arbitrationPriority {1}
    set_connection_parameter_value the_master.master/the_memory_mapped_reset.avalon_slave baseAddress {0x10000000}
    set_connection_parameter_value the_master.master/the_memory_mapped_reset.avalon_slave defaultConnection {0}

    add_connection the_master.master the_onchip_memory2.s2 avalon
    set_connection_parameter_value the_master.master/the_onchip_memory2.s2 arbitrationPriority {1}
    set_connection_parameter_value the_master.master/the_onchip_memory2.s2 baseAddress {0x0000}
    set_connection_parameter_value the_master.master/the_onchip_memory2.s2 defaultConnection {0}

    add_connection the_clk.clk ledg.clk clock

    add_connection the_clk.clk ledr.clk clock

    add_connection the_clk.clk hex_0.clk clock

    add_connection the_clk.clk hex_1.clk clock

    add_connection the_clk.clk the_jtag_uart.clk clock

    add_connection the_clk.clk the_mm_bridge.clk clock

    add_connection the_clk.clk hex_2.clk clock

    add_connection the_clk.clk hex_3.clk clock

    add_connection the_clk.clk the_master.clk clock

    add_connection the_clk.clk the_reset_controller.clk clock

    add_connection the_clk.clk the_onchip_memory2.clk1 clock

    add_connection the_clk.clk the_onchip_memory2.clk2 clock

    add_connection the_clk.clk the_vectorblox_orca.clock clock

    add_connection the_clk.clk the_memory_mapped_reset.clock clock

    add_connection the_vectorblox_orca.global_interrupts the_jtag_uart.irq interrupt
    set_connection_parameter_value the_vectorblox_orca.global_interrupts/the_jtag_uart.irq irqNumber {0}

    add_connection the_clk.clk_reset the_master.clk_reset reset

    add_connection the_clk.clk_reset the_mm_bridge.reset reset

    add_connection the_clk.clk_reset the_memory_mapped_reset.reset reset

    add_connection the_clk.clk_reset the_onchip_memory2.reset1 reset

    add_connection the_clk.clk_reset the_onchip_memory2.reset2 reset

    add_connection the_clk.clk_reset the_reset_controller.reset_in0 reset

    add_connection the_reset_controller.reset_out the_jtag_uart.reset reset

    add_connection the_reset_controller.reset_out hex_3.reset reset

    add_connection the_reset_controller.reset_out hex_2.reset reset

    add_connection the_reset_controller.reset_out hex_1.reset reset

    add_connection the_reset_controller.reset_out hex_0.reset reset

    add_connection the_reset_controller.reset_out ledr.reset reset

    add_connection the_reset_controller.reset_out ledg.reset reset

    add_connection the_reset_controller.reset_out the_vectorblox_orca.reset reset

    add_connection the_memory_mapped_reset.reset_source the_reset_controller.reset_in1 reset

    # exported interfaces
    add_interface clk clock sink
    set_interface_property clk EXPORT_OF the_clk.clk_in
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
    add_interface reset reset sink
    set_interface_property reset EXPORT_OF the_clk.clk_in_reset

    # interconnect requirements
    set_interconnect_requirement {$system} {qsys_mm.clockCrossingAdapter} {HANDSHAKE}
    set_interconnect_requirement {$system} {qsys_mm.maxAdditionalLatency} {1}
    set_interconnect_requirement {$system} {qsys_mm.enableEccProtection} {FALSE}
    set_interconnect_requirement {$system} {qsys_mm.insertDefaultSlave} {FALSE}
}
