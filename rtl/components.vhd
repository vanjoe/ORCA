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
      DATA_REQUEST_REGISTER : natural range 0 to 2          := 1;
      DATA_RETURN_REGISTER  : natural range 0 to 1          := 0;
      LVE_ENABLE            : natural range 0 to 1          := 0;
      ENABLE_EXT_INTERRUPTS : natural range 0 to 1          := 0;
      NUM_EXT_INTERRUPTS    : integer range 1 to 32         := 1;
      SCRATCHPAD_ADDR_BITS  : integer                       := 10;
      IUC_ADDR_BASE         : std_logic_vector(31 downto 0) := X"00000000";
      IUC_ADDR_LAST         : std_logic_vector(31 downto 0) := X"00000000";
      ICACHE_SIZE           : natural                       := 0;
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

  component memory_interface is
    generic (
      REGISTER_SIZE        : positive range 32 to 32 := 32;
      SCRATCHPAD_ADDR_BITS : positive                := 10;

      --BUS Select
      AVALON_ENABLE   : integer range 0 to 1 := 0;
      WISHBONE_ENABLE : integer range 0 to 1 := 0;
      AXI_ENABLE      : integer range 0 to 1 := 0;

      WISHBONE_SINGLE_CYCLE_READS : natural range 0 to 1          := 0;
      DATA_REQUEST_REGISTER       : natural range 0 to 2          := 1;
      DATA_RETURN_REGISTER        : natural range 0 to 1          := 0;
      IUC_ADDR_BASE               : std_logic_vector(31 downto 0) := X"00000000";
      IUC_ADDR_LAST               : std_logic_vector(31 downto 0) := X"00000000";
      ICACHE_SIZE                 : natural                       := 8192;
      ICACHE_LINE_SIZE            : integer range 16 to 256       := 32;
      ICACHE_EXTERNAL_WIDTH       : integer                       := 32;
      ICACHE_MAX_BURSTLENGTH      : positive                      := 16;
      ICACHE_BURST_EN             : integer range 0 to 1          := 0
      );
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;

      --Instruction Orca-internal memory-mapped master
      ifetch_oimm_address       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      ifetch_oimm_requestvalid  : in     std_logic;
      ifetch_oimm_readnotwrite  : in     std_logic;
      ifetch_oimm_readdata      : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      ifetch_oimm_waitrequest   : buffer std_logic;
      ifetch_oimm_readdatavalid : buffer std_logic;

      --Data Orca-internal memory-mapped master
      lsu_oimm_address       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_byteenable    : in     std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      lsu_oimm_requestvalid  : in     std_logic;
      lsu_oimm_readnotwrite  : in     std_logic;
      lsu_oimm_writedata     : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdata      : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdatavalid : out    std_logic;
      lsu_oimm_waitrequest   : buffer std_logic;

      --Scratchpad memory-mapped slave
      sp_address   : out    std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
      sp_byte_en   : out    std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      sp_write_en  : out    std_logic;
      sp_read_en   : buffer std_logic;
      sp_writedata : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_readdata  : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_ack       : in     std_logic;

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
      sp_STALL_O : out std_logic
      );
  end component;

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

      --Instruction Orca-internal memory-mapped master
      ifetch_oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      ifetch_oimm_requestvalid  : buffer std_logic;
      ifetch_oimm_readnotwrite  : out    std_logic;
      ifetch_oimm_readdata      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      ifetch_oimm_waitrequest   : in     std_logic;
      ifetch_oimm_readdatavalid : in     std_logic;

      --Data Orca-internal memory-mapped master
      lsu_oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_byteenable    : out    std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      lsu_oimm_requestvalid  : buffer std_logic;
      lsu_oimm_readnotwrite  : buffer std_logic;
      lsu_oimm_writedata     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdata      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdatavalid : in     std_logic;
      lsu_oimm_waitrequest   : in     std_logic;

      --Scratchpad memory-mapped slave
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
      LVE_ENABLE          : natural;
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

      --Data Orca-internal memory-mapped master
      lsu_oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_byteenable    : out    std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      lsu_oimm_requestvalid  : buffer std_logic;
      lsu_oimm_readnotwrite  : buffer std_logic;
      lsu_oimm_writedata     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdata      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdatavalid : in     std_logic;
      lsu_oimm_waitrequest   : in     std_logic;

      --Scratchpad memory-mapped slave
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

      --Orca-internal memory-mapped master
      oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      oimm_readnotwrite  : out    std_logic;
      oimm_requestvalid  : buffer std_logic;
      oimm_readdata      : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      oimm_readdatavalid : in     std_logic;
      oimm_waitrequest   : in     std_logic
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
      clk   : in std_logic;
      reset : in std_logic;

      valid                    : in     std_logic;
      rs1_data                 : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data                 : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction              : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension           : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      writeback_stall_from_lsu : buffer std_logic;
      stall_from_lsu           : out    std_logic;
      data_out                 : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable              : out    std_logic;

      --Orca-internal memory-mapped master
      oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      oimm_byteenable    : out    std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      oimm_requestvalid  : buffer std_logic;
      oimm_readnotwrite  : buffer std_logic;
      oimm_writedata     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      oimm_readdata      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      oimm_readdatavalid : in     std_logic;
      oimm_waitrequest   : in     std_logic
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
      POWER_OPTIMIZED   : boolean;
      ENABLE_EXCEPTIONS : boolean := true;
      COUNTER_LENGTH    : natural
      );
    port (
      clk         : in  std_logic;
      reset       : in  std_logic;
      valid       : in  std_logic;
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

  component bram_microsemi is
    generic (
      RAM_DEPTH : integer := 1024;      -- this is the maximum
      RAM_WIDTH : integer := 32
      );
    port (
      clk : in std_logic;

      address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      we       : in  std_logic;
      be       : in  std_logic_vector((RAM_WIDTH/8)-1 downto 0);
      readdata : out std_logic_vector(RAM_WIDTH-1 downto 0);

      data_address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      data_data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      data_we       : in  std_logic;
      data_be       : in  std_logic_vector((RAM_WIDTH/8)-1 downto 0);
      data_readdata : out std_logic_vector(RAM_WIDTH-1 downto 0)
      );
  end component;

  component a4l_master is
    generic (
      ADDR_WIDTH : integer := 32;
      DATA_WIDTH : integer := 32
      );
    port (
      clk     : in std_logic;
      aresetn : in std_logic;

      --Orca-internal memory-mapped slave
      oimm_address       : in     std_logic_vector(ADDR_WIDTH-1 downto 0);
      oimm_byteenable    : in     std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      oimm_requestvalid  : in     std_logic;
      oimm_readnotwrite  : in     std_logic;
      oimm_writedata     : in     std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdata      : out    std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdatavalid : out    std_logic;
      oimm_waitrequest   : buffer std_logic;

      --AXI4-Lite memory-mapped master
      AWADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      AWPROT  : out std_logic_vector(2 downto 0);
      AWVALID : out std_logic;
      AWREADY : in  std_logic;

      WSTRB  : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      WVALID : out std_logic;
      WDATA  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      WREADY : in  std_logic;

      BRESP  : in  std_logic_vector(1 downto 0);
      BVALID : in  std_logic;
      BREADY : out std_logic;

      ARADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      ARPROT  : out std_logic_vector(2 downto 0);
      ARVALID : out std_logic;
      ARREADY : in  std_logic;

      RDATA  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      RRESP  : in  std_logic_vector(1 downto 0);
      RVALID : in  std_logic;
      RREADY : out std_logic
      );
  end component a4l_master;

  component axi_master is
    generic (
      ADDR_WIDTH      : integer  := 32;
      DATA_WIDTH      : integer  := 32;
      ID_WIDTH        : positive := 4;
      MAX_BURSTLENGTH : positive := 16
      );
    port (
      clk     : in std_logic;
      aresetn : in std_logic;

      --Orca-internal memory-mapped slave
      oimm_address            : in     std_logic_vector(ADDR_WIDTH-1 downto 0);
      oimm_burstlength        : in     std_logic_vector(log2(MAX_BURSTLENGTH+1)-1 downto 0);
      oimm_burstlength_minus1 : in     std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
      oimm_byteenable         : in     std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      oimm_requestvalid       : in     std_logic;
      oimm_readnotwrite       : in     std_logic;
      oimm_writedata          : in     std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdata           : out    std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdatavalid      : out    std_logic;
      oimm_waitrequest        : buffer std_logic;

      --AXI memory-mapped master
      AWID    : out std_logic_vector(ID_WIDTH-1 downto 0);
      AWADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      AWLEN   : out std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
      AWSIZE  : out std_logic_vector(2 downto 0);
      AWBURST : out std_logic_vector(1 downto 0);
      AWLOCK  : out std_logic_vector(1 downto 0);
      AWCACHE : out std_logic_vector(3 downto 0);
      AWPROT  : out std_logic_vector(2 downto 0);
      AWVALID : out std_logic;
      AWREADY : in  std_logic;

      WID    : out std_logic_vector(ID_WIDTH-1 downto 0);
      WSTRB  : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      WVALID : out std_logic;
      WLAST  : out std_logic;
      WDATA  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      WREADY : in  std_logic;

      BID    : in  std_logic_vector(ID_WIDTH-1 downto 0);
      BRESP  : in  std_logic_vector(1 downto 0);
      BVALID : in  std_logic;
      BREADY : out std_logic;

      ARID    : out std_logic_vector(ID_WIDTH-1 downto 0);
      ARADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      ARLEN   : out std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
      ARSIZE  : out std_logic_vector(2 downto 0);
      ARBURST : out std_logic_vector(1 downto 0);
      ARLOCK  : out std_logic_vector(1 downto 0);
      ARCACHE : out std_logic_vector(3 downto 0);
      ARPROT  : out std_logic_vector(2 downto 0);
      ARVALID : out std_logic;
      ARREADY : in  std_logic;

      RID    : in  std_logic_vector(ID_WIDTH-1 downto 0);
      RDATA  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      RRESP  : in  std_logic_vector(1 downto 0);
      RLAST  : in  std_logic;
      RVALID : in  std_logic;
      RREADY : out std_logic
      );
  end component axi_master;

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
      CACHE_SIZE      : natural                  := 32768;  -- Byte size of cache
      LINE_SIZE       : positive range 16 to 256 := 32;  -- Bytes per cache line 
      ADDR_WIDTH      : integer                  := 32;
      INTERNAL_WIDTH  : integer                  := 32;
      EXTERNAL_WIDTH  : integer                  := 32;
      MAX_BURSTLENGTH : positive                 := 16;
      BURST_EN        : integer                  := 0
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      --Cache interface Orca-internal memory-mapped slave
      cacheint_oimm_address       : in     std_logic_vector(ADDR_WIDTH-1 downto 0);
      cacheint_oimm_byteenable    : in     std_logic_vector((INTERNAL_WIDTH/8)-1 downto 0);
      cacheint_oimm_requestvalid  : in     std_logic;
      cacheint_oimm_readnotwrite  : in     std_logic;
      cacheint_oimm_writedata     : in     std_logic_vector(INTERNAL_WIDTH-1 downto 0);
      cacheint_oimm_readdata      : out    std_logic_vector(INTERNAL_WIDTH-1 downto 0);
      cacheint_oimm_readdatavalid : out    std_logic;
      cacheint_oimm_waitrequest   : buffer std_logic;

      --Cached Orca-internal memory-mapped master
      c_oimm_address            : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      c_oimm_burstlength        : out std_logic_vector(log2(MAX_BURSTLENGTH+1)-1 downto 0);
      c_oimm_burstlength_minus1 : out std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
      c_oimm_byteenable         : out std_logic_vector((EXTERNAL_WIDTH/8)-1 downto 0);
      c_oimm_requestvalid       : out std_logic;
      c_oimm_readnotwrite       : out std_logic;
      c_oimm_writedata          : out std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
      c_oimm_readdata           : in  std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
      c_oimm_readdatavalid      : in  std_logic;
      c_oimm_waitrequest        : in  std_logic
      );
  end component icache;

  component cache is
    generic (
      NUM_LINES      : integer := 1;
      LINE_SIZE      : integer := 64;
      ADDR_WIDTH     : integer := 32;
      INTERNAL_WIDTH : integer := 32;
      EXTERNAL_WIDTH : integer := 32
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      --Internal data Orca-internal memory-mapped slave
      internal_data_oimm_address       : in     std_logic_vector(ADDR_WIDTH-1 downto 0);
      internal_data_oimm_byteenable    : in     std_logic_vector((INTERNAL_WIDTH/8)-1 downto 0);
      internal_data_oimm_requestvalid  : in     std_logic;
      internal_data_oimm_readnotwrite  : in     std_logic;
      internal_data_oimm_writedata     : in     std_logic_vector(INTERNAL_WIDTH-1 downto 0);
      internal_data_oimm_readdata      : out    std_logic_vector(INTERNAL_WIDTH-1 downto 0);
      internal_data_oimm_readdatavalid : out    std_logic;
      internal_data_oimm_miss          : out    std_logic;
      internal_data_oimm_missaddress   : buffer std_logic_vector(ADDR_WIDTH-1 downto 0);
      internal_data_oimm_waitrequest   : buffer std_logic;

      --Internal tag Orca-internal memory-mapped slave (uses internal_data_oimm_address)
      internal_tag_oimm_writedata    : in std_logic;
      internal_tag_oimm_requestvalid : in std_logic;

      --External data Orca-internal memory-mapped master
      external_data_oimm_address       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      external_data_oimm_requestvalid  : in  std_logic;
      external_data_oimm_readnotwrite  : in  std_logic;
      external_data_oimm_writedata     : in  std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
      external_data_oimm_readdata      : out std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
      external_data_oimm_readdatavalid : out std_logic;

      --External tag Orca-external memory-mapped slave (uses external_data_oimm_address)
      external_tag_oimm_writedata    : in std_logic;
      external_tag_oimm_requestvalid : in std_logic
      );
  end component;

  component cache_mux is
    generic (
      UC_ADDR_BASE    : std_logic_vector(31 downto 0);
      UC_ADDR_LAST    : std_logic_vector(31 downto 0);
      MAX_BURST_BEATS : positive := 16;
      ADDR_WIDTH      : integer  := 32;
      DATA_WIDTH      : integer  := 32
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      --Orca-internal memory-mapped slave
      oimm_address       : in     std_logic_vector(ADDR_WIDTH-1 downto 0);
      oimm_byteenable    : in     std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      oimm_requestvalid  : in     std_logic;
      oimm_readnotwrite  : in     std_logic;
      oimm_writedata     : in     std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdata      : out    std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdatavalid : buffer std_logic;
      oimm_waitrequest   : buffer std_logic;

      --Cache interface Orca-internal memory-mapped master
      cacheint_oimm_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      cacheint_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      cacheint_oimm_requestvalid  : out std_logic;
      cacheint_oimm_readnotwrite  : out std_logic;
      cacheint_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      cacheint_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      cacheint_oimm_readdatavalid : in  std_logic;
      cacheint_oimm_waitrequest   : in  std_logic;

      --Uncached Orca-internal memory-mapped master
      uc_oimm_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      uc_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      uc_oimm_requestvalid  : out std_logic;
      uc_oimm_readnotwrite  : out std_logic;
      uc_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      uc_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      uc_oimm_readdatavalid : in  std_logic;
      uc_oimm_waitrequest   : in  std_logic
      );
  end component;

end package rv_components;
