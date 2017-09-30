
################################################################
# This is a generated script based on design: design_1
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2017.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg484-1
   set_property BOARD_PART em.avnet.com:zed:part0:1.3 [current_project]
}


# CHANGE DESIGN NAME HERE
set design_name design_1

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: clock
proc create_hier_cell_clock { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_clock() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir O clk_2x_out
  create_bd_pin -dir I -type clk clk_in1
  create_bd_pin -dir O -type clk clk_out
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir O -from 0 -to 0 -type rst interconnect_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_reset

  # Create instance: clk_wiz, and set properties
  set clk_wiz [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:5.4 clk_wiz ]
  set_property -dict [ list \
CONFIG.CLKOUT1_JITTER {157.646} \
CONFIG.CLKOUT1_PHASE_ERROR {114.212} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {66.667} \
CONFIG.CLKOUT2_JITTER {136.421} \
CONFIG.CLKOUT2_PHASE_ERROR {114.212} \
CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {133.333} \
CONFIG.CLKOUT2_USED {true} \
CONFIG.MMCM_CLKFBOUT_MULT_F {8.000} \
CONFIG.MMCM_CLKIN1_PERIOD {10.000} \
CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.000} \
CONFIG.MMCM_CLKOUT1_DIVIDE {6} \
CONFIG.MMCM_DIVCLK_DIVIDE {1} \
CONFIG.NUM_OUT_CLKS {2} \
CONFIG.RESET_PORT {resetn} \
CONFIG.RESET_TYPE {ACTIVE_LOW} \
 ] $clk_wiz

  # Create instance: rst_clk_wiz_100M, and set properties
  set rst_clk_wiz_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_100M ]

  # Create port connections
  connect_bd_net -net clk_in1 [get_bd_pins clk_in1] [get_bd_pins clk_wiz/clk_in1]
  connect_bd_net -net clk_wiz_clk_out1 [get_bd_pins clk_out] [get_bd_pins clk_wiz/clk_out1] [get_bd_pins rst_clk_wiz_100M/slowest_sync_clk]
  connect_bd_net -net clk_wiz_clk_out2 [get_bd_pins clk_2x_out] [get_bd_pins clk_wiz/clk_out2]
  connect_bd_net -net clk_wiz_locked [get_bd_pins clk_wiz/locked] [get_bd_pins rst_clk_wiz_100M/dcm_locked]
  connect_bd_net -net ext_reset_in [get_bd_pins ext_reset_in] [get_bd_pins clk_wiz/resetn] [get_bd_pins rst_clk_wiz_100M/ext_reset_in]
  connect_bd_net -net interconnect_aresetn [get_bd_pins interconnect_aresetn] [get_bd_pins rst_clk_wiz_100M/interconnect_aresetn]
  connect_bd_net -net peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins rst_clk_wiz_100M/peripheral_aresetn]
  connect_bd_net -net peripheral_reset [get_bd_pins peripheral_reset] [get_bd_pins rst_clk_wiz_100M/peripheral_reset]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]
  set leds_8bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 leds_8bits ]

  # Create ports

  # Create instance: axi_bram_ctrl_onchip_A4, and set properties
  set axi_bram_ctrl_onchip_A4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_onchip_A4 ]
  set_property -dict [ list \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_onchip_A4

  # Create instance: axi_bram_ctrl_onchip_A4L, and set properties
  set axi_bram_ctrl_onchip_A4L [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.0 axi_bram_ctrl_onchip_A4L ]
  set_property -dict [ list \
CONFIG.ECC_TYPE {0} \
CONFIG.PROTOCOL {AXI4LITE} \
CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_onchip_A4L

  # Create instance: axi_crossbar_data_uncacheable, and set properties
  set axi_crossbar_data_uncacheable [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_data_uncacheable ]
  set_property -dict [ list \
CONFIG.DATA_WIDTH {32} \
CONFIG.NUM_MI {5} \
CONFIG.R_REGISTER {1} \
 ] $axi_crossbar_data_uncacheable

  # Create instance: axi_gpio_leds, and set properties
  set axi_gpio_leds [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_leds ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS_2 {1} \
CONFIG.C_DOUT_DEFAULT_2 {0x00000001} \
CONFIG.C_GPIO2_WIDTH {1} \
CONFIG.C_IS_DUAL {1} \
CONFIG.GPIO_BOARD_INTERFACE {leds_8bits} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_gpio_leds

  # Create instance: axi_interconnect_A4L_to_A4_PS7_GP0, and set properties
  set axi_interconnect_A4L_to_A4_PS7_GP0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_A4L_to_A4_PS7_GP0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {1} \
 ] $axi_interconnect_A4L_to_A4_PS7_GP0

  # Create instance: axi_interconnect_A4L_to_A4_PS7_HP1, and set properties
  set axi_interconnect_A4L_to_A4_PS7_HP1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_A4L_to_A4_PS7_HP1 ]
  set_property -dict [ list \
CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {1} \
 ] $axi_interconnect_A4L_to_A4_PS7_HP1

  # Create instance: axi_interconnect_instruction_cached, and set properties
  set axi_interconnect_instruction_cached [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_instruction_cached ]

  # Create instance: blk_mem_gen_onchip, and set properties
  set blk_mem_gen_onchip [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 blk_mem_gen_onchip ]
  set_property -dict [ list \
CONFIG.Assume_Synchronous_Clk {false} \
CONFIG.Enable_B {Use_ENB_Pin} \
CONFIG.Memory_Type {True_Dual_Port_RAM} \
CONFIG.Operating_Mode_A {READ_FIRST} \
CONFIG.Operating_Mode_B {READ_FIRST} \
CONFIG.Port_B_Clock {100} \
CONFIG.Port_B_Enable_Rate {100} \
CONFIG.Port_B_Write_Rate {50} \
CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen_onchip

  # Create instance: clock
  create_hier_cell_clock [current_bd_instance .] clock

  # Create instance: edge_extender, and set properties
  set edge_extender [ create_bd_cell -type ip -vlnv user.org:user:edge_extender:1.0 edge_extender ]

  # Create instance: fit_timer, and set properties
  set fit_timer [ create_bd_cell -type ip -vlnv xilinx.com:ip:fit_timer:2.0 fit_timer ]
  set_property -dict [ list \
CONFIG.C_NO_CLOCKS {50000000} \
 ] $fit_timer

  # Create instance: idram, and set properties
  set idram [ create_bd_cell -type ip -vlnv user.org:user:idram:1.0 idram ]
  set_property -dict [ list \
CONFIG.SIZE {131072} \
 ] $idram

  # Create instance: orca, and set properties
  set orca [ create_bd_cell -type ip -vlnv user.org:user:orca:1.0 orca ]
  set_property -dict [ list \
CONFIG.AXI_ENABLE {1} \
CONFIG.COUNTER_LENGTH {32} \
CONFIG.DIVIDE_ENABLE {1} \
CONFIG.ENABLE_EXT_INTERRUPTS {1} \
CONFIG.FAMILY {XILINX} \
CONFIG.ICACHE_LINE_SIZE {16} \
CONFIG.ICACHE_SIZE {8192} \
CONFIG.INTERRUPT_VECTOR {0xC0000200} \
CONFIG.IUC_ADDR_BASE {0x80000000} \
CONFIG.IUC_ADDR_LAST {0xFFFFFFFF} \
CONFIG.MULTIPLY_ENABLE {1} \
CONFIG.RESET_VECTOR {0xC0000000} \
 ] $orca

  # Create instance: processing_system7, and set properties
  set processing_system7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7 ]
  set_property -dict [ list \
CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {125.000000} \
CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {200.000000} \
CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {50.000000} \
CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {50.000000} \
CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {666.666667} \
CONFIG.PCW_CLK0_FREQ {100000000} \
CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} \
CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} \
CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {8} \
CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_ENET_RESET_ENABLE {1} \
CONFIG.PCW_ENET_RESET_SELECT {Share reset pin} \
CONFIG.PCW_EN_EMIO_TTC0 {1} \
CONFIG.PCW_EN_ENET0 {1} \
CONFIG.PCW_EN_GPIO {1} \
CONFIG.PCW_EN_QSPI {1} \
CONFIG.PCW_EN_SDIO0 {1} \
CONFIG.PCW_EN_TTC0 {1} \
CONFIG.PCW_EN_UART1 {1} \
CONFIG.PCW_EN_USB0 {1} \
CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {5} \
CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {2} \
CONFIG.PCW_FCLK_CLK0_BUF {TRUE} \
CONFIG.PCW_FCLK_CLK1_BUF {FALSE} \
CONFIG.PCW_FCLK_CLK2_BUF {FALSE} \
CONFIG.PCW_FCLK_CLK3_BUF {FALSE} \
CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {150.000000} \
CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_FTM_CTI_IN0 {<Select>} \
CONFIG.PCW_FTM_CTI_IN1 {<Select>} \
CONFIG.PCW_FTM_CTI_IN2 {<Select>} \
CONFIG.PCW_FTM_CTI_IN3 {<Select>} \
CONFIG.PCW_FTM_CTI_OUT0 {<Select>} \
CONFIG.PCW_FTM_CTI_OUT1 {<Select>} \
CONFIG.PCW_FTM_CTI_OUT2 {<Select>} \
CONFIG.PCW_FTM_CTI_OUT3 {<Select>} \
CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
CONFIG.PCW_GPIO_MIO_GPIO_IO {MIO} \
CONFIG.PCW_I2C_RESET_ENABLE {1} \
CONFIG.PCW_IOPLL_CTRL_FBDIV {30} \
CONFIG.PCW_IO_IO_PLL_FREQMHZ {1000.000} \
CONFIG.PCW_MIO_0_DIRECTION {inout} \
CONFIG.PCW_MIO_0_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_0_PULLUP {disabled} \
CONFIG.PCW_MIO_0_SLEW {slow} \
CONFIG.PCW_MIO_10_DIRECTION {inout} \
CONFIG.PCW_MIO_10_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_10_PULLUP {disabled} \
CONFIG.PCW_MIO_10_SLEW {slow} \
CONFIG.PCW_MIO_11_DIRECTION {inout} \
CONFIG.PCW_MIO_11_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_11_PULLUP {disabled} \
CONFIG.PCW_MIO_11_SLEW {slow} \
CONFIG.PCW_MIO_12_DIRECTION {inout} \
CONFIG.PCW_MIO_12_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_12_PULLUP {disabled} \
CONFIG.PCW_MIO_12_SLEW {slow} \
CONFIG.PCW_MIO_13_DIRECTION {inout} \
CONFIG.PCW_MIO_13_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_13_PULLUP {disabled} \
CONFIG.PCW_MIO_13_SLEW {slow} \
CONFIG.PCW_MIO_14_DIRECTION {inout} \
CONFIG.PCW_MIO_14_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_14_PULLUP {disabled} \
CONFIG.PCW_MIO_14_SLEW {slow} \
CONFIG.PCW_MIO_15_DIRECTION {inout} \
CONFIG.PCW_MIO_15_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_15_PULLUP {disabled} \
CONFIG.PCW_MIO_15_SLEW {slow} \
CONFIG.PCW_MIO_16_DIRECTION {out} \
CONFIG.PCW_MIO_16_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_16_PULLUP {disabled} \
CONFIG.PCW_MIO_16_SLEW {fast} \
CONFIG.PCW_MIO_17_DIRECTION {out} \
CONFIG.PCW_MIO_17_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_17_PULLUP {disabled} \
CONFIG.PCW_MIO_17_SLEW {fast} \
CONFIG.PCW_MIO_18_DIRECTION {out} \
CONFIG.PCW_MIO_18_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_18_PULLUP {disabled} \
CONFIG.PCW_MIO_18_SLEW {fast} \
CONFIG.PCW_MIO_19_DIRECTION {out} \
CONFIG.PCW_MIO_19_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_19_PULLUP {disabled} \
CONFIG.PCW_MIO_19_SLEW {fast} \
CONFIG.PCW_MIO_1_DIRECTION {out} \
CONFIG.PCW_MIO_1_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_1_PULLUP {disabled} \
CONFIG.PCW_MIO_1_SLEW {fast} \
CONFIG.PCW_MIO_20_DIRECTION {out} \
CONFIG.PCW_MIO_20_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_20_PULLUP {disabled} \
CONFIG.PCW_MIO_20_SLEW {fast} \
CONFIG.PCW_MIO_21_DIRECTION {out} \
CONFIG.PCW_MIO_21_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_21_PULLUP {disabled} \
CONFIG.PCW_MIO_21_SLEW {fast} \
CONFIG.PCW_MIO_22_DIRECTION {in} \
CONFIG.PCW_MIO_22_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_22_PULLUP {disabled} \
CONFIG.PCW_MIO_22_SLEW {fast} \
CONFIG.PCW_MIO_23_DIRECTION {in} \
CONFIG.PCW_MIO_23_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_23_PULLUP {disabled} \
CONFIG.PCW_MIO_23_SLEW {fast} \
CONFIG.PCW_MIO_24_DIRECTION {in} \
CONFIG.PCW_MIO_24_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_24_PULLUP {disabled} \
CONFIG.PCW_MIO_24_SLEW {fast} \
CONFIG.PCW_MIO_25_DIRECTION {in} \
CONFIG.PCW_MIO_25_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_25_PULLUP {disabled} \
CONFIG.PCW_MIO_25_SLEW {fast} \
CONFIG.PCW_MIO_26_DIRECTION {in} \
CONFIG.PCW_MIO_26_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_26_PULLUP {disabled} \
CONFIG.PCW_MIO_26_SLEW {fast} \
CONFIG.PCW_MIO_27_DIRECTION {in} \
CONFIG.PCW_MIO_27_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_27_PULLUP {disabled} \
CONFIG.PCW_MIO_27_SLEW {fast} \
CONFIG.PCW_MIO_28_DIRECTION {inout} \
CONFIG.PCW_MIO_28_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_28_PULLUP {disabled} \
CONFIG.PCW_MIO_28_SLEW {fast} \
CONFIG.PCW_MIO_29_DIRECTION {in} \
CONFIG.PCW_MIO_29_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_29_PULLUP {disabled} \
CONFIG.PCW_MIO_29_SLEW {fast} \
CONFIG.PCW_MIO_2_DIRECTION {inout} \
CONFIG.PCW_MIO_2_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_2_PULLUP {disabled} \
CONFIG.PCW_MIO_2_SLEW {fast} \
CONFIG.PCW_MIO_30_DIRECTION {out} \
CONFIG.PCW_MIO_30_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_30_PULLUP {disabled} \
CONFIG.PCW_MIO_30_SLEW {fast} \
CONFIG.PCW_MIO_31_DIRECTION {in} \
CONFIG.PCW_MIO_31_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_31_PULLUP {disabled} \
CONFIG.PCW_MIO_31_SLEW {fast} \
CONFIG.PCW_MIO_32_DIRECTION {inout} \
CONFIG.PCW_MIO_32_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_32_PULLUP {disabled} \
CONFIG.PCW_MIO_32_SLEW {fast} \
CONFIG.PCW_MIO_33_DIRECTION {inout} \
CONFIG.PCW_MIO_33_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_33_PULLUP {disabled} \
CONFIG.PCW_MIO_33_SLEW {fast} \
CONFIG.PCW_MIO_34_DIRECTION {inout} \
CONFIG.PCW_MIO_34_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_34_PULLUP {disabled} \
CONFIG.PCW_MIO_34_SLEW {fast} \
CONFIG.PCW_MIO_35_DIRECTION {inout} \
CONFIG.PCW_MIO_35_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_35_PULLUP {disabled} \
CONFIG.PCW_MIO_35_SLEW {fast} \
CONFIG.PCW_MIO_36_DIRECTION {in} \
CONFIG.PCW_MIO_36_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_36_PULLUP {disabled} \
CONFIG.PCW_MIO_36_SLEW {fast} \
CONFIG.PCW_MIO_37_DIRECTION {inout} \
CONFIG.PCW_MIO_37_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_37_PULLUP {disabled} \
CONFIG.PCW_MIO_37_SLEW {fast} \
CONFIG.PCW_MIO_38_DIRECTION {inout} \
CONFIG.PCW_MIO_38_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_38_PULLUP {disabled} \
CONFIG.PCW_MIO_38_SLEW {fast} \
CONFIG.PCW_MIO_39_DIRECTION {inout} \
CONFIG.PCW_MIO_39_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_39_PULLUP {disabled} \
CONFIG.PCW_MIO_39_SLEW {fast} \
CONFIG.PCW_MIO_3_DIRECTION {inout} \
CONFIG.PCW_MIO_3_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_3_PULLUP {disabled} \
CONFIG.PCW_MIO_3_SLEW {fast} \
CONFIG.PCW_MIO_40_DIRECTION {inout} \
CONFIG.PCW_MIO_40_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_40_PULLUP {disabled} \
CONFIG.PCW_MIO_40_SLEW {fast} \
CONFIG.PCW_MIO_41_DIRECTION {inout} \
CONFIG.PCW_MIO_41_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_41_PULLUP {disabled} \
CONFIG.PCW_MIO_41_SLEW {fast} \
CONFIG.PCW_MIO_42_DIRECTION {inout} \
CONFIG.PCW_MIO_42_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_42_PULLUP {disabled} \
CONFIG.PCW_MIO_42_SLEW {fast} \
CONFIG.PCW_MIO_43_DIRECTION {inout} \
CONFIG.PCW_MIO_43_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_43_PULLUP {disabled} \
CONFIG.PCW_MIO_43_SLEW {fast} \
CONFIG.PCW_MIO_44_DIRECTION {inout} \
CONFIG.PCW_MIO_44_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_44_PULLUP {disabled} \
CONFIG.PCW_MIO_44_SLEW {fast} \
CONFIG.PCW_MIO_45_DIRECTION {inout} \
CONFIG.PCW_MIO_45_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_45_PULLUP {disabled} \
CONFIG.PCW_MIO_45_SLEW {fast} \
CONFIG.PCW_MIO_46_DIRECTION {in} \
CONFIG.PCW_MIO_46_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_46_PULLUP {disabled} \
CONFIG.PCW_MIO_46_SLEW {slow} \
CONFIG.PCW_MIO_47_DIRECTION {in} \
CONFIG.PCW_MIO_47_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_47_PULLUP {disabled} \
CONFIG.PCW_MIO_47_SLEW {slow} \
CONFIG.PCW_MIO_48_DIRECTION {out} \
CONFIG.PCW_MIO_48_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_48_PULLUP {disabled} \
CONFIG.PCW_MIO_48_SLEW {slow} \
CONFIG.PCW_MIO_49_DIRECTION {in} \
CONFIG.PCW_MIO_49_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_49_PULLUP {disabled} \
CONFIG.PCW_MIO_49_SLEW {slow} \
CONFIG.PCW_MIO_4_DIRECTION {inout} \
CONFIG.PCW_MIO_4_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_4_PULLUP {disabled} \
CONFIG.PCW_MIO_4_SLEW {fast} \
CONFIG.PCW_MIO_50_DIRECTION {inout} \
CONFIG.PCW_MIO_50_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_50_PULLUP {disabled} \
CONFIG.PCW_MIO_50_SLEW {slow} \
CONFIG.PCW_MIO_51_DIRECTION {inout} \
CONFIG.PCW_MIO_51_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_51_PULLUP {disabled} \
CONFIG.PCW_MIO_51_SLEW {slow} \
CONFIG.PCW_MIO_52_DIRECTION {out} \
CONFIG.PCW_MIO_52_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_52_PULLUP {disabled} \
CONFIG.PCW_MIO_52_SLEW {slow} \
CONFIG.PCW_MIO_53_DIRECTION {inout} \
CONFIG.PCW_MIO_53_IOTYPE {LVCMOS 1.8V} \
CONFIG.PCW_MIO_53_PULLUP {disabled} \
CONFIG.PCW_MIO_53_SLEW {slow} \
CONFIG.PCW_MIO_5_DIRECTION {inout} \
CONFIG.PCW_MIO_5_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_5_PULLUP {disabled} \
CONFIG.PCW_MIO_5_SLEW {fast} \
CONFIG.PCW_MIO_6_DIRECTION {out} \
CONFIG.PCW_MIO_6_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_6_PULLUP {disabled} \
CONFIG.PCW_MIO_6_SLEW {fast} \
CONFIG.PCW_MIO_7_DIRECTION {out} \
CONFIG.PCW_MIO_7_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_7_PULLUP {disabled} \
CONFIG.PCW_MIO_7_SLEW {slow} \
CONFIG.PCW_MIO_8_DIRECTION {out} \
CONFIG.PCW_MIO_8_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_8_PULLUP {disabled} \
CONFIG.PCW_MIO_8_SLEW {fast} \
CONFIG.PCW_MIO_9_DIRECTION {inout} \
CONFIG.PCW_MIO_9_IOTYPE {LVCMOS 3.3V} \
CONFIG.PCW_MIO_9_PULLUP {disabled} \
CONFIG.PCW_MIO_9_SLEW {slow} \
CONFIG.PCW_MIO_TREE_PERIPHERALS {GPIO#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#GPIO#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#Enet 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#UART 1#UART 1#GPIO#GPIO#Enet 0#Enet 0} \
CONFIG.PCW_MIO_TREE_SIGNALS {gpio[0]#qspi0_ss_b#qspi0_io[0]#qspi0_io[1]#qspi0_io[2]#qspi0_io[3]#qspi0_sclk#gpio[7]#gpio[8]#gpio[9]#gpio[10]#gpio[11]#gpio[12]#gpio[13]#gpio[14]#gpio[15]#tx_clk#txd[0]#txd[1]#txd[2]#txd[3]#tx_ctl#rx_clk#rxd[0]#rxd[1]#rxd[2]#rxd[3]#rx_ctl#data[4]#dir#stp#nxt#data[0]#data[1]#data[2]#data[3]#clk#data[5]#data[6]#data[7]#clk#cmd#data[0]#data[1]#data[2]#data[3]#wp#cd#tx#rx#gpio[50]#gpio[51]#mdc#mdio} \
CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {5} \
CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {5} \
CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} \
CONFIG.PCW_QSPI_QSPI_IO {MIO 1 .. 6} \
CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
CONFIG.PCW_SD0_GRP_CD_IO {MIO 47} \
CONFIG.PCW_SD0_GRP_WP_ENABLE {1} \
CONFIG.PCW_SD0_GRP_WP_IO {MIO 46} \
CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {20} \
CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_SDIO_PERIPHERAL_VALID {1} \
CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {32} \
CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_TTC0_TTC0_IO {EMIO} \
CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {20} \
CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_UART_PERIPHERAL_VALID {1} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.063} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.062} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.065} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.083} \
CONFIG.PCW_UIPARAM_DDR_DEVICE_CAPACITY {2048 MBits} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {-0.007} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {-0.010} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {-0.006} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {-0.048} \
CONFIG.PCW_UIPARAM_DDR_DRAM_WIDTH {16 Bits} \
CONFIG.PCW_UIPARAM_DDR_FREQ_MHZ {533.333313} \
CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J128M16 HA-15E} \
CONFIG.PCW_UIPARAM_DDR_T_FAW {45.0} \
CONFIG.PCW_UIPARAM_DDR_T_RAS_MIN {36.0} \
CONFIG.PCW_UIPARAM_DDR_T_RC {49.5} \
CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {1} \
CONFIG.PCW_USB0_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_USB0_USB0_IO {MIO 28 .. 39} \
CONFIG.PCW_USB_RESET_ENABLE {1} \
CONFIG.PCW_USB_RESET_SELECT {Share reset pin} \
CONFIG.PCW_USE_M_AXI_GP0 {0} \
CONFIG.PCW_USE_S_AXI_GP0 {1} \
CONFIG.PCW_USE_S_AXI_HP0 {1} \
CONFIG.PCW_USE_S_AXI_HP1 {1} \
CONFIG.preset {ZedBoard} \
 ] $processing_system7

  # Create instance: ps7_uart_monitor, and set properties
  set ps7_uart_monitor [ create_bd_cell -type ip -vlnv vectorblox.com:debug:ps7_uart_monitor:1.0 ps7_uart_monitor ]

  # Create instance: system_ila_orca_masters, and set properties
  set system_ila_orca_masters [ create_bd_cell -type ip -vlnv xilinx.com:ip:system_ila:1.0 system_ila_orca_masters ]
  set_property -dict [ list \
CONFIG.C_BRAM_CNT {3.5} \
CONFIG.C_DATA_DEPTH {1024} \
CONFIG.C_INPUT_PIPE_STAGES {1} \
CONFIG.C_NUM_MONITOR_SLOTS {3} \
CONFIG.C_SLOT {0} \
CONFIG.C_SLOT_0_APC_EN {1} \
CONFIG.C_SLOT_0_AXI_AW_SEL {0} \
CONFIG.C_SLOT_0_AXI_AW_SEL_DATA {0} \
CONFIG.C_SLOT_0_AXI_AW_SEL_TRIG {0} \
CONFIG.C_SLOT_0_AXI_B_SEL {0} \
CONFIG.C_SLOT_0_AXI_B_SEL_DATA {0} \
CONFIG.C_SLOT_0_AXI_B_SEL_TRIG {0} \
CONFIG.C_SLOT_0_AXI_W_SEL {0} \
CONFIG.C_SLOT_0_AXI_W_SEL_DATA {0} \
CONFIG.C_SLOT_0_AXI_W_SEL_TRIG {0} \
CONFIG.C_SLOT_1_APC_EN {1} \
CONFIG.C_SLOT_1_AXI_AW_SEL {0} \
CONFIG.C_SLOT_1_AXI_AW_SEL_DATA {0} \
CONFIG.C_SLOT_1_AXI_AW_SEL_TRIG {0} \
CONFIG.C_SLOT_1_AXI_B_SEL {0} \
CONFIG.C_SLOT_1_AXI_B_SEL_DATA {0} \
CONFIG.C_SLOT_1_AXI_B_SEL_TRIG {0} \
CONFIG.C_SLOT_1_AXI_W_SEL {0} \
CONFIG.C_SLOT_1_AXI_W_SEL_DATA {0} \
CONFIG.C_SLOT_1_AXI_W_SEL_TRIG {0} \
CONFIG.C_SLOT_1_MAX_RD_BURSTS {4} \
CONFIG.C_SLOT_2_APC_EN {1} \
 ] $system_ila_orca_masters

  # Create instance: xlconstant_bypass_ps7_uart, and set properties
  set xlconstant_bypass_ps7_uart [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_bypass_ps7_uart ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
 ] $xlconstant_bypass_ps7_uart

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_interconnect_A4L_to_A4_PS7_GP0/S00_AXI] [get_bd_intf_pins ps7_uart_monitor/M_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_onchip_A4L/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_onchip/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_onchip_b_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_onchip_A4/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_onchip/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_crossbar_data_uncacheable_M00_AXI [get_bd_intf_pins axi_crossbar_data_uncacheable/M00_AXI] [get_bd_intf_pins idram/data]
  connect_bd_intf_net -intf_net axi_crossbar_data_uncacheable_M01_AXI [get_bd_intf_pins axi_crossbar_data_uncacheable/M01_AXI] [get_bd_intf_pins ps7_uart_monitor/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_data_uncacheable_M02_AXI [get_bd_intf_pins axi_crossbar_data_uncacheable/M02_AXI] [get_bd_intf_pins axi_gpio_leds/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_data_uncacheable_M03_AXI [get_bd_intf_pins axi_bram_ctrl_onchip_A4L/S_AXI] [get_bd_intf_pins axi_crossbar_data_uncacheable/M03_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_data_uncacheable_M04_AXI [get_bd_intf_pins axi_crossbar_data_uncacheable/M04_AXI] [get_bd_intf_pins axi_interconnect_A4L_to_A4_PS7_HP1/S00_AXI]
  connect_bd_intf_net -intf_net axi_gpio_leds_GPIO [get_bd_intf_ports leds_8bits] [get_bd_intf_pins axi_gpio_leds/GPIO]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_interconnect_instruction_cached/M00_AXI] [get_bd_intf_pins processing_system7/S_AXI_HP0]
  connect_bd_intf_net -intf_net axi_interconnect_A4L_to_A4_M00_AXI [get_bd_intf_pins axi_interconnect_A4L_to_A4_PS7_GP0/M00_AXI] [get_bd_intf_pins processing_system7/S_AXI_GP0]
  connect_bd_intf_net -intf_net axi_interconnect_A4L_to_A5_M00_AXI [get_bd_intf_pins axi_interconnect_A4L_to_A4_PS7_HP1/M00_AXI] [get_bd_intf_pins processing_system7/S_AXI_HP1]
  connect_bd_intf_net -intf_net axi_interconnect_instruction_cached_M01_AXI [get_bd_intf_pins axi_bram_ctrl_onchip_A4/S_AXI] [get_bd_intf_pins axi_interconnect_instruction_cached/M01_AXI]
  connect_bd_intf_net -intf_net orca_DUC [get_bd_intf_pins axi_crossbar_data_uncacheable/S00_AXI] [get_bd_intf_pins orca/DUC]
connect_bd_intf_net -intf_net [get_bd_intf_nets orca_DUC] [get_bd_intf_pins orca/DUC] [get_bd_intf_pins system_ila_orca_masters/SLOT_2_AXI]
  connect_bd_intf_net -intf_net orca_IC [get_bd_intf_pins axi_interconnect_instruction_cached/S00_AXI] [get_bd_intf_pins orca/IC]
connect_bd_intf_net -intf_net [get_bd_intf_nets orca_IC] [get_bd_intf_pins orca/IC] [get_bd_intf_pins system_ila_orca_masters/SLOT_1_AXI]
  connect_bd_intf_net -intf_net orca_IUC [get_bd_intf_pins idram/instr] [get_bd_intf_pins orca/IUC]
connect_bd_intf_net -intf_net [get_bd_intf_nets orca_IUC] [get_bd_intf_pins orca/IUC] [get_bd_intf_pins system_ila_orca_masters/SLOT_0_AXI]
  connect_bd_intf_net -intf_net processing_system7_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7/DDR]
  connect_bd_intf_net -intf_net processing_system7_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7/FIXED_IO]

  # Create port connections
  connect_bd_net -net axi_gpio_leds_gpio2_io_o [get_bd_pins axi_gpio_leds/gpio2_io_o] [get_bd_pins fit_timer/Rst]
  connect_bd_net -net clock_clk_2x_out -boundary_type upper [get_bd_pins clock/clk_2x_out]
  connect_bd_net -net clock_clk_out [get_bd_pins axi_bram_ctrl_onchip_A4/s_axi_aclk] [get_bd_pins axi_bram_ctrl_onchip_A4L/s_axi_aclk] [get_bd_pins axi_crossbar_data_uncacheable/aclk] [get_bd_pins axi_gpio_leds/s_axi_aclk] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_GP0/ACLK] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_GP0/M00_ACLK] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_GP0/S00_ACLK] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_HP1/ACLK] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_HP1/M00_ACLK] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_HP1/S00_ACLK] [get_bd_pins axi_interconnect_instruction_cached/ACLK] [get_bd_pins axi_interconnect_instruction_cached/M00_ACLK] [get_bd_pins axi_interconnect_instruction_cached/M01_ACLK] [get_bd_pins axi_interconnect_instruction_cached/S00_ACLK] [get_bd_pins clock/clk_out] [get_bd_pins edge_extender/clk] [get_bd_pins fit_timer/Clk] [get_bd_pins idram/clk] [get_bd_pins orca/clk] [get_bd_pins processing_system7/S_AXI_GP0_ACLK] [get_bd_pins processing_system7/S_AXI_HP0_ACLK] [get_bd_pins processing_system7/S_AXI_HP1_ACLK] [get_bd_pins ps7_uart_monitor/axi_aclk] [get_bd_pins system_ila_orca_masters/clk]
  connect_bd_net -net clock_interconnect_aresetn [get_bd_pins axi_interconnect_A4L_to_A4_PS7_GP0/ARESETN] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_HP1/ARESETN] [get_bd_pins axi_interconnect_instruction_cached/ARESETN] [get_bd_pins clock/interconnect_aresetn]
  connect_bd_net -net clock_peripheral_aresetn [get_bd_pins axi_bram_ctrl_onchip_A4/s_axi_aresetn] [get_bd_pins axi_bram_ctrl_onchip_A4L/s_axi_aresetn] [get_bd_pins axi_crossbar_data_uncacheable/aresetn] [get_bd_pins axi_gpio_leds/s_axi_aresetn] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_GP0/M00_ARESETN] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_GP0/S00_ARESETN] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_HP1/M00_ARESETN] [get_bd_pins axi_interconnect_A4L_to_A4_PS7_HP1/S00_ARESETN] [get_bd_pins axi_interconnect_instruction_cached/M00_ARESETN] [get_bd_pins axi_interconnect_instruction_cached/M01_ARESETN] [get_bd_pins axi_interconnect_instruction_cached/S00_ARESETN] [get_bd_pins clock/peripheral_aresetn] [get_bd_pins ps7_uart_monitor/axi_aresetn] [get_bd_pins system_ila_orca_masters/resetn]
  connect_bd_net -net clock_peripheral_reset [get_bd_pins clock/peripheral_reset] [get_bd_pins edge_extender/reset] [get_bd_pins idram/reset] [get_bd_pins orca/reset]
  connect_bd_net -net edge_extender_0_interrupt_out [get_bd_pins edge_extender/interrupt_out] [get_bd_pins orca/global_interrupts]
  connect_bd_net -net fit_timer_Interrupt [get_bd_pins edge_extender/interrupt_in] [get_bd_pins fit_timer/Interrupt]
  connect_bd_net -net processing_system7_FCLK_CLK0 [get_bd_pins clock/clk_in1] [get_bd_pins processing_system7/FCLK_CLK0]
  connect_bd_net -net processing_system7_FCLK_RESET0_N [get_bd_pins clock/ext_reset_in] [get_bd_pins processing_system7/FCLK_RESET0_N]
  connect_bd_net -net xlconstant_bypass_ps7_uart_dout [get_bd_pins ps7_uart_monitor/bypass] [get_bd_pins xlconstant_bypass_ps7_uart/dout]

  # Create address segments
  create_bd_addr_seg -range 0x00020000 -offset 0x50000000 [get_bd_addr_spaces orca/IC] [get_bd_addr_segs axi_bram_ctrl_onchip_A4/S_AXI/Mem0] SEG_axi_bram_ctrl_onchip_A4_Mem0
  create_bd_addr_seg -range 0x00020000 -offset 0xD0000000 [get_bd_addr_spaces orca/DUC] [get_bd_addr_segs axi_bram_ctrl_onchip_A4L/S_AXI/Mem0] SEG_axi_bram_ctrl_onchip_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0xFFFF0000 [get_bd_addr_spaces orca/DUC] [get_bd_addr_segs axi_gpio_leds/S_AXI/Reg] SEG_axi_gpio_leds_Reg
  create_bd_addr_seg -range 0x10000000 -offset 0xC0000000 [get_bd_addr_spaces orca/DUC] [get_bd_addr_segs idram/data/reg0] SEG_idram_reg0
  create_bd_addr_seg -range 0x10000000 -offset 0xC0000000 [get_bd_addr_spaces orca/IUC] [get_bd_addr_segs idram/instr/reg0] SEG_idram_reg0
  create_bd_addr_seg -range 0x20000000 -offset 0x80000000 [get_bd_addr_spaces orca/DUC] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_DDR_LOWOCM] SEG_processing_system7_GP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x00400000 -offset 0xE0000000 [get_bd_addr_spaces orca/DUC] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_IOP] SEG_processing_system7_GP0_IOP
  create_bd_addr_seg -range 0x01000000 -offset 0xFC000000 [get_bd_addr_spaces orca/DUC] [get_bd_addr_segs processing_system7/S_AXI_GP0/GP0_QSPI_LINEAR] SEG_processing_system7_GP0_QSPI_LINEAR
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces orca/IC] [get_bd_addr_segs processing_system7/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces orca/DUC] [get_bd_addr_segs processing_system7/S_AXI_HP1/HP1_DDR_LOWOCM] SEG_processing_system7_HP1_DDR_LOWOCM


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


