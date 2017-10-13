# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  ipgui::add_page $IPINST -name "Page 0"

  ipgui::add_param $IPINST -name "REGISTER_SIZE"
  ipgui::add_param $IPINST -name "AVALON_ENABLE"
  ipgui::add_param $IPINST -name "WISHBONE_ENABLE"
  ipgui::add_param $IPINST -name "AXI_ENABLE"
  ipgui::add_param $IPINST -name "RESET_VECTOR"
  ipgui::add_param $IPINST -name "INTERRUPT_VECTOR"
  ipgui::add_param $IPINST -name "MULTIPLY_ENABLE"
  ipgui::add_param $IPINST -name "DIVIDE_ENABLE"
  ipgui::add_param $IPINST -name "SHIFTER_MAX_CYCLES"
  ipgui::add_param $IPINST -name "COUNTER_LENGTH"
  ipgui::add_param $IPINST -name "ENABLE_EXCEPTIONS"
  ipgui::add_param $IPINST -name "BRANCH_PREDICTORS"
  ipgui::add_param $IPINST -name "DATA_REQUEST_REGISTER"
  ipgui::add_param $IPINST -name "DATA_RETURN_REGISTER"
  ipgui::add_param $IPINST -name "PIPELINE_STAGES"
  ipgui::add_param $IPINST -name "LVE_ENABLE"
  ipgui::add_param $IPINST -name "ENABLE_EXT_INTERRUPTS"
  ipgui::add_param $IPINST -name "NUM_EXT_INTERRUPTS"
  ipgui::add_param $IPINST -name "SCRATCHPAD_ADDR_BITS"
  ipgui::add_param $IPINST -name "IUC_ADDR_BASE"
  ipgui::add_param $IPINST -name "IUC_ADDR_LAST"
  ipgui::add_param $IPINST -name "IAUX_ADDR_BASE"
  ipgui::add_param $IPINST -name "IAUX_ADDR_LAST"
  ipgui::add_param $IPINST -name "ICACHE_SIZE"
  ipgui::add_param $IPINST -name "ICACHE_LINE_SIZE"
  ipgui::add_param $IPINST -name "ICACHE_EXTERNAL_WIDTH"
  ipgui::add_param $IPINST -name "ICACHE_BURST_EN"
  ipgui::add_param $IPINST -name "POWER_OPTIMIZED"
  ipgui::add_param $IPINST -name "FAMILY"

}

proc update_PARAM_VALUE.AVALON_ENABLE { PARAM_VALUE.AVALON_ENABLE } {
	# Procedure called to update AVALON_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AVALON_ENABLE { PARAM_VALUE.AVALON_ENABLE } {
	# Procedure called to validate AVALON_ENABLE
	return true
}

proc update_PARAM_VALUE.AXI_ENABLE { PARAM_VALUE.AXI_ENABLE } {
	# Procedure called to update AXI_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_ENABLE { PARAM_VALUE.AXI_ENABLE } {
	# Procedure called to validate AXI_ENABLE
	return true
}

proc update_PARAM_VALUE.BRANCH_PREDICTORS { PARAM_VALUE.BRANCH_PREDICTORS } {
	# Procedure called to update BRANCH_PREDICTORS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRANCH_PREDICTORS { PARAM_VALUE.BRANCH_PREDICTORS } {
	# Procedure called to validate BRANCH_PREDICTORS
	return true
}

proc update_PARAM_VALUE.DATA_REQUEST_REGISTER { PARAM_VALUE.DATA_REQUEST_REGISTER } {
	# Procedure called to update DATA_REQUEST_REGISTER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_REQUEST_REGISTER { PARAM_VALUE.DATA_REQUEST_REGISTER } {
	# Procedure called to validate DATA_REQUEST_REGISTER
	return true
}

proc update_PARAM_VALUE.DATA_RETURN_REGISTER { PARAM_VALUE.DATA_RETURN_REGISTER } {
	# Procedure called to update DATA_RETURN_REGISTER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_RETURN_REGISTER { PARAM_VALUE.DATA_RETURN_REGISTER } {
	# Procedure called to validate DATA_RETURN_REGISTER
	return true
}

proc update_PARAM_VALUE.ICACHE_BURST_EN { PARAM_VALUE.ICACHE_BURST_EN } {
	# Procedure called to update ICACHE_BURST_EN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ICACHE_BURST_EN { PARAM_VALUE.ICACHE_BURST_EN } {
	# Procedure called to validate ICACHE_BURST_EN
	return true
}

proc update_PARAM_VALUE.ICACHE_SIZE { PARAM_VALUE.ICACHE_SIZE } {
	# Procedure called to update ICACHE_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ICACHE_SIZE { PARAM_VALUE.ICACHE_SIZE } {
	# Procedure called to validate ICACHE_SIZE
	return true
}

proc update_PARAM_VALUE.COUNTER_LENGTH { PARAM_VALUE.COUNTER_LENGTH } {
	# Procedure called to update COUNTER_LENGTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.COUNTER_LENGTH { PARAM_VALUE.COUNTER_LENGTH } {
	# Procedure called to validate COUNTER_LENGTH
	return true
}

proc update_PARAM_VALUE.DIVIDE_ENABLE { PARAM_VALUE.DIVIDE_ENABLE } {
	# Procedure called to update DIVIDE_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DIVIDE_ENABLE { PARAM_VALUE.DIVIDE_ENABLE } {
	# Procedure called to validate DIVIDE_ENABLE
	return true
}

proc update_PARAM_VALUE.ICACHE_EXTERNAL_WIDTH { PARAM_VALUE.ICACHE_EXTERNAL_WIDTH } {
	# Procedure called to update ICACHE_EXTERNAL_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ICACHE_EXTERNAL_WIDTH { PARAM_VALUE.ICACHE_EXTERNAL_WIDTH } {
	# Procedure called to validate ICACHE_EXTERNAL_WIDTH
	return true
}

proc update_PARAM_VALUE.ENABLE_EXCEPTIONS { PARAM_VALUE.ENABLE_EXCEPTIONS } {
	# Procedure called to update ENABLE_EXCEPTIONS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_EXCEPTIONS { PARAM_VALUE.ENABLE_EXCEPTIONS } {
	# Procedure called to validate ENABLE_EXCEPTIONS
	return true
}

proc update_PARAM_VALUE.ENABLE_EXT_INTERRUPTS { PARAM_VALUE.ENABLE_EXT_INTERRUPTS } {
	# Procedure called to update ENABLE_EXT_INTERRUPTS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_EXT_INTERRUPTS { PARAM_VALUE.ENABLE_EXT_INTERRUPTS } {
	# Procedure called to validate ENABLE_EXT_INTERRUPTS
	return true
}

proc update_PARAM_VALUE.FAMILY { PARAM_VALUE.FAMILY } {
	# Procedure called to update FAMILY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FAMILY { PARAM_VALUE.FAMILY } {
	# Procedure called to validate FAMILY
	return true
}

proc update_PARAM_VALUE.INTERRUPT_VECTOR { PARAM_VALUE.INTERRUPT_VECTOR } {
	# Procedure called to update INTERRUPT_VECTOR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INTERRUPT_VECTOR { PARAM_VALUE.INTERRUPT_VECTOR } {
	# Procedure called to validate INTERRUPT_VECTOR
	return true
}

proc update_PARAM_VALUE.ICACHE_LINE_SIZE { PARAM_VALUE.ICACHE_LINE_SIZE } {
	# Procedure called to update ICACHE_LINE_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ICACHE_LINE_SIZE { PARAM_VALUE.ICACHE_LINE_SIZE } {
	# Procedure called to validate ICACHE_LINE_SIZE
	return true
}

proc update_PARAM_VALUE.LVE_ENABLE { PARAM_VALUE.LVE_ENABLE } {
	# Procedure called to update LVE_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LVE_ENABLE { PARAM_VALUE.LVE_ENABLE } {
	# Procedure called to validate LVE_ENABLE
	return true
}

proc update_PARAM_VALUE.MULTIPLY_ENABLE { PARAM_VALUE.MULTIPLY_ENABLE } {
	# Procedure called to update MULTIPLY_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MULTIPLY_ENABLE { PARAM_VALUE.MULTIPLY_ENABLE } {
	# Procedure called to validate MULTIPLY_ENABLE
	return true
}

proc update_PARAM_VALUE.NUM_EXT_INTERRUPTS { PARAM_VALUE.NUM_EXT_INTERRUPTS } {
	# Procedure called to update NUM_EXT_INTERRUPTS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUM_EXT_INTERRUPTS { PARAM_VALUE.NUM_EXT_INTERRUPTS } {
	# Procedure called to validate NUM_EXT_INTERRUPTS
	return true
}

proc update_PARAM_VALUE.PIPELINE_STAGES { PARAM_VALUE.PIPELINE_STAGES } {
	# Procedure called to update PIPELINE_STAGES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PIPELINE_STAGES { PARAM_VALUE.PIPELINE_STAGES } {
	# Procedure called to validate PIPELINE_STAGES
	return true
}

proc update_PARAM_VALUE.POWER_OPTIMIZED { PARAM_VALUE.POWER_OPTIMIZED } {
	# Procedure called to update POWER_OPTIMIZED when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.POWER_OPTIMIZED { PARAM_VALUE.POWER_OPTIMIZED } {
	# Procedure called to validate POWER_OPTIMIZED
	return true
}

proc update_PARAM_VALUE.REGISTER_SIZE { PARAM_VALUE.REGISTER_SIZE } {
	# Procedure called to update REGISTER_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.REGISTER_SIZE { PARAM_VALUE.REGISTER_SIZE } {
	# Procedure called to validate REGISTER_SIZE
	return true
}

proc update_PARAM_VALUE.RESET_VECTOR { PARAM_VALUE.RESET_VECTOR } {
	# Procedure called to update RESET_VECTOR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RESET_VECTOR { PARAM_VALUE.RESET_VECTOR } {
	# Procedure called to validate RESET_VECTOR
	return true
}

proc update_PARAM_VALUE.SCRATCHPAD_ADDR_BITS { PARAM_VALUE.SCRATCHPAD_ADDR_BITS } {
	# Procedure called to update SCRATCHPAD_ADDR_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCRATCHPAD_ADDR_BITS { PARAM_VALUE.SCRATCHPAD_ADDR_BITS } {
	# Procedure called to validate SCRATCHPAD_ADDR_BITS
	return true
}

proc update_PARAM_VALUE.SHIFTER_MAX_CYCLES { PARAM_VALUE.SHIFTER_MAX_CYCLES } {
	# Procedure called to update SHIFTER_MAX_CYCLES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SHIFTER_MAX_CYCLES { PARAM_VALUE.SHIFTER_MAX_CYCLES } {
	# Procedure called to validate SHIFTER_MAX_CYCLES
	return true
}

proc update_PARAM_VALUE.IUC_ADDR_BASE { PARAM_VALUE.IUC_ADDR_BASE } {
	# Procedure called to update IUC_ADDR_BASE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IUC_ADDR_BASE { PARAM_VALUE.IUC_ADDR_BASE } {
	# Procedure called to validate IUC_ADDR_BASE
	return true
}

proc update_PARAM_VALUE.IUC_ADDR_LAST { PARAM_VALUE.IUC_ADDR_LAST } {
	# Procedure called to update IUC_ADDR_LAST when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IUC_ADDR_LAST { PARAM_VALUE.IUC_ADDR_LAST } {
	# Procedure called to validate IUC_ADDR_LAST
	return true
}

proc update_PARAM_VALUE.IAUX_ADDR_BASE { PARAM_VALUE.IAUX_ADDR_BASE } {
	# Procedure called to update IAUX_ADDR_BASE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IAUX_ADDR_BASE { PARAM_VALUE.IAUX_ADDR_BASE } {
	# Procedure called to validate IAUX_ADDR_BASE
	return true
}

proc update_PARAM_VALUE.IAUX_ADDR_LAST { PARAM_VALUE.IAUX_ADDR_LAST } {
	# Procedure called to update IAUX_ADDR_LAST when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IAUX_ADDR_LAST { PARAM_VALUE.IAUX_ADDR_LAST } {
	# Procedure called to validate IAUX_ADDR_LAST
	return true
}

proc update_PARAM_VALUE.WISHBONE_ENABLE { PARAM_VALUE.WISHBONE_ENABLE } {
	# Procedure called to update WISHBONE_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.WISHBONE_ENABLE { PARAM_VALUE.WISHBONE_ENABLE } {
	# Procedure called to validate WISHBONE_ENABLE
	return true
}


proc update_MODELPARAM_VALUE.REGISTER_SIZE { MODELPARAM_VALUE.REGISTER_SIZE PARAM_VALUE.REGISTER_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.REGISTER_SIZE}] ${MODELPARAM_VALUE.REGISTER_SIZE}
}

proc update_MODELPARAM_VALUE.AVALON_ENABLE { MODELPARAM_VALUE.AVALON_ENABLE PARAM_VALUE.AVALON_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AVALON_ENABLE}] ${MODELPARAM_VALUE.AVALON_ENABLE}
}

proc update_MODELPARAM_VALUE.WISHBONE_ENABLE { MODELPARAM_VALUE.WISHBONE_ENABLE PARAM_VALUE.WISHBONE_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.WISHBONE_ENABLE}] ${MODELPARAM_VALUE.WISHBONE_ENABLE}
}

proc update_MODELPARAM_VALUE.AXI_ENABLE { MODELPARAM_VALUE.AXI_ENABLE PARAM_VALUE.AXI_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_ENABLE}] ${MODELPARAM_VALUE.AXI_ENABLE}
}

proc update_MODELPARAM_VALUE.RESET_VECTOR { MODELPARAM_VALUE.RESET_VECTOR PARAM_VALUE.RESET_VECTOR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RESET_VECTOR}] ${MODELPARAM_VALUE.RESET_VECTOR}
}

proc update_MODELPARAM_VALUE.INTERRUPT_VECTOR { MODELPARAM_VALUE.INTERRUPT_VECTOR PARAM_VALUE.INTERRUPT_VECTOR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INTERRUPT_VECTOR}] ${MODELPARAM_VALUE.INTERRUPT_VECTOR}
}

proc update_MODELPARAM_VALUE.MULTIPLY_ENABLE { MODELPARAM_VALUE.MULTIPLY_ENABLE PARAM_VALUE.MULTIPLY_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MULTIPLY_ENABLE}] ${MODELPARAM_VALUE.MULTIPLY_ENABLE}
}

proc update_MODELPARAM_VALUE.DIVIDE_ENABLE { MODELPARAM_VALUE.DIVIDE_ENABLE PARAM_VALUE.DIVIDE_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DIVIDE_ENABLE}] ${MODELPARAM_VALUE.DIVIDE_ENABLE}
}

proc update_MODELPARAM_VALUE.SHIFTER_MAX_CYCLES { MODELPARAM_VALUE.SHIFTER_MAX_CYCLES PARAM_VALUE.SHIFTER_MAX_CYCLES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SHIFTER_MAX_CYCLES}] ${MODELPARAM_VALUE.SHIFTER_MAX_CYCLES}
}

proc update_MODELPARAM_VALUE.COUNTER_LENGTH { MODELPARAM_VALUE.COUNTER_LENGTH PARAM_VALUE.COUNTER_LENGTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.COUNTER_LENGTH}] ${MODELPARAM_VALUE.COUNTER_LENGTH}
}

proc update_MODELPARAM_VALUE.ENABLE_EXCEPTIONS { MODELPARAM_VALUE.ENABLE_EXCEPTIONS PARAM_VALUE.ENABLE_EXCEPTIONS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_EXCEPTIONS}] ${MODELPARAM_VALUE.ENABLE_EXCEPTIONS}
}

proc update_MODELPARAM_VALUE.BRANCH_PREDICTORS { MODELPARAM_VALUE.BRANCH_PREDICTORS PARAM_VALUE.BRANCH_PREDICTORS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRANCH_PREDICTORS}] ${MODELPARAM_VALUE.BRANCH_PREDICTORS}
}

proc update_MODELPARAM_VALUE.DATA_REQUEST_REGISTER { MODELPARAM_VALUE.DATA_REQUEST_REGISTER PARAM_VALUE.DATA_REQUEST_REGISTER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_REQUEST_REGISTER}] ${MODELPARAM_VALUE.DATA_REQUEST_REGISTER}
}

proc update_MODELPARAM_VALUE.DATA_RETURN_REGISTER { MODELPARAM_VALUE.DATA_RETURN_REGISTER PARAM_VALUE.DATA_RETURN_REGISTER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_RETURN_REGISTER}] ${MODELPARAM_VALUE.DATA_RETURN_REGISTER}
}

proc update_MODELPARAM_VALUE.PIPELINE_STAGES { MODELPARAM_VALUE.PIPELINE_STAGES PARAM_VALUE.PIPELINE_STAGES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PIPELINE_STAGES}] ${MODELPARAM_VALUE.PIPELINE_STAGES}
}

proc update_MODELPARAM_VALUE.LVE_ENABLE { MODELPARAM_VALUE.LVE_ENABLE PARAM_VALUE.LVE_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LVE_ENABLE}] ${MODELPARAM_VALUE.LVE_ENABLE}
}

proc update_MODELPARAM_VALUE.ENABLE_EXT_INTERRUPTS { MODELPARAM_VALUE.ENABLE_EXT_INTERRUPTS PARAM_VALUE.ENABLE_EXT_INTERRUPTS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_EXT_INTERRUPTS}] ${MODELPARAM_VALUE.ENABLE_EXT_INTERRUPTS}
}

proc update_MODELPARAM_VALUE.NUM_EXT_INTERRUPTS { MODELPARAM_VALUE.NUM_EXT_INTERRUPTS PARAM_VALUE.NUM_EXT_INTERRUPTS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUM_EXT_INTERRUPTS}] ${MODELPARAM_VALUE.NUM_EXT_INTERRUPTS}
}

proc update_MODELPARAM_VALUE.SCRATCHPAD_ADDR_BITS { MODELPARAM_VALUE.SCRATCHPAD_ADDR_BITS PARAM_VALUE.SCRATCHPAD_ADDR_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCRATCHPAD_ADDR_BITS}] ${MODELPARAM_VALUE.SCRATCHPAD_ADDR_BITS}
}

proc update_MODELPARAM_VALUE.IUC_ADDR_BASE { MODELPARAM_VALUE.IUC_ADDR_BASE PARAM_VALUE.IUC_ADDR_BASE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IUC_ADDR_BASE}] ${MODELPARAM_VALUE.IUC_ADDR_BASE}
}

proc update_MODELPARAM_VALUE.IUC_ADDR_LAST { MODELPARAM_VALUE.IUC_ADDR_LAST PARAM_VALUE.IUC_ADDR_LAST } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) lastd on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IUC_ADDR_LAST}] ${MODELPARAM_VALUE.IUC_ADDR_LAST}
}

proc update_MODELPARAM_VALUE.IAUX_ADDR_BASE { MODELPARAM_VALUE.IAUX_ADDR_BASE PARAM_VALUE.IAUX_ADDR_BASE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IAUX_ADDR_BASE}] ${MODELPARAM_VALUE.IAUX_ADDR_BASE}
}

proc update_MODELPARAM_VALUE.IAUX_ADDR_LAST { MODELPARAM_VALUE.IAUX_ADDR_LAST PARAM_VALUE.IAUX_ADDR_LAST } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) lastd on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IAUX_ADDR_LAST}] ${MODELPARAM_VALUE.IAUX_ADDR_LAST}
}

proc update_MODELPARAM_VALUE.ICACHE_SIZE { MODELPARAM_VALUE.ICACHE_SIZE PARAM_VALUE.ICACHE_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ICACHE_SIZE}] ${MODELPARAM_VALUE.ICACHE_SIZE}
}

proc update_MODELPARAM_VALUE.ICACHE_LINE_SIZE { MODELPARAM_VALUE.ICACHE_LINE_SIZE PARAM_VALUE.ICACHE_LINE_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ICACHE_LINE_SIZE}] ${MODELPARAM_VALUE.ICACHE_LINE_SIZE}
}

proc update_MODELPARAM_VALUE.ICACHE_EXTERNAL_WIDTH { MODELPARAM_VALUE.ICACHE_EXTERNAL_WIDTH PARAM_VALUE.ICACHE_EXTERNAL_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ICACHE_EXTERNAL_WIDTH}] ${MODELPARAM_VALUE.ICACHE_EXTERNAL_WIDTH}
}

proc update_MODELPARAM_VALUE.ICACHE_BURST_EN { MODELPARAM_VALUE.ICACHE_BURST_EN PARAM_VALUE.ICACHE_BURST_EN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ICACHE_BURST_EN}] ${MODELPARAM_VALUE.ICACHE_BURST_EN}
}

proc update_MODELPARAM_VALUE.POWER_OPTIMIZED { MODELPARAM_VALUE.POWER_OPTIMIZED PARAM_VALUE.POWER_OPTIMIZED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.POWER_OPTIMIZED}] ${MODELPARAM_VALUE.POWER_OPTIMIZED}
}

proc update_MODELPARAM_VALUE.FAMILY { MODELPARAM_VALUE.FAMILY PARAM_VALUE.FAMILY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FAMILY}] ${MODELPARAM_VALUE.FAMILY}
}

