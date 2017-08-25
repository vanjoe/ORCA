library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.utils.all;
use work.constants_pkg.all;

package rv_components is
  component orca is
    generic (
      REGISTER_SIZE : positive range 32 to 32 := 32;

      --BUS Select
      AVALON_ENABLE   : integer range 0 to 1 := 0;
      WISHBONE_ENABLE : integer range 0 to 1 := 0;
      AXI_ENABLE      : integer range 0 to 1 := 0;

      RESET_VECTOR          : std_logic_vector(31 downto 0) := X"00000000";
      INTERRUPT_VECTOR      : std_logic_vector(31 downto 0) := X"00000200";
      MULTIPLY_ENABLE       : natural range 0 to 1          := 0;
      DIVIDE_ENABLE         : natural range 0 to 1          := 0;
      SHIFTER_MAX_CYCLES    : natural                       := 1;
      COUNTER_LENGTH        : natural                       := 0;
      ENABLE_EXCEPTIONS     : natural                       := 1;
      BRANCH_PREDICTORS     : natural                       := 0;
      PIPELINE_STAGES       : natural range 4 to 5          := 5;
      LVE_ENABLE            : natural range 0 to 1          := 0;
      ENABLE_EXT_INTERRUPTS : natural range 0 to 1          := 0;
      NUM_EXT_INTERRUPTS    : integer range 1 to 32         := 1;
      SCRATCHPAD_ADDR_BITS  : integer                       := 10;
      IUC_ADDR_BASE         : std_logic_vector(31 downto 0) := X"00000000";
      IUC_ADDR_LAST         : std_logic_vector(31 downto 0) := X"00000000";
      ICACHE_SIZE           : natural                       := 8192;
      ICACHE_LINE_SIZE      : integer range 16 to 256       := 32;
      ICACHE_EXTERNAL_WIDTH : integer                       := 32;
      ICACHE_BURST_EN       : integer range 0 to 1          := 0;
      POWER_OPTIMIZED       : integer range 0 to 1          := 0;
      FAMILY                : string                        := "ALTERA"
      );
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;

      -------------------------------------------------------------------------------
      --AVALON
      -------------------------------------------------------------------------------
      --Avalon data master
      avm_data_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_data_byteenable    : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      avm_data_read          : out std_logic;
      avm_data_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
      avm_data_write         : out std_logic;
      avm_data_writedata     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_data_waitrequest   : in  std_logic                                  := '0';
      avm_data_readdatavalid : in  std_logic                                  := '0';

      --Avalon instruction master
      avm_instruction_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_instruction_read          : out std_logic;
      avm_instruction_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
      avm_instruction_waitrequest   : in  std_logic                                  := '0';
      avm_instruction_readdatavalid : in  std_logic                                  := '0';

      -------------------------------------------------------------------------------
      --WISHBONE
      -------------------------------------------------------------------------------
      --WISHBONE data master
      data_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
      data_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_WE_O    : out std_logic;
      data_SEL_O   : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      data_STB_O   : out std_logic;
      data_ACK_I   : in  std_logic                                  := '0';
      data_CYC_O   : out std_logic;
      data_CTI_O   : out std_logic_vector(2 downto 0);
      data_STALL_I : in  std_logic                                  := '0';

      --WISHBONE instruction master
      instr_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
      instr_STB_O   : out std_logic;
      instr_ACK_I   : in  std_logic                                  := '0';
      instr_CYC_O   : out std_logic;
      instr_CTI_O   : out std_logic_vector(2 downto 0);
      instr_STALL_I : in  std_logic                                  := '0';

      -------------------------------------------------------------------------------
      --AXI
      -------------------------------------------------------------------------------
      --AXI4-Lite uncached data master
      --A full AXI3 interface is exposed for systems that require it, but
      --only the A4L signals are needed
      DUC_AWID    : out std_logic_vector(3 downto 0);
      DUC_AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      DUC_AWLEN   : out std_logic_vector(3 downto 0);
      DUC_AWSIZE  : out std_logic_vector(2 downto 0);
      DUC_AWBURST : out std_logic_vector(1 downto 0);
      DUC_AWLOCK  : out std_logic_vector(1 downto 0);
      DUC_AWCACHE : out std_logic_vector(3 downto 0);
      DUC_AWPROT  : out std_logic_vector(2 downto 0);
      DUC_AWVALID : out std_logic;
      DUC_AWREADY : in  std_logic := '0';

      DUC_WID    : out std_logic_vector(3 downto 0);
      DUC_WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      DUC_WSTRB  : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      DUC_WLAST  : out std_logic;
      DUC_WVALID : out std_logic;
      DUC_WREADY : in  std_logic := '0';

      DUC_BID    : in  std_logic_vector(3 downto 0) := (others => '0');
      DUC_BRESP  : in  std_logic_vector(1 downto 0) := (others => '0');
      DUC_BVALID : in  std_logic                    := '0';
      DUC_BREADY : out std_logic;

      DUC_ARID    : out std_logic_vector(3 downto 0);
      DUC_ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      DUC_ARLEN   : out std_logic_vector(3 downto 0);
      DUC_ARSIZE  : out std_logic_vector(2 downto 0);
      DUC_ARBURST : out std_logic_vector(1 downto 0);
      DUC_ARLOCK  : out std_logic_vector(1 downto 0);
      DUC_ARCACHE : out std_logic_vector(3 downto 0);
      DUC_ARPROT  : out std_logic_vector(2 downto 0);
      DUC_ARVALID : out std_logic;
      DUC_ARREADY : in  std_logic := '0';

      DUC_RID    : in  std_logic_vector(3 downto 0)               := (others => '0');
      DUC_RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
      DUC_RRESP  : in  std_logic_vector(1 downto 0)               := (others => '0');
      DUC_RLAST  : in  std_logic                                  := '0';
      DUC_RVALID : in  std_logic                                  := '0';
      DUC_RREADY : out std_logic;

      --AXI4-Lite uncached instruction master
      --A full AXI3 interface is exposed for systems that require it, but
      --only the A4L signals are needed
      IUC_ARID    : out std_logic_vector(3 downto 0);
      IUC_ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      IUC_ARLEN   : out std_logic_vector(3 downto 0);
      IUC_ARSIZE  : out std_logic_vector(2 downto 0);
      IUC_ARBURST : out std_logic_vector(1 downto 0);
      IUC_ARLOCK  : out std_logic_vector(1 downto 0);
      IUC_ARCACHE : out std_logic_vector(3 downto 0);
      IUC_ARPROT  : out std_logic_vector(2 downto 0);
      IUC_ARVALID : out std_logic;
      IUC_ARREADY : in  std_logic := '0';

      IUC_RID    : in  std_logic_vector(3 downto 0)               := (others => '0');
      IUC_RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
      IUC_RRESP  : in  std_logic_vector(1 downto 0)               := (others => '0');
      IUC_RLAST  : in  std_logic                                  := '0';
      IUC_RVALID : in  std_logic                                  := '0';
      IUC_RREADY : out std_logic;

      IUC_AWID    : out std_logic_vector(3 downto 0);
      IUC_AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      IUC_AWLEN   : out std_logic_vector(3 downto 0);
      IUC_AWSIZE  : out std_logic_vector(2 downto 0);
      IUC_AWBURST : out std_logic_vector(1 downto 0);
      IUC_AWLOCK  : out std_logic_vector(1 downto 0);
      IUC_AWCACHE : out std_logic_vector(3 downto 0);
      IUC_AWPROT  : out std_logic_vector(2 downto 0);
      IUC_AWVALID : out std_logic;
      IUC_AWREADY : in  std_logic := '0';

      IUC_WID    : out std_logic_vector(3 downto 0);
      IUC_WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      IUC_WSTRB  : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      IUC_WLAST  : out std_logic;
      IUC_WVALID : out std_logic;
      IUC_WREADY : in  std_logic := '0';

      IUC_BID    : in  std_logic_vector(3 downto 0) := (others => '0');
      IUC_BRESP  : in  std_logic_vector(1 downto 0) := (others => '0');
      IUC_BVALID : in  std_logic                    := '0';
      IUC_BREADY : out std_logic;

      --AXI3 cacheable instruction master
      IC_ARID    : out std_logic_vector(3 downto 0);
      IC_ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      IC_ARLEN   : out std_logic_vector(3 downto 0);
      IC_ARSIZE  : out std_logic_vector(2 downto 0);
      IC_ARBURST : out std_logic_vector(1 downto 0);
      IC_ARLOCK  : out std_logic_vector(1 downto 0);
      IC_ARCACHE : out std_logic_vector(3 downto 0);
      IC_ARPROT  : out std_logic_vector(2 downto 0);
      IC_ARVALID : out std_logic;
      IC_ARREADY : in  std_logic := '0';

      IC_RID    : in  std_logic_vector(3 downto 0)                       := (others => '0');
      IC_RDATA  : in  std_logic_vector(ICACHE_EXTERNAL_WIDTH-1 downto 0) := (others => '0');
      IC_RRESP  : in  std_logic_vector(1 downto 0)                       := (others => '0');
      IC_RLAST  : in  std_logic                                          := '0';
      IC_RVALID : in  std_logic                                          := '0';
      IC_RREADY : out std_logic;

      IC_AWID    : out std_logic_vector(3 downto 0);
      IC_AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      IC_AWLEN   : out std_logic_vector(3 downto 0);
      IC_AWSIZE  : out std_logic_vector(2 downto 0);
      IC_AWBURST : out std_logic_vector(1 downto 0);
      IC_AWLOCK  : out std_logic_vector(1 downto 0);
      IC_AWCACHE : out std_logic_vector(3 downto 0);
      IC_AWPROT  : out std_logic_vector(2 downto 0);
      IC_AWVALID : out std_logic;
      IC_AWREADY : in  std_logic := '0';

      IC_WID    : out std_logic_vector(3 downto 0);
      IC_WDATA  : out std_logic_vector(ICACHE_EXTERNAL_WIDTH-1 downto 0);
      IC_WSTRB  : out std_logic_vector((ICACHE_EXTERNAL_WIDTH/8)-1 downto 0);
      IC_WLAST  : out std_logic;
      IC_WVALID : out std_logic;
      IC_WREADY : in  std_logic                    := '0';
      IC_BID    : in  std_logic_vector(3 downto 0) := (others => '0');
      IC_BRESP  : in  std_logic_vector(1 downto 0) := (others => '0');
      IC_BVALID : in  std_logic                    := '0';
      IC_BREADY : out std_logic;

      -------------------------------------------------------------------------------
      -- Scratchpad Slave
      -------------------------------------------------------------------------------
      --Avalon scratchpad slave
      avm_scratch_address       : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0) := (others => '0');
      avm_scratch_byteenable    : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0)    := (others => '0');
      avm_scratch_read          : in  std_logic                                         := '0';
      avm_scratch_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_scratch_write         : in  std_logic                                         := '0';
      avm_scratch_writedata     : in  std_logic_vector(REGISTER_SIZE-1 downto 0)        := (others => '0');
      avm_scratch_waitrequest   : out std_logic;
      avm_scratch_readdatavalid : out std_logic;

      --WISHBONE scratchpad slave
      sp_ADR_I   : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0) := (others => '0');
      sp_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0)        := (others => '0');
      sp_WE_I    : in  std_logic                                         := '0';
      sp_SEL_I   : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0)    := (others => '0');
      sp_STB_I   : in  std_logic                                         := '0';
      sp_ACK_O   : out std_logic;
      sp_CYC_I   : in  std_logic                                         := '0';
      sp_CTI_I   : in  std_logic_vector(2 downto 0)                      := (others => '0');
      sp_STALL_O : out std_logic;

      -------------------------------------------------------------------------------
      -- Interrupts
      -------------------------------------------------------------------------------
      global_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0) := (others => '0')
      );
  end component orca;

  component orca_core is
    generic (
      REGISTER_SIZE      : integer;
      RESET_VECTOR       : std_logic_vector(31 downto 0);
      INTERRUPT_VECTOR   : std_logic_vector(31 downto 0);
      MULTIPLY_ENABLE    : natural range 0 to 1;
      DIVIDE_ENABLE      : natural range 0 to 1;
      SHIFTER_MAX_CYCLES : natural;
      POWER_OPTIMIZED    : natural range 0 to 1 := 0;
      COUNTER_LENGTH     : natural;
      ENABLE_EXCEPTIONS  : natural;
      BRANCH_PREDICTORS  : natural;
      PIPELINE_STAGES    : natural range 4 to 5;
      NUM_EXT_INTERRUPTS : integer range 0 to 32;
      LVE_ENABLE         : natural range 0 to 1;
      SCRATCHPAD_SIZE    : integer;
      FAMILY             : string
      );
    port(
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;

      --avalon master bus
      core_data_address              : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      core_data_byteenable           : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      core_data_read                 : out std_logic;
      core_data_readdata             : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => 'X');
      core_data_write                : out std_logic;
      core_data_writedata            : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      core_data_ack                  : in  std_logic                                  := '0';
      --avalon master bus
      core_instruction_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      core_instruction_read          : out std_logic;
      core_instruction_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => 'X');
      core_instruction_waitrequest   : in  std_logic                                  := '0';
      core_instruction_readdatavalid : in  std_logic                                  := '0';

      --memory-bus scratchpad-slave
      sp_address   : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
      sp_byte_en   : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      sp_write_en  : in  std_logic;
      sp_read_en   : in  std_logic;
      sp_writedata : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_readdata  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_ack       : out std_logic;

      external_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0) := (others => '0')
      );
  end component orca_core;

  component decode is
    generic(
      REGISTER_SIZE       : positive;
      SIGN_EXTENSION_SIZE : positive;
      PIPELINE_STAGES     : natural range 1 to 2;
      FAMILY              : string := "ALTERA"
      );
    port(
      clk   : in std_logic;
      reset : in std_logic;
      stall : in std_logic;

      flush       : in std_logic;
      instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      valid_input : in std_logic;
      --writeback signals
      wb_sel      : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      wb_data     : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      wb_enable   : in std_logic;

      --output signals
      rs1_data       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      sign_extension : out    std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      --inputs just for carrying to next pipeline stage
      br_taken_in    : in     std_logic;
      pc_curr_in     : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      br_taken_out   : out    std_logic;
      pc_curr_out    : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_out      : buffer std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      subseq_instr   : out    std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      subseq_valid   : out    std_logic;
      valid_output   : out    std_logic;
      decode_flushed : out    std_logic
      );
  end component decode;

  component execute is
    generic(
      REGISTER_SIZE       : positive;
      SIGN_EXTENSION_SIZE : positive;
      INTERRUPT_VECTOR    : std_logic_vector(31 downto 0);
      POWER_OPTIMIZED     : boolean;
      MULTIPLY_ENABLE     : boolean;
      DIVIDE_ENABLE       : boolean;
      SHIFTER_MAX_CYCLES  : natural;
      COUNTER_LENGTH      : natural;
      ENABLE_EXCEPTIONS   : boolean;
      SCRATCHPAD_SIZE     : integer;
      FAMILY              : string
      );
    port(
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;
      valid_input    : in std_logic;

      br_taken_in  : in std_logic;
      pc_current   : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction  : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      subseq_instr : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      subseq_valid : in std_logic;

      rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      sign_extension : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

      wb_sel    : buffer std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      wb_data   : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
      wb_enable : buffer std_logic;

      branch_pred        : out    std_logic_vector((REGISTER_SIZE*2)+3-1 downto 0);
      stall_from_execute : buffer std_logic;

      --memory-bus master
      address   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      byte_en   : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      write_en  : out std_logic;
      read_en   : out std_logic;
      writedata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      readdata  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_ack  : in  std_logic;

      --memory-bus scratchpad-slave
      sp_address   : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
      sp_byte_en   : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      sp_write_en  : in  std_logic;
      sp_read_en   : in  std_logic;
      sp_writedata : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_readdata  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_ack       : out std_logic;

      external_interrupts : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      pipeline_empty      : in     std_logic;
      ifetch_next_pc      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      fetch_in_flight     : in     std_logic;
      interrupt_pending   : buffer std_logic
      );
  end component execute;

  component instruction_fetch is
    generic (
      REGISTER_SIZE     : positive;
      RESET_VECTOR      : std_logic_vector(31 downto 0);
      BRANCH_PREDICTORS : natural
      );
    port (
      clk                : in std_logic;
      reset              : in std_logic;
      downstream_stalled : in std_logic;
      interrupt_pending  : in std_logic;
      branch_pred        : in std_logic_vector((REGISTER_SIZE*2)+3-1 downto 0);

      br_taken        : buffer std_logic;
      instr_out       : out    std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      pc_out          : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      next_pc_out     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      valid_instr_out : out    std_logic;
      fetch_in_flight : out    std_logic;

      read_address   : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      read_en        : buffer std_logic;
      read_data      : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      read_datavalid : in     std_logic;
      read_wait      : in     std_logic
      );
  end component instruction_fetch;

  component arithmetic_unit is
    generic (
      REGISTER_SIZE       : integer;
      SIMD_ENABLE         : boolean;
      SIGN_EXTENSION_SIZE : integer;
      MULTIPLY_ENABLE     : boolean;
      POWER_OPTIMIZED     : boolean;
      DIVIDE_ENABLE       : boolean;
      SHIFTER_MAX_CYCLES  : natural;
      FAMILY              : string := "ALTERA"
      );
    port (
      clk                : in  std_logic;
      valid_instr        : in  std_logic;
      stall_to_alu       : in  std_logic;
      simd_op_size       : in  std_logic_vector(1 downto 0);
      stall_from_execute : in  std_logic;
      rs1_data           : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data           : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction        : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension     : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      program_counter    : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_out           : out std_logic_vector(REGISTER_SIZE-1 downto 0);

      data_out_valid : out std_logic;
      less_than      : out std_logic;
      stall_from_alu : out std_logic;

      lve_data1        : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_data2        : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_source_valid : in std_logic
      );
  end component arithmetic_unit;

  component branch_unit is
    generic (
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer);
    port (
      clk            : in  std_logic;
      stall          : in  std_logic;
      valid          : in  std_logic;
      reset          : in  std_logic;
      rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      current_pc     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      br_taken_in    : in  std_logic;
      instr          : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      less_than      : in  std_logic;
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable    : out std_logic;
      is_branch      : out std_logic;
      br_taken_out   : out std_logic;
      new_pc         : out std_logic_vector(REGISTER_SIZE-1 downto 0);  --next pc
      bad_predict    : out std_logic
      );
  end component branch_unit;

  component load_store_unit is
    generic (
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer
      );
    port (
      clk            : in     std_logic;
      reset          : in     std_logic;
      valid          : in     std_logic;
      stall_to_lsu   : in     std_logic;
      rs1_data       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction    : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      stalled        : buffer std_logic;
      data_out       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable    : out    std_logic;
      --memory-bus
      address        : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      byte_en        : out    std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      write_en       : buffer std_logic;
      read_en        : buffer std_logic;
      write_data     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      read_data      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      ack            : in     std_logic
      );
  end component load_store_unit;

  component register_file
    generic(
      REGISTER_SIZE      : positive;
      REGISTER_NAME_SIZE : positive
      );
    port(
      clk         : in std_logic;
      valid_input : in std_logic;
      rs1_sel     : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      rs2_sel     : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      wb_sel      : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      wb_data     : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      wb_enable   : in std_logic;

      rs1_data : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data : buffer std_logic_vector(REGISTER_SIZE-1 downto 0)
      );
  end component register_file;

  component system_calls is
    generic (
      REGISTER_SIZE     : natural;
      INTERRUPT_VECTOR  : std_logic_vector(31 downto 0);
      ENABLE_EXCEPTIONS : boolean := true;
      COUNTER_LENGTH    : natural
      );
    port (
      clk         : in  std_logic;
      reset       : in  std_logic;
      valid       : in  std_logic;
      stall_in    : in  std_logic;
      stall_out   : out std_logic;
      rs1_data    : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

      data_out    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable : out std_logic;

      current_pc    : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      pc_correction : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      pc_corr_en    : buffer std_logic;

      -- The interrupt_pending signal goes to the Instruction Fetch stage.
      interrupt_pending   : buffer std_logic;
      external_interrupts : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      -- Signals when an interrupt may proceed.
      pipeline_empty      : in     std_logic;

      -- These signals are used to tell the interrupt handler which instruction
      -- to return to upon exit. They are sourced from the instruction fetch
      -- stage of the processor.
      instruction_fetch_pc : in std_logic_vector(REGISTER_SIZE-1 downto 0);

      br_bad_predict : in std_logic;
      br_new_pc      : in std_logic_vector(REGISTER_SIZE-1 downto 0)
      );
  end component system_calls;

  component lve_ci is
    generic (
      REGISTER_SIZE : positive := 32
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      pause : in std_logic;

      func3 : in std_logic_vector(2 downto 0);

      valid_in : in std_logic;
      data1_in : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      data2_in : in std_logic_vector(REGISTER_SIZE-1 downto 0);

      align1_in : in std_logic_vector(1 downto 0);
      align2_in : in std_logic_vector(1 downto 0);

      valid_out        : out std_logic;
      write_enable_out : out std_logic;
      data_out         : out std_logic_vector(REGISTER_SIZE-1 downto 0)
      );
  end component lve_ci;

  component lve_top is
    generic (
      REGISTER_SIZE    : natural;
      SLAVE_DATA_WIDTH : natural := 32;
      POWER_OPTIMIZED  : boolean;
      SCRATCHPAD_SIZE  : integer := 1024;
      FAMILY           : string  := "ALTERA"
      );
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;
      instruction    : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      valid_instr    : in std_logic;
      stall_to_lve   : in std_logic;
      rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);

      slave_address  : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
      slave_read_en  : in  std_logic;
      slave_write_en : in  std_logic;
      slave_byte_en  : in  std_logic_vector((SLAVE_DATA_WIDTH/8)-1 downto 0);
      slave_data_in  : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
      slave_data_out : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
      slave_ack      : out std_logic;

      lve_executing        : out    std_logic;
      lve_alu_data1        : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_alu_data2        : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_alu_op_size      : out    std_logic_vector(1 downto 0);
      lve_alu_source_valid : out    std_logic;
      lve_alu_result       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_alu_result_valid : in     std_logic
      );
  end component;

  component ram_mux is
    generic (
      DATA_WIDTH : natural := 32;
      ADDR_WIDTH : natural := 32
      );
    port (
      -- init signals
      nvm_addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      nvm_wdata    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      nvm_wen      : in  std_logic;
      nvm_byte_sel : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      nvm_strb     : in  std_logic;
      nvm_ack      : out std_logic;
      nvm_rdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);

      -- user signals
      user_ARREADY : out std_logic;
      user_ARADDR  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      user_ARVALID : in  std_logic;

      user_RREADY : out std_logic;
      user_RDATA  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      user_RVALID : out std_logic;

      user_AWADDR  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      user_AWVALID : in  std_logic;
      user_AWREADY : out std_logic;

      user_WDATA  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      user_WVALID : in  std_logic;
      user_WREADY : out std_logic;

      user_BREADY : in  std_logic;
      user_BVALID : out std_logic;

      -- mux signals/ram inputs
      SEL          : in  std_logic;
      ram_addr     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      ram_wdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
      ram_wen      : out std_logic;
      ram_byte_sel : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
      ram_strb     : out std_logic;
      ram_ack      : in  std_logic;
      ram_rdata    : in  std_logic_vector(DATA_WIDTH-1 downto 0)
      );
  end component;

  component idram is
    generic (
      --Port types: 0 = AXI4Lite, 1 = AXI3, 2 = AXI4
      INSTR_PORT_TYPE : natural range 0 to 2 := 0;
      DATA_PORT_TYPE  : natural range 0 to 2 := 0;
      SIZE            : integer              := 32768;
      RAM_WIDTH       : integer              := 32;
      ADDR_WIDTH      : integer              := 32;
      BYTE_SIZE       : integer              := 8
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      instr_AWID    : in std_logic_vector(13 downto 0);
      instr_AWADDR  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      instr_AWLEN   : in std_logic_vector(7-(4*(INSTR_PORT_TYPE mod 2)) downto 0);
      instr_AWSIZE  : in std_logic_vector(2 downto 0);
      instr_AWBURST : in std_logic_vector(1 downto 0);

      instr_AWLOCK  : in  std_logic_vector(1 downto 0);
      instr_AWCACHE : in  std_logic_vector(3 downto 0);
      instr_AWPROT  : in  std_logic_vector(2 downto 0);
      instr_AWVALID : in  std_logic;
      instr_AWREADY : out std_logic;

      instr_WID    : in  std_logic_vector(13 downto 0);
      instr_WDATA  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      instr_WSTRB  : in  std_logic_vector((RAM_WIDTH/BYTE_SIZE)-1 downto 0);
      instr_WLAST  : in  std_logic;
      instr_WVALID : in  std_logic;
      instr_WREADY : out std_logic;

      instr_BID    : out std_logic_vector(13 downto 0);
      instr_BRESP  : out std_logic_vector(1 downto 0);
      instr_BVALID : out std_logic;
      instr_BREADY : in  std_logic;

      instr_ARID    : in  std_logic_vector(13 downto 0);
      instr_ARADDR  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      instr_ARLEN   : in  std_logic_vector(7-(4*(INSTR_PORT_TYPE mod 2)) downto 0);
      instr_ARSIZE  : in  std_logic_vector(2 downto 0);
      instr_ARBURST : in  std_logic_vector(1 downto 0);
      instr_ARLOCK  : in  std_logic_vector(1 downto 0);
      instr_ARCACHE : in  std_logic_vector(3 downto 0);
      instr_ARPROT  : in  std_logic_vector(2 downto 0);
      instr_ARVALID : in  std_logic;
      instr_ARREADY : out std_logic;

      instr_RID    : out std_logic_vector(13 downto 0);
      instr_RDATA  : out std_logic_vector(RAM_WIDTH-1 downto 0);
      instr_RRESP  : out std_logic_vector(1 downto 0);
      instr_RLAST  : out std_logic;
      instr_RVALID : out std_logic;
      instr_RREADY : in  std_logic;

      data_AWID    : in std_logic_vector(13 downto 0);
      data_AWADDR  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_AWLEN   : in std_logic_vector(7-(4*(DATA_PORT_TYPE mod 2)) downto 0);
      data_AWSIZE  : in std_logic_vector(2 downto 0);
      data_AWBURST : in std_logic_vector(1 downto 0);

      data_AWLOCK  : in  std_logic_vector(1 downto 0);
      data_AWCACHE : in  std_logic_vector(3 downto 0);
      data_AWPROT  : in  std_logic_vector(2 downto 0);
      data_AWVALID : in  std_logic;
      data_AWREADY : out std_logic;

      data_WID    : in  std_logic_vector(13 downto 0);
      data_WDATA  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      data_WSTRB  : in  std_logic_vector((RAM_WIDTH/BYTE_SIZE)-1 downto 0);
      data_WLAST  : in  std_logic;
      data_WVALID : in  std_logic;
      data_WREADY : out std_logic;

      data_BID    : out std_logic_vector(13 downto 0);
      data_BRESP  : out std_logic_vector(1 downto 0);
      data_BVALID : out std_logic;
      data_BREADY : in  std_logic;

      data_ARID    : in  std_logic_vector(13 downto 0);
      data_ARADDR  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_ARLEN   : in  std_logic_vector(7-(4*(DATA_PORT_TYPE mod 2)) downto 0);
      data_ARSIZE  : in  std_logic_vector(2 downto 0);
      data_ARBURST : in  std_logic_vector(1 downto 0);
      data_ARLOCK  : in  std_logic_vector(1 downto 0);
      data_ARCACHE : in  std_logic_vector(3 downto 0);
      data_ARPROT  : in  std_logic_vector(2 downto 0);
      data_ARVALID : in  std_logic;
      data_ARREADY : out std_logic;

      data_RID    : out std_logic_vector(13 downto 0);
      data_RDATA  : out std_logic_vector(RAM_WIDTH-1 downto 0);
      data_RRESP  : out std_logic_vector(1 downto 0);
      data_RLAST  : out std_logic;
      data_RVALID : out std_logic;
      data_RREADY : in  std_logic
      );
  end component;

  component bram_microsemi is
    generic (
      RAM_DEPTH : integer := 1024;      -- this is the maximum
      RAM_WIDTH : integer := 32;
      BYTE_SIZE : integer := 8
      );
    port (
      clk : in std_logic;

      address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      we       : in  std_logic;
      be       : in  std_logic_vector((RAM_WIDTH/BYTE_SIZE)-1 downto 0);
      readdata : out std_logic_vector(RAM_WIDTH-1 downto 0);

      data_address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      data_data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      data_we       : in  std_logic;
      data_be       : in  std_logic_vector((RAM_WIDTH/BYTE_SIZE)-1 downto 0);
      data_readdata : out std_logic_vector(RAM_WIDTH-1 downto 0)
      );
  end component;

  component a4l_master is
    generic (
      ADDR_WIDTH    : integer := 32;
      REGISTER_SIZE : integer := 32;
      BYTE_SIZE     : integer := 8
      );
    port (
      clk     : in std_logic;
      aresetn : in std_logic;

      core_data_address    : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      core_data_byteenable : in  std_logic_vector((REGISTER_SIZE/BYTE_SIZE)-1 downto 0);
      core_data_read       : in  std_logic;
      core_data_readdata   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      core_data_write      : in  std_logic;
      core_data_writedata  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      core_data_ack        : out std_logic;

      AWADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      AWPROT  : out std_logic_vector(2 downto 0);
      AWVALID : out std_logic;
      AWREADY : in  std_logic;

      WSTRB  : out std_logic_vector((REGISTER_SIZE/BYTE_SIZE)-1 downto 0);
      WVALID : out std_logic;
      WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      WREADY : in  std_logic;

      BRESP  : in  std_logic_vector(1 downto 0);
      BVALID : in  std_logic;
      BREADY : out std_logic;

      ARADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      ARPROT  : out std_logic_vector(2 downto 0);
      ARVALID : out std_logic;
      ARREADY : in  std_logic;

      RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      RRESP  : in  std_logic_vector(1 downto 0);
      RVALID : in  std_logic;
      RREADY : out std_logic
      );
  end component a4l_master;

  component a4l_instruction_master is
    generic (
      REGISTER_SIZE : integer := 32;
      BYTE_SIZE     : integer := 8
      );
    port (
      clk     : in std_logic;
      aresetn : in std_logic;

      core_instruction_address       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      core_instruction_read          : in  std_logic;
      core_instruction_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      core_instruction_readdatavalid : out std_logic;
      core_instruction_write         : in  std_logic;
      core_instruction_writedata     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      core_instruction_waitrequest   : out std_logic;

      AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      AWPROT  : out std_logic_vector(2 downto 0);
      AWVALID : out std_logic;
      AWREADY : in  std_logic;

      WSTRB  : out std_logic_vector((REGISTER_SIZE/BYTE_SIZE)-1 downto 0);
      WVALID : out std_logic;
      WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      WREADY : in  std_logic;

      BRESP  : in  std_logic_vector(1 downto 0);
      BVALID : in  std_logic;
      BREADY : out std_logic;

      ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      ARPROT  : out std_logic_vector(2 downto 0);
      ARVALID : out std_logic;
      ARREADY : in  std_logic;

      RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      RRESP  : in  std_logic_vector(1 downto 0);
      RVALID : in  std_logic;
      RREADY : out std_logic
      );
  end component a4l_instruction_master;

  component ram_4port is
    generic (
      MEM_DEPTH       : natural;
      MEM_WIDTH       : natural;
      POWER_OPTIMIZED : boolean;
      FAMILY          : string := "ALTERA"
      );
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;

      pause_lve_in  : in  std_logic;
      pause_lve_out : out std_logic;
                                        --read source A
      raddr0        : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      ren0          : in  std_logic;
      scalar_value  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      scalar_enable : in  std_logic;
      data_out0     : out std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --read source B
      raddr1        : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      ren1          : in  std_logic;
      enum_value    : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      enum_enable   : in  std_logic;
      data_out1     : out std_logic_vector(MEM_WIDTH-1 downto 0);
      ack01         : out std_logic;
                                        --write dest
      waddr2        : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      byte_en2      : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      wen2          : in  std_logic;
      data_in2      : in  std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --external slave port
      rwaddr3       : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      wen3          : in  std_logic;
      ren3          : in  std_logic;    --cannot be asserted same cycle as wen3
      byte_en3      : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      data_in3      : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      ack3          : out std_logic;
      data_out3     : out std_logic_vector(MEM_WIDTH-1 downto 0)
      );
  end component;

  component idram_xilinx is
    generic (
      RAM_DEPTH : integer := 1024;
      RAM_WIDTH : integer := 32;
      BYTE_SIZE : integer := 8
      );
    port (
      clk : in std_logic;

      instr_address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      instr_data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      instr_we       : in  std_logic;
      instr_en       : in  std_logic;
      instr_be       : in  std_logic_vector((RAM_WIDTH/BYTE_SIZE)-1 downto 0);
      instr_readdata : out std_logic_vector(RAM_WIDTH-1 downto 0);

      data_address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      data_data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      data_we       : in  std_logic;
      data_en       : in  std_logic;
      data_be       : in  std_logic_vector((RAM_WIDTH/BYTE_SIZE)-1 downto 0);
      data_readdata : out std_logic_vector(RAM_WIDTH-1 downto 0)
      );
  end component;

  component bram_xilinx is
    generic (
      RAM_DEPTH : integer := 1024;
      RAM_WIDTH : integer := 8
      );
    port (
      address_a  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      address_b  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      clk        : in  std_logic;
      data_a     : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      data_b     : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      wren_a     : in  std_logic;
      wren_b     : in  std_logic;
      en_a       : in  std_logic;
      en_b       : in  std_logic;
      readdata_a : out std_logic_vector(RAM_WIDTH-1 downto 0);
      readdata_b : out std_logic_vector(RAM_WIDTH-1 downto 0)
      );
  end component;

  component bram_tdp_behav is
    generic (
      RAM_DEPTH : integer := 1024;
      RAM_WIDTH : integer := 8
      );
    port (
      address_a  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      address_b  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      clk        : in  std_logic;
      data_a     : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      data_b     : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      wren_a     : in  std_logic;
      wren_b     : in  std_logic;
      readdata_a : out std_logic_vector(RAM_WIDTH-1 downto 0);
      readdata_b : out std_logic_vector(RAM_WIDTH-1 downto 0)
      );
  end component;

  component icache is
    generic (
      CACHE_SIZE     : natural                  := 32768;  -- Byte size of cache
      LINE_SIZE      : positive range 16 to 256 := 32;  -- Bytes per cache line 
      ADDR_WIDTH     : integer                  := 32;
      ORCA_WIDTH     : integer                  := 32;
      EXTERNAL_WIDTH : integer                  := 32;
      BYTE_SIZE      : integer                  := 8;
      BURST_EN       : integer                  := 0;
      FAMILY         : string                   := "ALTERA"
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      orca_AWID    : in  std_logic_vector(3 downto 0);
      orca_AWADDR  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      orca_AWPROT  : in  std_logic_vector(2 downto 0);
      orca_AWVALID : in  std_logic;
      orca_AWREADY : out std_logic;

      orca_WID    : in  std_logic_vector(3 downto 0);
      orca_WDATA  : in  std_logic_vector(ORCA_WIDTH-1 downto 0);
      orca_WSTRB  : in  std_logic_vector((ORCA_WIDTH/BYTE_SIZE)-1 downto 0);
      orca_WVALID : in  std_logic;
      orca_WREADY : out std_logic;

      orca_BID    : out std_logic_vector(3 downto 0);
      orca_BRESP  : out std_logic_vector(1 downto 0);
      orca_BVALID : out std_logic;
      orca_BREADY : in  std_logic;

      orca_ARID    : in  std_logic_vector(3 downto 0);
      orca_ARADDR  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      orca_ARPROT  : in  std_logic_vector(2 downto 0);
      orca_ARVALID : in  std_logic;
      orca_ARREADY : out std_logic;

      orca_RID    : out std_logic_vector(3 downto 0);
      orca_RDATA  : out std_logic_vector(ORCA_WIDTH-1 downto 0);
      orca_RRESP  : out std_logic_vector(1 downto 0);
      orca_RVALID : out std_logic;
      orca_RREADY : in  std_logic;

      dram_AWID    : out std_logic_vector(3 downto 0);
      dram_AWADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      dram_AWLEN   : out std_logic_vector(3 downto 0);
      dram_AWSIZE  : out std_logic_vector(2 downto 0);
      dram_AWBURST : out std_logic_vector(1 downto 0);

      dram_AWLOCK  : out std_logic_vector(1 downto 0);
      dram_AWCACHE : out std_logic_vector(3 downto 0);
      dram_AWPROT  : out std_logic_vector(2 downto 0);
      dram_AWVALID : out std_logic;
      dram_AWREADY : in  std_logic;

      dram_WID    : out std_logic_vector(3 downto 0);
      dram_WDATA  : out std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
      dram_WSTRB  : out std_logic_vector((EXTERNAL_WIDTH/BYTE_SIZE)-1 downto 0);
      dram_WLAST  : out std_logic;
      dram_WVALID : out std_logic;
      dram_WREADY : in  std_logic;

      dram_BID    : in  std_logic_vector(3 downto 0);
      dram_BRESP  : in  std_logic_vector(1 downto 0);
      dram_BVALID : in  std_logic;
      dram_BREADY : out std_logic;

      dram_ARID    : out std_logic_vector(3 downto 0);
      dram_ARADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      dram_ARLEN   : out std_logic_vector(3 downto 0);
      dram_ARSIZE  : out std_logic_vector(2 downto 0);
      dram_ARBURST : out std_logic_vector(1 downto 0);
      dram_ARLOCK  : out std_logic_vector(1 downto 0);
      dram_ARCACHE : out std_logic_vector(3 downto 0);
      dram_ARPROT  : out std_logic_vector(2 downto 0);
      dram_ARVALID : out std_logic;
      dram_ARREADY : in  std_logic;

      dram_RID    : in  std_logic_vector(3 downto 0);
      dram_RDATA  : in  std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
      dram_RRESP  : in  std_logic_vector(1 downto 0);
      dram_RLAST  : in  std_logic;
      dram_RVALID : in  std_logic;
      dram_RREADY : out std_logic
      );
  end component icache;

  component cache is
    generic (
      NUM_LINES   : integer := 1;
      LINE_SIZE   : integer := 64;      -- In bytes
      BYTE_SIZE   : integer := 8;
      ADDR_WIDTH  : integer := 32;
      READ_WIDTH  : integer := 32;
      WRITE_WIDTH : integer := 32
      );
    port (
      clk : in std_logic;

      read_address  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      read_data_in  : in  std_logic_vector(READ_WIDTH-1 downto 0);
      read_valid_in : in  std_logic;
      read_we       : in  std_logic;
      read_readdata : out std_logic_vector(READ_WIDTH-1 downto 0);
      read_hit      : out std_logic;

      write_address  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      write_data_in  : in  std_logic_vector(WRITE_WIDTH-1 downto 0);
      write_valid_in : in  std_logic;
      write_we       : in  std_logic;
      write_readdata : out std_logic_vector(WRITE_WIDTH-1 downto 0);
      write_hit      : out std_logic;

      write_tag_valid_in : in std_logic;
      write_tag_valid_en : in std_logic
      );
  end component;

  component cache_mux is
    generic (
      UC_ADDR_BASE  : std_logic_vector(31 downto 0);
      UC_ADDR_LAST  : std_logic_vector(31 downto 0);
      ADDR_WIDTH    : integer := 32;
      REGISTER_SIZE : integer := 32;
      BYTE_SIZE     : integer := 8
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      in_AWID   : in std_logic_vector(3 downto 0);
      in_AWADDR : in std_logic_vector(ADDR_WIDTH-1 downto 0);

      in_AWPROT  : in     std_logic_vector(2 downto 0);
      in_AWVALID : in     std_logic;
      in_AWREADY : buffer std_logic;

      in_WID    : in     std_logic_vector(3 downto 0);
      in_WDATA  : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      in_WSTRB  : in     std_logic_vector((REGISTER_SIZE/BYTE_SIZE)-1 downto 0);
      in_WVALID : in     std_logic;
      in_WREADY : buffer std_logic;

      in_BID    : out    std_logic_vector(3 downto 0);
      in_BRESP  : out    std_logic_vector(1 downto 0);
      in_BVALID : buffer std_logic;
      in_BREADY : in     std_logic;

      in_ARID    : in     std_logic_vector(3 downto 0);
      in_ARADDR  : in     std_logic_vector(ADDR_WIDTH-1 downto 0);
      in_ARPROT  : in     std_logic_vector(2 downto 0);
      in_ARVALID : in     std_logic;
      in_ARREADY : buffer std_logic;

      in_RID    : out    std_logic_vector(3 downto 0);
      in_RDATA  : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      in_RRESP  : out    std_logic_vector(1 downto 0);
      in_RVALID : buffer std_logic;
      in_RREADY : in     std_logic;

      cache_AWID   : out std_logic_vector(3 downto 0);
      cache_AWADDR : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      cache_AWPROT  : out std_logic_vector(2 downto 0);
      cache_AWVALID : out std_logic;
      cache_AWREADY : in  std_logic;

      cache_WID    : out std_logic_vector(3 downto 0);
      cache_WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      cache_WSTRB  : out std_logic_vector((REGISTER_SIZE/BYTE_SIZE)-1 downto 0);
      cache_WVALID : out std_logic;
      cache_WREADY : in  std_logic;

      cache_BID    : in  std_logic_vector(3 downto 0);
      cache_BRESP  : in  std_logic_vector(1 downto 0);
      cache_BVALID : in  std_logic;
      cache_BREADY : out std_logic;

      cache_ARID    : out std_logic_vector(3 downto 0);
      cache_ARADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      cache_ARPROT  : out std_logic_vector(2 downto 0);
      cache_ARVALID : out std_logic;
      cache_ARREADY : in  std_logic;

      cache_RID    : in  std_logic_vector(3 downto 0);
      cache_RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      cache_RRESP  : in  std_logic_vector(1 downto 0);
      cache_RVALID : in  std_logic;
      cache_RREADY : out std_logic;

      uc_AWADDR : out std_logic_vector(ADDR_WIDTH-1 downto 0);

      uc_AWPROT  : out std_logic_vector(2 downto 0);
      uc_AWVALID : out std_logic;
      uc_AWREADY : in  std_logic;

      uc_WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      uc_WSTRB  : out std_logic_vector((REGISTER_SIZE/BYTE_SIZE)-1 downto 0);
      uc_WVALID : out std_logic;
      uc_WREADY : in  std_logic;

      uc_BRESP  : in  std_logic_vector(1 downto 0);
      uc_BVALID : in  std_logic;
      uc_BREADY : out std_logic;

      uc_ARADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      uc_ARPROT  : out std_logic_vector(2 downto 0);
      uc_ARVALID : out std_logic;
      uc_ARREADY : in  std_logic;

      uc_RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      uc_RRESP  : in  std_logic_vector(1 downto 0);
      uc_RVALID : in  std_logic;
      uc_RREADY : out std_logic
      );
  end component;

end package rv_components;
