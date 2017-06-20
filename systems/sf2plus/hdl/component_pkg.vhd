-- component_pkg.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- Component declarations

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.isa_pkg.all;
use work.util_pkg.all;
use work.architecture_pkg.all;

package component_pkg is
  component avalon_buffer
    generic (
      ADDR_WIDTH       : integer  := 27;
      MEM_WIDTH_BYTES  : integer  := 4;
      BURSTCOUNT_BITS  : positive := 1;
      MULTI_READ_BURST : boolean  := false;
      BUFFER_READDATA  : boolean  := true
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      empty : out std_logic;

      slave_waitrequest   : out std_logic;
      slave_address       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      slave_burstcount    : in  std_logic_vector(BURSTCOUNT_BITS-1 downto 0);
      slave_read          : in  std_logic;
      slave_write         : in  std_logic;
      slave_writedata     : in  std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0);
      slave_byteenable    : in  std_logic_vector(MEM_WIDTH_BYTES-1 downto 0);
      slave_readdatavalid : out std_logic;
      slave_readdata      : out std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0);

      master_waitrequest   : in  std_logic;
      master_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      master_burstcount    : out std_logic_vector(BURSTCOUNT_BITS-1 downto 0);
      master_read          : out std_logic;
      master_write         : out std_logic;
      master_writedata     : out std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0);
      master_byteenable    : out std_logic_vector(MEM_WIDTH_BYTES-1 downto 0);
      master_readdatavalid : in  std_logic;
      master_readdata      : in  std_logic_vector(MEM_WIDTH_BYTES*8-1 downto 0)
      );
  end component;

  component nios_ci_handler
    port (
      ci_clk    : in std_logic;
      ci_clk_en : in std_logic;
      ci_reset  : in std_logic;

      ci_start : in  std_logic;
      ci_done  : out std_logic;

      ci_dataa   : in  std_logic_vector(31 downto 0);
      ci_datab   : in  std_logic_vector(31 downto 0);
      ci_writerc : in  std_logic;
      ci_result  : out std_logic_vector(31 downto 0);

      fsl_s_read   : out std_logic;
      fsl_s_data   : in  std_logic_vector(0 to 31);
      fsl_s_exists : in  std_logic;

      fsl_m_write : out std_logic;
      fsl_m_data  : out std_logic_vector(0 to 31);
      fsl_m_full  : in  std_logic
      );
  end component;

  component fsl_handler is
    generic (
      CFG_FAM           : config_family_type;
      MIN_MULTIPLIER_HW : min_size_type := BYTE;
      ADDR_WIDTH        : integer       := 1
      );
    port(
      FSL_Clk : in std_logic;

      FSL_S_Read   : in  std_logic;
      FSL_S_Data   : out std_logic_vector(0 to 31);
      FSL_S_Exists : out std_logic;

      FSL_M_Write : in  std_logic;
      FSL_M_Data  : in  std_logic_vector(0 to 31);
      FSL_M_Full  : out std_logic;

      core_pipeline_empty : in std_logic;
      dma_pipeline_empty  : in std_logic;

      instr_fifo_read     : in  std_logic;
      instr_fifo_readdata : out instruction_type;
      instr_fifo_empty    : out std_logic;

      mask_status_update  : in std_logic;
      mask_length_nonzero : in std_logic;

      clk   : in std_logic;
      reset : in std_logic
      );
  end component;

  component axis_instr_if is
    port (
      clk   : in std_logic;
      reset : in std_logic;

      m_tdata  : out std_logic_vector(31 downto 0);
      m_tlast  : out std_logic;
      m_tvalid : out std_logic;
      m_tready : in  std_logic;

      s_tdata  : in  std_logic_vector(31 downto 0);
      s_tlast  : in  std_logic;
      s_tvalid : in  std_logic;
      s_tready : out std_logic;

      fsl_s_read   : out std_logic;
      fsl_s_data   : in  std_logic_vector(0 to 31);
      fsl_s_exists : in  std_logic;

      fsl_m_write : out std_logic;
      fsl_m_data  : out std_logic_vector(0 to 31);
      fsl_m_full  : in  std_logic
      );
  end component;

  component axi_instr_slave is
    generic (
      C_S_AXI_DATA_WIDTH : integer := 32;
      C_S_AXI_ADDR_WIDTH : integer := 32;
      C_S_AXI_ID_WIDTH   : integer := 4
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      s_axi_awaddr  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awvalid : in  std_logic;
      s_axi_awready : out std_logic;
      s_axi_awid    : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_awlen   : in  std_logic_vector(7 downto 0);
      s_axi_awsize  : in  std_logic_vector(2 downto 0);
      s_axi_awburst : in  std_logic_vector(1 downto 0);

      s_axi_wdata  : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_wstrb  : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      s_axi_wvalid : in  std_logic;
      s_axi_wlast  : in  std_logic;
      s_axi_wready : out std_logic;

      s_axi_bready : in  std_logic;
      s_axi_bresp  : out std_logic_vector(1 downto 0);
      s_axi_bvalid : out std_logic;
      s_axi_bid    : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

      s_axi_araddr  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_arvalid : in  std_logic;
      s_axi_arready : out std_logic;
      s_axi_arid    : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_arlen   : in  std_logic_vector(7 downto 0);
      s_axi_arsize  : in  std_logic_vector(2 downto 0);
      s_axi_arburst : in  std_logic_vector(1 downto 0);

      s_axi_rready : in  std_logic;
      s_axi_rdata  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_rresp  : out std_logic_vector(1 downto 0);
      s_axi_rvalid : out std_logic;
      s_axi_rlast  : out std_logic;
      s_axi_rid    : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);

      fsl_s_read   : out std_logic;
      fsl_s_data   : in  std_logic_vector(0 to 31);
      fsl_s_exists : in  std_logic;

      fsl_m_write : out std_logic;
      fsl_m_data  : out std_logic_vector(0 to 31);
      fsl_m_full  : in  std_logic

      );
  end component;

  component scratchpad_arbiter is
    generic (
      VECTOR_LANES : integer := 1;

      CFG_FAM : config_family_type;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      request_in  : in  std_logic_vector(scratchpad_requests_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      request_out : out std_logic_vector(scratchpad_requests_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

      scratch_port_d : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      readdata_d     : in  scratchpad_data((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component scratchpad is
    generic (
      VECTOR_LANES  : integer := 1;
      SCRATCHPAD_KB : integer := 8;

      CFG_FAM : config_family_type;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk    : in std_logic;
      reset  : in std_logic;
      clk_2x : in std_logic;

      scratch_port_a : in std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      scratch_port_b : in std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      scratch_port_c : in std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      scratch_port_d : in std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

      readdata_a : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      readdata_b : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      readdata_c : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      readdata_d : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component vci_handler
    generic (
      VECTOR_LANES               : positive range 1 to MAX_VECTOR_LANES       := 1;
      CFG_FAM                    : config_family_type                         := CFG_FAM_ALTERA;
      VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS := 0;
      VCI_CONFIGS                : vci_config_array                           := DEFAULT_VCI_CONFIGS;
      VCI_DEPTHS                 : vci_depth_array                            := DEFAULT_VCI_DEPTHS
      );
    port(
      core_clk : in std_logic;

      -- To/From vblox1_core --
      vci_valid  : in std_logic_vector(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);
      vci_signed : in std_logic;
      vci_opsize : in std_logic_vector(1 downto 0);

      vci_vector_start : in std_logic;
      vci_vector_end   : in std_logic;
      vci_byte_valid   : in std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_dest_addr_in : in std_logic_vector(31 downto 0);

      vci_data_a : in std_logic_vector(VECTOR_LANES*32-1 downto 0);
      vci_flag_a : in std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_data_b : in std_logic_vector(VECTOR_LANES*32-1 downto 0);
      vci_flag_b : in std_logic_vector(VECTOR_LANES*4-1 downto 0);

      vci_port          : in  unsigned(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0);
      vci_data_out      : out std_logic_vector(VECTOR_LANES*32-1 downto 0);
      vci_flag_out      : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_byteenable    : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_dest_addr_out : out std_logic_vector(31 downto 0);

      -- To/From Vector Custom Instructions --
      vci_0_valid         : out std_logic_vector(VCI_CONFIGS(0).OPCODE_END-VCI_CONFIGS(0).OPCODE_START downto 0);
      vci_0_data_out      : in  std_logic_vector(VCI_CONFIGS(0).LANES*32-1 downto 0);
      vci_0_flag_out      : in  std_logic_vector(VCI_CONFIGS(0).LANES*4-1 downto 0);
      vci_0_byteenable    : in  std_logic_vector(VCI_CONFIGS(0).LANES*4-1 downto 0);
      vci_0_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_1_valid         : out std_logic_vector(VCI_CONFIGS(1).OPCODE_END-VCI_CONFIGS(1).OPCODE_START downto 0);
      vci_1_data_out      : in  std_logic_vector(VCI_CONFIGS(1).LANES*32-1 downto 0);
      vci_1_flag_out      : in  std_logic_vector(VCI_CONFIGS(1).LANES*4-1 downto 0);
      vci_1_byteenable    : in  std_logic_vector(VCI_CONFIGS(1).LANES*4-1 downto 0);
      vci_1_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_2_valid         : out std_logic_vector(VCI_CONFIGS(2).OPCODE_END-VCI_CONFIGS(2).OPCODE_START downto 0);
      vci_2_data_out      : in  std_logic_vector(VCI_CONFIGS(2).LANES*32-1 downto 0);
      vci_2_flag_out      : in  std_logic_vector(VCI_CONFIGS(2).LANES*4-1 downto 0);
      vci_2_byteenable    : in  std_logic_vector(VCI_CONFIGS(2).LANES*4-1 downto 0);
      vci_2_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_3_valid         : out std_logic_vector(VCI_CONFIGS(3).OPCODE_END-VCI_CONFIGS(3).OPCODE_START downto 0);
      vci_3_data_out      : in  std_logic_vector(VCI_CONFIGS(3).LANES*32-1 downto 0);
      vci_3_flag_out      : in  std_logic_vector(VCI_CONFIGS(3).LANES*4-1 downto 0);
      vci_3_byteenable    : in  std_logic_vector(VCI_CONFIGS(3).LANES*4-1 downto 0);
      vci_3_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_4_valid         : out std_logic_vector(VCI_CONFIGS(4).OPCODE_END-VCI_CONFIGS(4).OPCODE_START downto 0);
      vci_4_data_out      : in  std_logic_vector(VCI_CONFIGS(4).LANES*32-1 downto 0);
      vci_4_flag_out      : in  std_logic_vector(VCI_CONFIGS(4).LANES*4-1 downto 0);
      vci_4_byteenable    : in  std_logic_vector(VCI_CONFIGS(4).LANES*4-1 downto 0);
      vci_4_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_5_valid         : out std_logic_vector(VCI_CONFIGS(5).OPCODE_END-VCI_CONFIGS(5).OPCODE_START downto 0);
      vci_5_data_out      : in  std_logic_vector(VCI_CONFIGS(5).LANES*32-1 downto 0);
      vci_5_flag_out      : in  std_logic_vector(VCI_CONFIGS(5).LANES*4-1 downto 0);
      vci_5_byteenable    : in  std_logic_vector(VCI_CONFIGS(5).LANES*4-1 downto 0);
      vci_5_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_6_valid         : out std_logic_vector(VCI_CONFIGS(6).OPCODE_END-VCI_CONFIGS(6).OPCODE_START downto 0);
      vci_6_data_out      : in  std_logic_vector(VCI_CONFIGS(6).LANES*32-1 downto 0);
      vci_6_flag_out      : in  std_logic_vector(VCI_CONFIGS(6).LANES*4-1 downto 0);
      vci_6_byteenable    : in  std_logic_vector(VCI_CONFIGS(6).LANES*4-1 downto 0);
      vci_6_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_7_valid         : out std_logic_vector(VCI_CONFIGS(7).OPCODE_END-VCI_CONFIGS(7).OPCODE_START downto 0);
      vci_7_data_out      : in  std_logic_vector(VCI_CONFIGS(7).LANES*32-1 downto 0);
      vci_7_flag_out      : in  std_logic_vector(VCI_CONFIGS(7).LANES*4-1 downto 0);
      vci_7_byteenable    : in  std_logic_vector(VCI_CONFIGS(7).LANES*4-1 downto 0);
      vci_7_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_8_valid         : out std_logic_vector(VCI_CONFIGS(8).OPCODE_END-VCI_CONFIGS(8).OPCODE_START downto 0);
      vci_8_data_out      : in  std_logic_vector(VCI_CONFIGS(8).LANES*32-1 downto 0);
      vci_8_flag_out      : in  std_logic_vector(VCI_CONFIGS(8).LANES*4-1 downto 0);
      vci_8_byteenable    : in  std_logic_vector(VCI_CONFIGS(8).LANES*4-1 downto 0);
      vci_8_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_9_valid         : out std_logic_vector(VCI_CONFIGS(9).OPCODE_END-VCI_CONFIGS(9).OPCODE_START downto 0);
      vci_9_data_out      : in  std_logic_vector(VCI_CONFIGS(9).LANES*32-1 downto 0);
      vci_9_flag_out      : in  std_logic_vector(VCI_CONFIGS(9).LANES*4-1 downto 0);
      vci_9_byteenable    : in  std_logic_vector(VCI_CONFIGS(9).LANES*4-1 downto 0);
      vci_9_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_10_valid         : out std_logic_vector(VCI_CONFIGS(10).OPCODE_END-VCI_CONFIGS(10).OPCODE_START downto 0);
      vci_10_data_out      : in  std_logic_vector(VCI_CONFIGS(10).LANES*32-1 downto 0);
      vci_10_flag_out      : in  std_logic_vector(VCI_CONFIGS(10).LANES*4-1 downto 0);
      vci_10_byteenable    : in  std_logic_vector(VCI_CONFIGS(10).LANES*4-1 downto 0);
      vci_10_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_11_valid         : out std_logic_vector(VCI_CONFIGS(11).OPCODE_END-VCI_CONFIGS(11).OPCODE_START downto 0);
      vci_11_data_out      : in  std_logic_vector(VCI_CONFIGS(11).LANES*32-1 downto 0);
      vci_11_flag_out      : in  std_logic_vector(VCI_CONFIGS(11).LANES*4-1 downto 0);
      vci_11_byteenable    : in  std_logic_vector(VCI_CONFIGS(11).LANES*4-1 downto 0);
      vci_11_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_12_valid         : out std_logic_vector(VCI_CONFIGS(12).OPCODE_END-VCI_CONFIGS(12).OPCODE_START downto 0);
      vci_12_data_out      : in  std_logic_vector(VCI_CONFIGS(12).LANES*32-1 downto 0);
      vci_12_flag_out      : in  std_logic_vector(VCI_CONFIGS(12).LANES*4-1 downto 0);
      vci_12_byteenable    : in  std_logic_vector(VCI_CONFIGS(12).LANES*4-1 downto 0);
      vci_12_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_13_valid         : out std_logic_vector(VCI_CONFIGS(13).OPCODE_END-VCI_CONFIGS(13).OPCODE_START downto 0);
      vci_13_data_out      : in  std_logic_vector(VCI_CONFIGS(13).LANES*32-1 downto 0);
      vci_13_flag_out      : in  std_logic_vector(VCI_CONFIGS(13).LANES*4-1 downto 0);
      vci_13_byteenable    : in  std_logic_vector(VCI_CONFIGS(13).LANES*4-1 downto 0);
      vci_13_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_14_valid         : out std_logic_vector(VCI_CONFIGS(14).OPCODE_END-VCI_CONFIGS(14).OPCODE_START downto 0);
      vci_14_data_out      : in  std_logic_vector(VCI_CONFIGS(14).LANES*32-1 downto 0);
      vci_14_flag_out      : in  std_logic_vector(VCI_CONFIGS(14).LANES*4-1 downto 0);
      vci_14_byteenable    : in  std_logic_vector(VCI_CONFIGS(14).LANES*4-1 downto 0);
      vci_14_dest_addr_out : in  std_logic_vector(31 downto 0);

      vci_15_valid         : out std_logic_vector(VCI_CONFIGS(15).OPCODE_END-VCI_CONFIGS(15).OPCODE_START downto 0);
      vci_15_data_out      : in  std_logic_vector(VCI_CONFIGS(15).LANES*32-1 downto 0);
      vci_15_flag_out      : in  std_logic_vector(VCI_CONFIGS(15).LANES*4-1 downto 0);
      vci_15_byteenable    : in  std_logic_vector(VCI_CONFIGS(15).LANES*4-1 downto 0);
      vci_15_dest_addr_out : in  std_logic_vector(31 downto 0)
      );
  end component;

  component vblox1_core
    generic (
      VECTOR_LANES               : integer                                    := 1;
      VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS := 0;
      VCI_CONFIGS                : vci_config_array                           := DEFAULT_VCI_CONFIGS;
      VCI_DEPTHS                 : vci_depth_array                            := DEFAULT_VCI_DEPTHS;
      MAX_MASKED_WAVES           : positive range 128 to 8192                 := 128;
      MASK_PARTITIONS            : natural                                    := 1;

      MIN_MULTIPLIER_HW : min_size_type := BYTE;

      MULFXP_WORD_FRACTION_BITS : integer range 1 to 31 := 25;
      MULFXP_HALF_FRACTION_BITS : integer range 1 to 15 := 15;
      MULFXP_BYTE_FRACTION_BITS : integer range 1 to 7  := 4;

      CFG_FAM : config_family_type;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk    : in std_logic;
      reset  : in std_logic;
      clk_2x : in std_logic;

      core_pipeline_empty : out std_logic;

      dma_instr_valid : out std_logic;
      dma_instruction : out instruction_type;
      dma_instr_read  : in  std_logic;
      dma_status      : in  std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);

      scratch_port_a : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      scratch_port_b : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      scratch_port_c : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

      readdata_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      readdata_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

      instr_fifo_empty    : in  std_logic;
      instr_fifo_readdata : in  instruction_type;
      instr_fifo_read     : out std_logic;

      mask_status_update  : out std_logic;
      mask_length_nonzero : out std_logic;

      vci_valid  : out std_logic_vector(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);
      vci_signed : out std_logic;
      vci_opsize : out std_logic_vector(1 downto 0);

      vci_vector_start : out std_logic;
      vci_vector_end   : out std_logic;
      vci_byte_valid   : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_dest_addr_in : out std_logic_vector(31 downto 0);

      vci_data_a : out std_logic_vector(VECTOR_LANES*32-1 downto 0);
      vci_flag_a : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_data_b : out std_logic_vector(VECTOR_LANES*32-1 downto 0);
      vci_flag_b : out std_logic_vector(VECTOR_LANES*4-1 downto 0);

      vci_port          : out unsigned(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0);
      vci_data_out      : in  std_logic_vector(VECTOR_LANES*32-1 downto 0);
      vci_flag_out      : in  std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_byteenable    : in  std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_dest_addr_out : in  std_logic_vector(31 downto 0)
      );
  end component;

  component scratchpad_ram
    generic (
      RAM_DEPTH : integer := 1024
      );
    port
      (
        address_a  : in  std_logic_vector (log2(RAM_DEPTH)-1 downto 0);
        address_b  : in  std_logic_vector (log2(RAM_DEPTH)-1 downto 0);
        byteena_a  : in  std_logic_vector (0 downto 0);
        byteena_b  : in  std_logic_vector (0 downto 0);
        clock      : in  std_logic;
        data_a     : in  std_logic_vector (8 downto 0);
        data_b     : in  std_logic_vector (8 downto 0);
        wren_a     : in  std_logic;
        wren_b     : in  std_logic;
        readdata_a : out std_logic_vector (8 downto 0);
        readdata_b : out std_logic_vector (8 downto 0)
        );
  end component;

  component scratchpad_ram_xil
    generic (
      RAM_DEPTH : integer := 1024
      );
    port
      (
        address_a  : in  std_logic_vector (log2(RAM_DEPTH)-1 downto 0);
        address_b  : in  std_logic_vector (log2(RAM_DEPTH)-1 downto 0);
        clock      : in  std_logic;
        data_a     : in  std_logic_vector (8 downto 0);
        data_b     : in  std_logic_vector (8 downto 0);
        wren_a     : in  std_logic;
        wren_b     : in  std_logic;
        readdata_a : out std_logic_vector (8 downto 0);
        readdata_b : out std_logic_vector (8 downto 0)
        );
  end component;

  component scratchpad_ram_microsemi
    generic (
      RAM_DEPTH : integer := 1024
      );
    port
      (
        address_a  : in  std_logic_vector (log2(RAM_DEPTH)-1 downto 0);
        address_b  : in  std_logic_vector (log2(RAM_DEPTH)-1 downto 0);
        clock      : in  std_logic;
        data_a     : in  std_logic_vector (8 downto 0);
        data_b     : in  std_logic_vector (8 downto 0);
        wren_a     : in  std_logic;
        wren_b     : in  std_logic;
        readdata_a : out std_logic_vector (8 downto 0);
        readdata_b : out std_logic_vector (8 downto 0)
        );
  end component;

  component avalon_slave
    generic (
      VECTOR_LANES : integer := 1;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      slave_request_out : in  std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      slave_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

      slave_address       : in  std_logic_vector(ADDR_WIDTH-3 downto 0);
      slave_read          : in  std_logic;
      slave_write         : in  std_logic;
      slave_waitrequest   : out std_logic;
      slave_readdatavalid : out std_logic;

      slave_writedata  : in  std_logic_vector(31 downto 0);
      slave_byteenable : in  std_logic_vector(3 downto 0);
      slave_readdata   : out std_logic_vector(31 downto 0)
      );
  end component;

  component axi4lite_sp_slave is
    generic (
      VECTOR_LANES       : integer := 1;
      ADDR_WIDTH         : integer := 1;
      EXT_ALIGN          : boolean := false;
      C_S_AXI_DATA_WIDTH : integer := 32;
      C_S_AXI_ADDR_WIDTH : integer := 32
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWVALID : in  std_logic;
      S_AXI_AWREADY : out std_logic;

      S_AXI_WDATA  : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB  : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WVALID : in  std_logic;
      S_AXI_WREADY : out std_logic;

      S_AXI_BREADY : in  std_logic;
      S_AXI_BRESP  : out std_logic_vector(1 downto 0);
      S_AXI_BVALID : out std_logic;

      S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARVALID : in  std_logic;
      S_AXI_ARREADY : out std_logic;

      S_AXI_RREADY : in  std_logic;
      S_AXI_RDATA  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP  : out std_logic_vector(1 downto 0);
      S_AXI_RVALID : out std_logic;

      slave_request_out : in  std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      slave_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0)
      );
  end component;

  component dma_controller
    generic (
      VECTOR_LANES       : integer := 1;
      MEMORY_WIDTH_LANES : integer := 1;
      BURSTLENGTH_BYTES  : integer := 32;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      dma_instr_valid    : in  std_logic;
      dma_instruction    : in  instruction_type;
      dma_instr_read     : out std_logic;
      dma_status         : out std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);
      dma_pipeline_empty : out std_logic;

      dma_request_out : in  std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      dma_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

      master_address       : out std_logic_vector(31 downto 0);
      master_read          : out std_logic;
      master_write         : out std_logic;
      master_waitrequest   : in  std_logic;
      master_readdatavalid : in  std_logic;

      master_burstcount : out std_logic_vector(burst_bits(BURSTLENGTH_BYTES, MEMORY_WIDTH_LANES)-1 downto 0);

      master_writedata  : out std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
      master_byteenable : out std_logic_vector(MEMORY_WIDTH_LANES*4-1 downto 0);
      master_readdata   : in  std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0)
      );
  end component;

  component dma_controller_axi is
    generic (
      VECTOR_LANES       : integer                 := 1;
      MEMORY_WIDTH_LANES : integer range 1 to 32   := 1;
      BURSTLENGTH_BYTES  : integer range 4 to 4096 := 32;

      ADDR_WIDTH : integer := 1;

      C_M_AXI_ADDR_WIDTH   : integer := 32;
      C_M_AXI_ARUSER_WIDTH : integer := 5;
      C_M_AXI_AWUSER_WIDTH : integer := 5
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      dma_instr_valid    : in  std_logic;
      dma_instruction    : in  instruction_type;
      dma_instr_read     : out std_logic;
      dma_status         : out std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);
      dma_pipeline_empty : out std_logic;

      dma_request_out : in  std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      dma_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

      -- AXI4 master
      m_axi_arready : in  std_logic;
      m_axi_arvalid : out std_logic;
      m_axi_araddr  : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      m_axi_arlen   : out std_logic_vector(7 downto 0);
      m_axi_arsize  : out std_logic_vector(2 downto 0);
      m_axi_arburst : out std_logic_vector(1 downto 0);
      m_axi_arprot  : out std_logic_vector(2 downto 0);
      m_axi_arcache : out std_logic_vector(3 downto 0);
      m_axi_aruser  : out std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0);

      m_axi_rready : out std_logic;
      m_axi_rvalid : in  std_logic;
      m_axi_rdata  : in  std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
      m_axi_rresp  : in  std_logic_vector(1 downto 0);
      m_axi_rlast  : in  std_logic;

      m_axi_awready : in  std_logic;
      m_axi_awvalid : out std_logic;
      m_axi_awaddr  : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      m_axi_awlen   : out std_logic_vector(7 downto 0);
      m_axi_awsize  : out std_logic_vector(2 downto 0);
      m_axi_awburst : out std_logic_vector(1 downto 0);
      m_axi_awprot  : out std_logic_vector(2 downto 0);
      m_axi_awcache : out std_logic_vector(3 downto 0);
      m_axi_awuser  : out std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0);

      m_axi_wready : in  std_logic;
      m_axi_wvalid : out std_logic;
      m_axi_wdata  : out std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
      m_axi_wstrb  : out std_logic_vector(MEMORY_WIDTH_LANES*4-1 downto 0);
      m_axi_wlast  : out std_logic;

      m_axi_bready : out std_logic;
      m_axi_bvalid : in  std_logic;
      m_axi_bresp  : in  std_logic_vector(1 downto 0)
      );
  end component;

  component dma_queue
    generic (
      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      dma_instruction : in instruction_type;
      dma_queue_write : in std_logic;
      dma_queue_read  : in std_logic;

      update_scratchpad_start : in std_logic;
      new_scratchpad_start    : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      update_external_start   : in std_logic;
      new_external_start      : in std_logic_vector(31 downto 0);
      decrement_rows          : in std_logic;

      dma_2d_rows           : in unsigned(ADDR_WIDTH-1 downto 0);
      dma_2d_scratch_incr   : in unsigned(ADDR_WIDTH-1 downto 0);
      dma_2d_scratch_length : in unsigned(ADDR_WIDTH downto 0);
      dma_2d_ext_incr       : in unsigned(31 downto 0);

      current_dma     : out std_logic_vector(dma_info_length(ADDR_WIDTH)-1 downto 0);
      dma_status      : out std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);
      dma_queue_empty : out std_logic;
      dma_queue_full  : out std_logic
      );
  end component;

  component dma_engine
    generic (
      VECTOR_LANES       : integer := 1;
      MEMORY_WIDTH_LANES : integer := 1;
      BURSTLENGTH_BYTES  : integer := 32;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      current_dma     : in std_logic_vector(dma_info_length(ADDR_WIDTH)-1 downto 0);
      dma_request_out : in std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

      master_waitrequest   : in std_logic;
      master_readdatavalid : in std_logic;
      master_readdata      : in std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);

      master_address    : out std_logic_vector(31 downto 0);
      master_read       : out std_logic;
      master_write      : out std_logic;
      master_burstcount : out std_logic_vector(burst_bits(BURSTLENGTH_BYTES, MEMORY_WIDTH_LANES)-1 downto 0);
      master_writedata  : out std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
      master_byteenable : out std_logic_vector(MEMORY_WIDTH_LANES*4-1 downto 0);

      update_scratchpad_start : out std_logic;
      new_scratchpad_start    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      update_external_start   : out std_logic;
      new_external_start      : out std_logic_vector(31 downto 0);
      decrement_rows          : out std_logic;

      dma_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      dma_queue_read  : out std_logic;
      dma_in_progress : out std_logic
      );
  end component;

  component dma_engine_axi is
    generic (
      VECTOR_LANES       : integer                 := 1;
      MEMORY_WIDTH_LANES : integer range 1 to 32   := 1;
      BURSTLENGTH_BYTES  : integer range 4 to 4096 := 32;

      ADDR_WIDTH : integer := 1;

      C_M_AXI_ADDR_WIDTH   : integer := 32;
      C_M_AXI_ARUSER_WIDTH : integer := 5;
      C_M_AXI_AWUSER_WIDTH : integer := 5
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      update_scratchpad_start : out std_logic;
      new_scratchpad_start    : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      update_external_start : out std_logic;
      new_external_start    : out std_logic_vector(31 downto 0);

      decrement_rows : out std_logic;

      dma_request_in  : out std_logic_vector(scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      dma_request_out : in  std_logic_vector(scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

      dma_queue_read  : out std_logic;
      dma_in_progress : out std_logic;
      current_dma     : in  std_logic_vector(dma_info_length(ADDR_WIDTH)-1 downto 0);

      -- AXI4 Master

      m_axi_arready : in  std_logic;
      m_axi_arvalid : out std_logic;
      m_axi_araddr  : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      m_axi_arlen   : out std_logic_vector(7 downto 0);
      m_axi_arsize  : out std_logic_vector(2 downto 0);
      m_axi_arburst : out std_logic_vector(1 downto 0);
      m_axi_arprot  : out std_logic_vector(2 downto 0);
      m_axi_arcache : out std_logic_vector(3 downto 0);
      m_axi_aruser  : out std_logic_vector(C_M_AXI_ARUSER_WIDTH-1 downto 0);

      m_axi_rready : out std_logic;
      m_axi_rvalid : in  std_logic;
      m_axi_rdata  : in  std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
      m_axi_rresp  : in  std_logic_vector(1 downto 0);
      m_axi_rlast  : in  std_logic;

      m_axi_awready : in  std_logic;
      m_axi_awvalid : out std_logic;
      m_axi_awaddr  : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      m_axi_awlen   : out std_logic_vector(7 downto 0);
      m_axi_awsize  : out std_logic_vector(2 downto 0);
      m_axi_awburst : out std_logic_vector(1 downto 0);
      m_axi_awprot  : out std_logic_vector(2 downto 0);
      m_axi_awcache : out std_logic_vector(3 downto 0);
      m_axi_awuser  : out std_logic_vector(C_M_AXI_AWUSER_WIDTH-1 downto 0);

      m_axi_wready : in  std_logic;
      m_axi_wvalid : out std_logic;
      m_axi_wdata  : out std_logic_vector(MEMORY_WIDTH_LANES*32-1 downto 0);
      m_axi_wstrb  : out std_logic_vector(MEMORY_WIDTH_LANES*4-1 downto 0);
      m_axi_wlast  : out std_logic;

      m_axi_bready : out std_logic;
      m_axi_bvalid : in  std_logic;
      m_axi_bresp  : in  std_logic_vector(1 downto 0)
      );
  end component;

  component dma_hazard_detect
    generic (
      VECTOR_LANES : integer := 1;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      dma_status : in std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);

      addr_a       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      instr_uses_a : in std_logic;
      addr_b       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      instr_uses_b : in std_logic;
      addr_dest    : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      write_dest   : in std_logic;

      prev_addr_a       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      prev_instr_uses_a : in std_logic;
      prev_addr_b       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      prev_instr_uses_b : in std_logic;
      prev_addr_dest    : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      prev_write_dest   : in std_logic;

      dma_hazard : out std_logic
      );
  end component;

  component instr_hazard_detect
    generic (
      VECTOR_LANES : integer := 1;

      PIPELINE_STAGES : integer := 1;
      HAZARD_STAGES   : integer := 1;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      addr_a       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      instr_uses_a : in std_logic;
      addr_b       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      instr_uses_b : in std_logic;

      dest_addrs          : in addr_pipeline_type(PIPELINE_STAGES-1 downto 0);
      current_instruction : in std_logic_vector(HAZARD_STAGES-1 downto 0);
      dest_write_shifter  : in std_logic_vector(HAZARD_STAGES-1 downto 0);

      instr_hazard_pipeline : out std_logic_vector(HAZARD_STAGES-1 downto 0)
      );
  end component;

  component wave_expander
    generic (
      VECTOR_LANES : integer  := 1;
      PARTS        : positive := 2
      );
    port(
      enables_in : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      available  : in std_logic_vector(PARTS-1 downto 0);

      alignment      : out std_logic_vector(log2(PARTS)-1 downto 0);
      next_available : out std_logic_vector(PARTS-1 downto 0);
      last           : out std_logic;
      enables_out    : out std_logic_vector((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component masked_unit
    generic (
      VECTOR_LANES     : integer                    := 1;
      MAX_MASKED_WAVES : positive range 128 to 8192 := 128;
      MASK_PARTITIONS  : natural                    := 1;

      ADDR_WIDTH : integer := 1
      );
    port(
      clk   : in std_logic;
      reset : in std_logic;

      mask_write             : in std_logic;
      mask_write_size        : in opsize;
      mask_write_last        : in std_logic;
      mask_writedata_enables : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      mask_writedata_offset  : in std_logic_vector(ADDR_WIDTH-1 downto 0);

      next_mask           : in  std_logic;
      mask_read_size      : in  opsize;
      mask_status_update  : out std_logic;
      mask_length_nonzero : out std_logic;
      masked_enables      : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      masked_offset       : out std_logic_vector(log2(MAX_MASKED_WAVES*VECTOR_LANES*4)+1 downto 0);
      masked_end          : out std_logic
      );
  end component;

  component addr_gen
    generic (
      VECTOR_LANES               : integer                                    := 1;
      VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS := 0;
      VCI_CONFIGS                : vci_config_array                           := DEFAULT_VCI_CONFIGS;
      VCI_INFO_ROM               : vci_info_array                             := DEFAULT_VCI_INFO_ROM;
      MAX_MASKED_WAVES           : positive range 128 to 8192                 := 128;
      MASK_PARTITIONS            : natural                                    := 1;

      PIPELINE_STAGES      : integer := 1;
      HAZARD_STAGES        : integer := 1;
      STAGE_IN_SHIFT_START : integer := 1;
      STAGE_MUL_START      : integer := 1;
      STAGE_ACCUM_START    : integer := 1;
      STAGE_ACCUM_END      : integer := 1;

      CFG_FAM : config_family_type;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      core_instr_pending   : in std_logic;
      dma_status           : in std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);
      instruction_pipeline : in instruction_pipeline_type;

      mask_writedata_enables : in  std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      mask_status_update     : out std_logic;
      mask_length_nonzero    : out std_logic;

      core_instr_read : out std_logic;
      stall           : out std_logic;

      in_shift_element         : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      exec_dest_addr           : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      exec_byteena             : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      exec_first_column        : out std_logic;
      exec_last_cycle          : out std_logic;
      exec_last_cooldown_cycle : out std_logic;
      exec_read                : out std_logic;
      exec_write               : out std_logic;
      exec_we                  : out std_logic;

      scalar_a : out std_logic_vector(31 downto 0);
      offset_a : out std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
      offset_b : out std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);

      scratch_port_a : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
      scratch_port_b : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0)
      );
  end component;

  component barrel_shifter
    generic (
      WORD_WIDTH : integer := 1;
      WORDS      : integer := 1;
      LEFT_SHIFT : boolean := false
      );
    port (
      data_in      : in std_logic_vector(WORD_WIDTH*WORDS-1 downto 0);
      shift_amount : in std_logic_vector(log2(WORDS)-1 downto 0);

      data_out : out std_logic_vector(WORD_WIDTH*WORDS-1 downto 0)
      );
  end component;

  component size_up
    generic (
      VECTOR_LANES : integer := 1
      );
    port (
      clk : in std_logic;

      next_instruction : in instruction_type;

      data_in  : in  scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      data_out : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component in_shifter
    generic (
      VECTOR_LANES : integer := 1;

      PIPELINE_STAGES      : integer := 1;
      EXTRA_ALIGN_STAGES   : integer := 1;
      STAGE_IN_SHIFT_START : integer := 1;
      STAGE_IN_SHIFT_END   : integer := 1;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      instruction_pipeline : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);
      scalar_a             : in std_logic_vector(31 downto 0);
      in_shift_element     : in std_logic_vector(ADDR_WIDTH-1 downto 0);

      offset_a   : in  std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
      readdata_a : in  scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      shifted_a  : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);

      offset_b   : in  std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
      readdata_b : in  scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      shifted_b  : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component size_down
    generic (
      VECTOR_LANES : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      instruction      : in instruction_type;
      next_instruction : in instruction_type;

      data_in    : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      byteena_in : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);

      data_out    : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      byteena_out : out std_logic_vector((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component out_shifter
    generic (
      VECTOR_LANES : integer := 1;

      EXTRA_ALIGN_STAGES : integer := 1;

      CFG_FAM : config_family_type;

      ADDR_WIDTH : integer := 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      instruction      : in instruction_type;
      next_instruction : in instruction_type;

      dest_addr      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      dest_byteena   : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      dest_writedata : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      dest_we        : in std_logic;

      scratch_port_c : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0)
      );
  end component;

  component hardware_mult
    generic (
      WIDTH_A   : integer := 33;
      WIDTH_B   : integer := 33;
      WIDTH_OUT : integer := 66;
      DELAY     : integer := 2
      );
    port
      (
        clk    : in  std_logic;
        dataa  : in  std_logic_vector(WIDTH_A-1 downto 0);
        datab  : in  std_logic_vector(WIDTH_B-1 downto 0);
        result : out std_logic_vector(WIDTH_OUT-1 downto 0)
        );
  end component;

  component byte_shamt_rom
    port
      (
        shamt_trunc        : in  std_logic_vector(2 downto 0);
        shiftl             : in  std_logic;
        byte_shamt_rom_out : out std_logic_vector(8 downto 0)
        );
  end component;

  component half_shamt_rom
    port
      (
        shamt_trunc        : in  std_logic_vector(3 downto 0);
        shiftl             : in  std_logic;
        half_shamt_rom_out : out std_logic_vector(17 downto 0)
        );
  end component;

  component word_shamt_rom
    port
      (
        shamt_trunc        : in  std_logic_vector(4 downto 0);
        shiftl             : in  std_logic;
        word_shamt_rom_out : out std_logic_vector(33 downto 0)
        );
  end component;

  component mul_unit
    generic (
      VECTOR_LANES : integer := 1;

      MULFXP_WORD_FRACTION_BITS : integer range 1 to 31 := 25;
      MULFXP_HALF_FRACTION_BITS : integer range 1 to 15 := 15;
      MULFXP_BYTE_FRACTION_BITS : integer range 1 to 7  := 4;

      CFG_FAM : config_family_type;

      PIPELINE_STAGES : integer := 1;
      STAGE_MUL_START : integer := 1;
      STAGE_MUL_END   : integer := 1
      );
    port(
      clk   : in std_logic;
      reset : in std_logic;

      instruction_pipeline : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);

      data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

      multiplier_out : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component arith_unit
    generic (
      VECTOR_LANES : integer := 1
      );
    port(
      clk   : in std_logic;
      reset : in std_logic;

      next_instruction : in instruction_type;
      instruction      : in instruction_type;

      data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

      arith_out : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component cmov_unit
    generic (
      VECTOR_LANES : integer := 1
      );
    port(
      clk   : in std_logic;
      reset : in std_logic;

      instruction : in instruction_type;

      data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

      cmov_byteena : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      cmov_out     : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component alu_unit
    generic (
      VECTOR_LANES : integer := 1;

      CFG_FAM : config_family_type;

      PIPELINE_STAGES : integer := 1;
      STAGE_MUL_START : integer := 1
      );
    port(
      clk   : in std_logic;
      reset : in std_logic;

      exec_byteena         : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      instruction_pipeline : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);

      data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

      mask_writedata_enables : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);

      alu_byteena : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      alu_out     : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component absv_unit
    generic (
      VECTOR_LANES : integer := 1
      );
    port(
      clk   : in std_logic;
      reset : in std_logic;

      next_instruction : in instruction_type;
      instruction      : in instruction_type;

      alu_result : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

      absv_out : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
      );
  end component;

  component exec_unit
    generic (
      VECTOR_LANES : integer        := 1;
      VCI_INFO_ROM : vci_info_array := DEFAULT_VCI_INFO_ROM;

      MIN_MULTIPLIER_HW : min_size_type := BYTE;

      MULFXP_WORD_FRACTION_BITS : integer range 1 to 31 := 25;
      MULFXP_HALF_FRACTION_BITS : integer range 1 to 15 := 15;
      MULFXP_BYTE_FRACTION_BITS : integer range 1 to 7  := 4;

      CFG_FAM : config_family_type;

      PIPELINE_STAGES : integer := 1;
      STAGE_MUL_START : integer := 1;
      STAGE_MUL_END   : integer := 1;

      ADDR_WIDTH : integer := 1
      );
    port(
      clk   : in std_logic;
      reset : in std_logic;

      exec_first_cycle         : in std_logic;
      exec_first_column        : in std_logic;
      exec_last_cycle          : in std_logic;
      exec_last_cooldown_cycle : in std_logic;
      exec_read                : in std_logic;
      exec_write               : in std_logic;
      exec_we                  : in std_logic;
      exec_byteena             : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      exec_dest_addr           : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      instruction_pipeline     : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);

      data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

      accum_first_column : out std_logic;
      accum_byteena      : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      accum_dest_addr    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      exec_out           : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      accum_we           : out std_logic;

      mask_writedata_enables : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);

      vci_valid  : out std_logic_vector(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);
      vci_signed : out std_logic;
      vci_opsize : out std_logic_vector(1 downto 0);

      vci_vector_start : out std_logic;
      vci_vector_end   : out std_logic;
      vci_byte_valid   : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_dest_addr_in : out std_logic_vector(31 downto 0);

      vci_data_a : out std_logic_vector(VECTOR_LANES*32-1 downto 0);
      vci_flag_a : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_data_b : out std_logic_vector(VECTOR_LANES*32-1 downto 0);
      vci_flag_b : out std_logic_vector(VECTOR_LANES*4-1 downto 0);

      vci_port          : out unsigned(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0);
      vci_data_out      : in  std_logic_vector(VECTOR_LANES*32-1 downto 0);
      vci_flag_out      : in  std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_byteenable    : in  std_logic_vector(VECTOR_LANES*4-1 downto 0);
      vci_dest_addr_out : in  std_logic_vector(31 downto 0)
      );
  end component;

  component adder_tree_clk
    generic (
      WIDTH            : integer := 32;
      LEAVES           : integer := 8;
      BRANCHES_PER_CLK : integer := 2);
    port(
      clk : in std_logic;

      data_in  : in  std_logic_vector((WIDTH*LEAVES)-1 downto 0);
      data_out : out std_logic_vector(WIDTH-1 downto 0)
      );
  end component;

  component accum_unit
    generic (
      VECTOR_LANES : integer := 1;

      PIPELINE_STAGES   : integer := 1;
      ACCUM_DELAY       : integer := 1;
      STAGE_ACCUM_START : integer := 1;
      STAGE_ACCUM_END   : integer := 1;

      ADDR_WIDTH : integer := 1
      );
    port(
      clk   : in std_logic;
      reset : in std_logic;

      accum_first_column   : in std_logic;
      accum_byteena        : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      accum_dest_addr      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      accum_writedata      : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      accum_we             : in std_logic;
      instruction_pipeline : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);

      dest_byteena   : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
      dest_addr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      dest_writedata : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      dest_we        : out std_logic
      );
  end component;

  component sdp_ram is
    generic (
      AW : integer := 5;
      DW : integer := 32
      );
    port(
      clk   : in  std_logic;
      we    : in  std_logic;
      raddr : in  std_logic_vector(AW-1 downto 0);
      waddr : in  std_logic_vector(AW-1 downto 0);
      di    : in  std_logic_vector(DW-1 downto 0);
      do    : out std_logic_vector(DW-1 downto 0)
      );
  end component;

  component fifo_sync is
    generic (
      CFG_FAM      : config_family_type;
      C_IMPL_STYLE : integer := 0;
      WIDTH        : integer := 32;
      DEPTH        : integer := 16
      );
    port (
      reset : in std_logic;
      clk   : in std_logic;

      we       : in  std_logic;
      data_in  : in  std_logic_vector(WIDTH-1 downto 0);
      full     : out std_logic;
      rd       : in  std_logic;
      data_out : out std_logic_vector(WIDTH-1 downto 0);
      empty    : out std_logic
      );
  end component;

end package;

package body component_pkg is
end component_pkg;
