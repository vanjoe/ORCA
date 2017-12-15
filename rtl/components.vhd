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

      --Auxiliary Interface Select
      AVALON_AUX   : natural range 0 to 1 := 0;
      WISHBONE_AUX : natural range 0 to 1 := 0;
      LMB_AUX      : natural range 0 to 1 := 0;

      RESET_VECTOR           : std_logic_vector(31 downto 0) := X"00000000";
      INTERRUPT_VECTOR       : std_logic_vector(31 downto 0) := X"00000200";
      MAX_IFETCHES_IN_FLIGHT : positive range 1 to 4         := 1;
      BTB_ENTRIES            : natural                       := 0;
      MULTIPLY_ENABLE        : natural range 0 to 1          := 0;
      DIVIDE_ENABLE          : natural range 0 to 1          := 0;
      SHIFTER_MAX_CYCLES     : natural                       := 1;
      COUNTER_LENGTH         : natural                       := 0;
      ENABLE_EXCEPTIONS      : natural                       := 1;
      PIPELINE_STAGES        : natural range 4 to 5          := 5;
      LVE_ENABLE             : natural range 0 to 1          := 0;
      ENABLE_EXT_INTERRUPTS  : natural range 0 to 1          := 0;
      NUM_EXT_INTERRUPTS     : positive range 1 to 32        := 1;
      SCRATCHPAD_ADDR_BITS   : positive                      := 10;
      POWER_OPTIMIZED        : natural range 0 to 1          := 0;
      FAMILY                 : string                        := "GENERIC";

      --Memory interface configuration
      INSTRUCTION_REQUEST_REGISTER : natural range 0 to 2 := 0;
      INSTRUCTION_RETURN_REGISTER  : natural range 0 to 1 := 0;

      IUC_REQUEST_REGISTER : natural range 0 to 2          := 0;
      IUC_RETURN_REGISTER  : natural range 0 to 1          := 0;
      IUC_ADDR_BASE        : std_logic_vector(31 downto 0) := X"00000000";
      IUC_ADDR_LAST        : std_logic_vector(31 downto 0) := X"00000000";

      IAUX_REQUEST_REGISTER : natural range 0 to 2          := 0;
      IAUX_RETURN_REGISTER  : natural range 0 to 1          := 0;
      IAUX_ADDR_BASE        : std_logic_vector(31 downto 0) := X"00000000";
      IAUX_ADDR_LAST        : std_logic_vector(31 downto 0) := X"FFFFFFFF";

      IC_REQUEST_REGISTER   : natural range 0 to 2     := 0;
      IC_RETURN_REGISTER    : natural range 0 to 1     := 0;
      ICACHE_SIZE           : natural                  := 0;
      ICACHE_LINE_SIZE      : positive range 16 to 256 := 32;
      ICACHE_EXTERNAL_WIDTH : positive                 := 32;
      ICACHE_BURST_EN       : natural range 0 to 1     := 0;

      DATA_REQUEST_REGISTER : natural range 0 to 2 := 0;
      DATA_RETURN_REGISTER  : natural range 0 to 1 := 0;

      DUC_REQUEST_REGISTER : natural range 0 to 2          := 1;
      DUC_RETURN_REGISTER  : natural range 0 to 1          := 0;
      DUC_ADDR_BASE        : std_logic_vector(31 downto 0) := X"00000000";
      DUC_ADDR_LAST        : std_logic_vector(31 downto 0) := X"00000000";

      DAUX_REQUEST_REGISTER : natural range 0 to 2          := 1;
      DAUX_RETURN_REGISTER  : natural range 0 to 1          := 0;
      DAUX_ADDR_BASE        : std_logic_vector(31 downto 0) := X"00000000";
      DAUX_ADDR_LAST        : std_logic_vector(31 downto 0) := X"FFFFFFFF";

      DC_REQUEST_REGISTER   : natural range 0 to 2     := 1;
      DC_RETURN_REGISTER    : natural range 0 to 1     := 0;
      DCACHE_SIZE           : natural                  := 0;
      DCACHE_LINE_SIZE      : positive range 16 to 256 := 32;
      DCACHE_EXTERNAL_WIDTH : positive                 := 32;
      DCACHE_BURST_EN       : natural range 0 to 1     := 0
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

      --AXI3 cacheable data master
      DC_ARID    : out std_logic_vector(3 downto 0);
      DC_ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      DC_ARLEN   : out std_logic_vector(3 downto 0);
      DC_ARSIZE  : out std_logic_vector(2 downto 0);
      DC_ARBURST : out std_logic_vector(1 downto 0);
      DC_ARLOCK  : out std_logic_vector(1 downto 0);
      DC_ARCACHE : out std_logic_vector(3 downto 0);
      DC_ARPROT  : out std_logic_vector(2 downto 0);
      DC_ARVALID : out std_logic;
      DC_ARREADY : in  std_logic := '0';

      DC_RID    : in  std_logic_vector(3 downto 0)                       := (others => '0');
      DC_RDATA  : in  std_logic_vector(DCACHE_EXTERNAL_WIDTH-1 downto 0) := (others => '0');
      DC_RRESP  : in  std_logic_vector(1 downto 0)                       := (others => '0');
      DC_RLAST  : in  std_logic                                          := '0';
      DC_RVALID : in  std_logic                                          := '0';
      DC_RREADY : out std_logic;

      DC_AWID    : out std_logic_vector(3 downto 0);
      DC_AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      DC_AWLEN   : out std_logic_vector(3 downto 0);
      DC_AWSIZE  : out std_logic_vector(2 downto 0);
      DC_AWBURST : out std_logic_vector(1 downto 0);
      DC_AWLOCK  : out std_logic_vector(1 downto 0);
      DC_AWCACHE : out std_logic_vector(3 downto 0);
      DC_AWPROT  : out std_logic_vector(2 downto 0);
      DC_AWVALID : out std_logic;
      DC_AWREADY : in  std_logic := '0';

      DC_WID    : out std_logic_vector(3 downto 0);
      DC_WDATA  : out std_logic_vector(DCACHE_EXTERNAL_WIDTH-1 downto 0);
      DC_WSTRB  : out std_logic_vector((DCACHE_EXTERNAL_WIDTH/8)-1 downto 0);
      DC_WLAST  : out std_logic;
      DC_WVALID : out std_logic;
      DC_WREADY : in  std_logic                    := '0';
      DC_BID    : in  std_logic_vector(3 downto 0) := (others => '0');
      DC_BRESP  : in  std_logic_vector(1 downto 0) := (others => '0');
      DC_BVALID : in  std_logic                    := '0';
      DC_BREADY : out std_logic;

      --Xilinx local memory bus instruction master
      ILMB_Addr         : out std_logic_vector(0 to REGISTER_SIZE-1);
      ILMB_Byte_Enable  : out std_logic_vector(0 to (REGISTER_SIZE/8)-1);
      ILMB_Data_Write   : out std_logic_vector(0 to REGISTER_SIZE-1);
      ILMB_AS           : out std_logic;
      ILMB_Read_Strobe  : out std_logic;
      ILMB_Write_Strobe : out std_logic;
      ILMB_Data_Read    : in  std_logic_vector(0 to REGISTER_SIZE-1) := (others => '0');
      ILMB_Ready        : in  std_logic                              := '0';
      ILMB_Wait         : in  std_logic                              := '0';
      ILMB_CE           : in  std_logic                              := '0';
      ILMB_UE           : in  std_logic                              := '0';

      --Xilinx local memory bus data master
      DLMB_Addr         : out std_logic_vector(0 to REGISTER_SIZE-1);
      DLMB_Byte_Enable  : out std_logic_vector(0 to (REGISTER_SIZE/8)-1);
      DLMB_Data_Write   : out std_logic_vector(0 to REGISTER_SIZE-1);
      DLMB_AS           : out std_logic;
      DLMB_Read_Strobe  : out std_logic;
      DLMB_Write_Strobe : out std_logic;
      DLMB_Data_Read    : in  std_logic_vector(0 to REGISTER_SIZE-1) := (others => '0');
      DLMB_Ready        : in  std_logic                              := '0';
      DLMB_Wait         : in  std_logic                              := '0';
      DLMB_CE           : in  std_logic                              := '0';
      DLMB_UE           : in  std_logic                              := '0';

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
      REGISTER_SIZE         : positive range 32 to 32;
      SCRATCHPAD_ADDR_BITS  : positive;
      WRITE_FIRST_SUPPORTED : boolean;

      --Auxiliary Interface Select
      AVALON_AUX   : natural range 0 to 1;
      WISHBONE_AUX : natural range 0 to 1;
      LMB_AUX      : natural range 0 to 1;

      WISHBONE_SINGLE_CYCLE_READS  : natural range 0 to 1;
      MAX_IFETCHES_IN_FLIGHT       : positive range 1 to 4;
      MAX_OUTSTANDING_REQUESTS     : positive;

      INSTRUCTION_REQUEST_REGISTER : natural range 0 to 2;
      INSTRUCTION_RETURN_REGISTER  : natural range 0 to 1;

      IUC_REQUEST_REGISTER         : natural range 0 to 2;
      IUC_RETURN_REGISTER          : natural range 0 to 1;
      IUC_ADDR_BASE                : std_logic_vector(31 downto 0);
      IUC_ADDR_LAST                : std_logic_vector(31 downto 0);

      IAUX_REQUEST_REGISTER        : natural range 0 to 2;
      IAUX_RETURN_REGISTER         : natural range 0 to 1;
      IAUX_ADDR_BASE               : std_logic_vector(31 downto 0);
      IAUX_ADDR_LAST               : std_logic_vector(31 downto 0);

      IC_REQUEST_REGISTER          : natural range 0 to 2;
      IC_RETURN_REGISTER           : natural range 0 to 1;
      ICACHE_SIZE                  : natural;
      ICACHE_LINE_SIZE             : integer range 16 to 256;
      ICACHE_EXTERNAL_WIDTH        : integer;
      ICACHE_MAX_BURSTLENGTH       : positive;
      ICACHE_BURST_EN              : integer range 0 to 1;

      DATA_REQUEST_REGISTER        : natural range 0 to 2;
      DATA_RETURN_REGISTER         : natural range 0 to 1;

      DUC_REQUEST_REGISTER         : natural range 0 to 2;
      DUC_RETURN_REGISTER          : natural range 0 to 1;
      DUC_ADDR_BASE                : std_logic_vector(31 downto 0);
      DUC_ADDR_LAST                : std_logic_vector(31 downto 0);

      DAUX_REQUEST_REGISTER        : natural range 0 to 2;
      DAUX_RETURN_REGISTER         : natural range 0 to 1;
      DAUX_ADDR_BASE               : std_logic_vector(31 downto 0);
      DAUX_ADDR_LAST               : std_logic_vector(31 downto 0);

      DC_REQUEST_REGISTER          : natural range 0 to 2;
      DC_RETURN_REGISTER           : natural range 0 to 1;
      DCACHE_SIZE                  : natural;
      DCACHE_LINE_SIZE             : integer range 16 to 256;
      DCACHE_EXTERNAL_WIDTH        : integer;
      DCACHE_MAX_BURSTLENGTH       : positive;
      DCACHE_BURST_EN              : integer range 0 to 1
      );
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;

      --ICache control (Invalidate/flush/writeback/enable/disable)
      from_icache_control_ready : out std_logic;
      to_icache_control_valid   : in  std_logic;
      to_icache_control_command : in  cache_control_command;

      --DCache control (Invalidate/flush/writeback/enable/disable)
      from_dcache_control_ready : out std_logic;
      to_dcache_control_valid   : in  std_logic;
      to_dcache_control_command : in  cache_control_command;

      memory_interface_idle : out std_logic;

      --Instruction Orca-internal memory-mapped master
      ifetch_oimm_address       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      ifetch_oimm_requestvalid  : in  std_logic;
      ifetch_oimm_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      ifetch_oimm_waitrequest   : out std_logic;
      ifetch_oimm_readdatavalid : out std_logic;

      --Data Orca-internal memory-mapped master
      lsu_oimm_address       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_byteenable    : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      lsu_oimm_requestvalid  : in  std_logic;
      lsu_oimm_readnotwrite  : in  std_logic;
      lsu_oimm_writedata     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdatavalid : out std_logic;
      lsu_oimm_waitrequest   : out std_logic;

      --Scratchpad memory-mapped slave
      sp_address   : out std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
      sp_byte_en   : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      sp_write_en  : out std_logic;
      sp_read_en   : out std_logic;
      sp_writedata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_readdata  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_ack       : in  std_logic;

      -------------------------------------------------------------------------------
      --AVALON
      -------------------------------------------------------------------------------
      --Avalon data master
      avm_data_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_data_byteenable    : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      avm_data_read          : out std_logic;
      avm_data_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_data_write         : out std_logic;
      avm_data_writedata     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_data_waitrequest   : in  std_logic;
      avm_data_readdatavalid : in  std_logic;

      --Avalon instruction master
      avm_instruction_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_instruction_read          : out std_logic;
      avm_instruction_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_instruction_waitrequest   : in  std_logic;
      avm_instruction_readdatavalid : in  std_logic;

      -------------------------------------------------------------------------------
      --WISHBONE
      -------------------------------------------------------------------------------
      --WISHBONE data master
      data_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_WE_O    : out std_logic;
      data_SEL_O   : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      data_STB_O   : out std_logic;
      data_ACK_I   : in  std_logic;
      data_CYC_O   : out std_logic;
      data_CTI_O   : out std_logic_vector(2 downto 0);
      data_STALL_I : in  std_logic;

      --WISHBONE instruction master
      instr_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_STB_O   : out std_logic;
      instr_ACK_I   : in  std_logic;
      instr_CYC_O   : out std_logic;
      instr_CTI_O   : out std_logic_vector(2 downto 0);
      instr_STALL_I : in  std_logic;

      -------------------------------------------------------------------------------
      --AXI
      -------------------------------------------------------------------------------
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
      IUC_ARREADY : in  std_logic;

      IUC_RID    : in  std_logic_vector(3 downto 0);
      IUC_RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      IUC_RRESP  : in  std_logic_vector(1 downto 0);
      IUC_RLAST  : in  std_logic;
      IUC_RVALID : in  std_logic;
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
      IUC_AWREADY : in  std_logic;

      IUC_WID    : out std_logic_vector(3 downto 0);
      IUC_WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      IUC_WSTRB  : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      IUC_WLAST  : out std_logic;
      IUC_WVALID : out std_logic;
      IUC_WREADY : in  std_logic;

      IUC_BID    : in  std_logic_vector(3 downto 0);
      IUC_BRESP  : in  std_logic_vector(1 downto 0);
      IUC_BVALID : in  std_logic;
      IUC_BREADY : out std_logic;

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
      DUC_AWREADY : in  std_logic;

      DUC_WID    : out std_logic_vector(3 downto 0);
      DUC_WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      DUC_WSTRB  : out std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      DUC_WLAST  : out std_logic;
      DUC_WVALID : out std_logic;
      DUC_WREADY : in  std_logic;

      DUC_BID    : in  std_logic_vector(3 downto 0);
      DUC_BRESP  : in  std_logic_vector(1 downto 0);
      DUC_BVALID : in  std_logic;
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
      DUC_ARREADY : in  std_logic;

      DUC_RID    : in  std_logic_vector(3 downto 0);
      DUC_RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      DUC_RRESP  : in  std_logic_vector(1 downto 0);
      DUC_RLAST  : in  std_logic;
      DUC_RVALID : in  std_logic;
      DUC_RREADY : out std_logic;

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
      IC_ARREADY : in  std_logic;

      IC_RID    : in  std_logic_vector(3 downto 0);
      IC_RDATA  : in  std_logic_vector(ICACHE_EXTERNAL_WIDTH-1 downto 0);
      IC_RRESP  : in  std_logic_vector(1 downto 0);
      IC_RLAST  : in  std_logic;
      IC_RVALID : in  std_logic;
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
      IC_AWREADY : in  std_logic;

      IC_WID    : out std_logic_vector(3 downto 0);
      IC_WDATA  : out std_logic_vector(ICACHE_EXTERNAL_WIDTH-1 downto 0);
      IC_WSTRB  : out std_logic_vector((ICACHE_EXTERNAL_WIDTH/8)-1 downto 0);
      IC_WLAST  : out std_logic;
      IC_WVALID : out std_logic;
      IC_WREADY : in  std_logic;
      IC_BID    : in  std_logic_vector(3 downto 0);
      IC_BRESP  : in  std_logic_vector(1 downto 0);
      IC_BVALID : in  std_logic;
      IC_BREADY : out std_logic;

      --AXI3 cacheable data master
      DC_ARID    : out std_logic_vector(3 downto 0);
      DC_ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      DC_ARLEN   : out std_logic_vector(3 downto 0);
      DC_ARSIZE  : out std_logic_vector(2 downto 0);
      DC_ARBURST : out std_logic_vector(1 downto 0);
      DC_ARLOCK  : out std_logic_vector(1 downto 0);
      DC_ARCACHE : out std_logic_vector(3 downto 0);
      DC_ARPROT  : out std_logic_vector(2 downto 0);
      DC_ARVALID : out std_logic;
      DC_ARREADY : in  std_logic;

      DC_RID    : in  std_logic_vector(3 downto 0);
      DC_RDATA  : in  std_logic_vector(DCACHE_EXTERNAL_WIDTH-1 downto 0);
      DC_RRESP  : in  std_logic_vector(1 downto 0);
      DC_RLAST  : in  std_logic;
      DC_RVALID : in  std_logic;
      DC_RREADY : out std_logic;

      DC_AWID    : out std_logic_vector(3 downto 0);
      DC_AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      DC_AWLEN   : out std_logic_vector(3 downto 0);
      DC_AWSIZE  : out std_logic_vector(2 downto 0);
      DC_AWBURST : out std_logic_vector(1 downto 0);
      DC_AWLOCK  : out std_logic_vector(1 downto 0);
      DC_AWCACHE : out std_logic_vector(3 downto 0);
      DC_AWPROT  : out std_logic_vector(2 downto 0);
      DC_AWVALID : out std_logic;
      DC_AWREADY : in  std_logic;

      DC_WID    : out std_logic_vector(3 downto 0);
      DC_WDATA  : out std_logic_vector(DCACHE_EXTERNAL_WIDTH-1 downto 0);
      DC_WSTRB  : out std_logic_vector((DCACHE_EXTERNAL_WIDTH/8)-1 downto 0);
      DC_WLAST  : out std_logic;
      DC_WVALID : out std_logic;
      DC_WREADY : in  std_logic;
      DC_BID    : in  std_logic_vector(3 downto 0);
      DC_BRESP  : in  std_logic_vector(1 downto 0);
      DC_BVALID : in  std_logic;
      DC_BREADY : out std_logic;

      --Xilinx local memory bus instruction master
      ILMB_Addr         : out std_logic_vector(0 to REGISTER_SIZE-1);
      ILMB_Byte_Enable  : out std_logic_vector(0 to (REGISTER_SIZE/8)-1);
      ILMB_Data_Write   : out std_logic_vector(0 to REGISTER_SIZE-1);
      ILMB_AS           : out std_logic;
      ILMB_Read_Strobe  : out std_logic;
      ILMB_Write_Strobe : out std_logic;
      ILMB_Data_Read    : in  std_logic_vector(0 to REGISTER_SIZE-1);
      ILMB_Ready        : in  std_logic;
      ILMB_Wait         : in  std_logic;
      ILMB_CE           : in  std_logic;
      ILMB_UE           : in  std_logic;

      --Xilinx local memory bus data master
      DLMB_Addr         : out std_logic_vector(0 to REGISTER_SIZE-1);
      DLMB_Byte_Enable  : out std_logic_vector(0 to (REGISTER_SIZE/8)-1);
      DLMB_Data_Write   : out std_logic_vector(0 to REGISTER_SIZE-1);
      DLMB_AS           : out std_logic;
      DLMB_Read_Strobe  : out std_logic;
      DLMB_Write_Strobe : out std_logic;
      DLMB_Data_Read    : in  std_logic_vector(0 to REGISTER_SIZE-1);
      DLMB_Ready        : in  std_logic;
      DLMB_Wait         : in  std_logic;
      DLMB_CE           : in  std_logic;
      DLMB_UE           : in  std_logic;

      -------------------------------------------------------------------------------
      -- Scratchpad Slave
      -------------------------------------------------------------------------------
      --Avalon scratchpad slave
      avm_scratch_address       : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
      avm_scratch_byteenable    : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      avm_scratch_read          : in  std_logic;
      avm_scratch_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_scratch_write         : in  std_logic;
      avm_scratch_writedata     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_scratch_waitrequest   : out std_logic;
      avm_scratch_readdatavalid : out std_logic;

      --WISHBONE scratchpad slave
      sp_ADR_I   : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
      sp_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_WE_I    : in  std_logic;
      sp_SEL_I   : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      sp_STB_I   : in  std_logic;
      sp_ACK_O   : out std_logic;
      sp_CYC_I   : in  std_logic;
      sp_CTI_I   : in  std_logic_vector(2 downto 0);
      sp_STALL_O : out std_logic
      );
  end component;

  component orca_core is
    generic (
      REGISTER_SIZE          : integer;
      RESET_VECTOR           : std_logic_vector(31 downto 0);
      INTERRUPT_VECTOR       : std_logic_vector(31 downto 0);
      MAX_IFETCHES_IN_FLIGHT : positive range 1 to 4;
      BTB_ENTRIES            : natural;
      MULTIPLY_ENABLE        : natural range 0 to 1;
      DIVIDE_ENABLE          : natural range 0 to 1;
      SHIFTER_MAX_CYCLES     : natural;
      POWER_OPTIMIZED        : natural range 0 to 1;
      COUNTER_LENGTH         : natural;
      ENABLE_EXCEPTIONS      : natural;
      PIPELINE_STAGES        : natural range 4 to 5;
      ENABLE_EXT_INTERRUPTS  : natural range 0 to 1;
      NUM_EXT_INTERRUPTS     : positive range 1 to 32;
      LVE_ENABLE             : natural range 0 to 1;
      SCRATCHPAD_SIZE        : integer;
      WRITE_FIRST_SMALL_RAMS : boolean;
      FAMILY                 : string;

      HAS_ICACHE : boolean;
      HAS_DCACHE : boolean
      );
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;

      --ICache control (Invalidate/flush/writeback/enable/disable)
      from_icache_control_ready : in     std_logic;
      to_icache_control_valid   : buffer std_logic;
      to_icache_control_command : out    cache_control_command;

      --DCache control (Invalidate/flush/writeback/enable/disable)
      from_dcache_control_ready : in     std_logic;
      to_dcache_control_valid   : buffer std_logic;
      to_dcache_control_command : out    cache_control_command;

      memory_interface_idle : in std_logic;

      --Instruction Orca-internal memory-mapped master
      ifetch_oimm_address       : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
      ifetch_oimm_requestvalid  : buffer std_logic;
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

      global_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0)
      );
  end component orca_core;

  component decode is
    generic (
      REGISTER_SIZE          : positive;
      SIGN_EXTENSION_SIZE    : positive;
      LVE_ENABLE             : boolean;
      PIPELINE_STAGES        : natural range 1 to 2;
      WRITE_FIRST_SMALL_RAMS : boolean;
      FAMILY                 : string
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      --writeback signals
      to_rf_select : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      to_rf_data   : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      to_rf_valid  : in std_logic;

      to_decode_instruction     : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      to_decode_program_counter : in  unsigned(REGISTER_SIZE-1 downto 0);
      to_decode_predicted_pc    : in  unsigned(REGISTER_SIZE-1 downto 0);
      to_decode_valid           : in  std_logic;
      from_decode_ready         : out std_logic;

      quash_decode : in  std_logic;
      decode_idle  : out std_logic;

      from_decode_rs1_data         : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      from_decode_rs2_data         : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      from_decode_rs3_data         : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      from_decode_sign_extension   : out std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      from_decode_program_counter  : out unsigned(REGISTER_SIZE-1 downto 0);
      from_decode_predicted_pc     : out unsigned(REGISTER_SIZE-1 downto 0);
      from_decode_instruction      : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      from_decode_next_instruction : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      from_decode_next_valid       : out std_logic;
      from_decode_valid            : out std_logic;
      to_decode_ready              : in  std_logic
      );
  end component decode;

  component execute is
    generic (
      REGISTER_SIZE         : positive;
      SIGN_EXTENSION_SIZE   : positive;
      INTERRUPT_VECTOR      : std_logic_vector(31 downto 0);
      BTB_ENTRIES           : natural;
      POWER_OPTIMIZED       : boolean;
      MULTIPLY_ENABLE       : boolean;
      DIVIDE_ENABLE         : boolean;
      SHIFTER_MAX_CYCLES    : natural;
      COUNTER_LENGTH        : natural;
      ENABLE_EXCEPTIONS     : boolean;
      ENABLE_EXT_INTERRUPTS : natural range 0 to 1;
      NUM_EXT_INTERRUPTS    : positive range 1 to 32;
      LVE_ENABLE            : natural;
      SCRATCHPAD_SIZE       : integer;
      FAMILY                : string;
      
      HAS_ICACHE : boolean;
      HAS_DCACHE : boolean
      );
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;

      global_interrupts     : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);
      program_counter       : in unsigned(REGISTER_SIZE-1 downto 0);
      core_idle             : in std_logic;
      memory_interface_idle : in std_logic;

      --LVE Scratchpad memory-mapped slave
      sp_address   : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
      sp_byte_en   : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      sp_write_en  : in  std_logic;
      sp_read_en   : in  std_logic;
      sp_writedata : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_readdata  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      sp_ack       : out std_logic;

      to_execute_valid            : in     std_logic;
      to_execute_program_counter  : in     unsigned(REGISTER_SIZE-1 downto 0);
      to_execute_predicted_pc     : in     unsigned(REGISTER_SIZE-1 downto 0);
      to_execute_instruction      : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      to_execute_next_instruction : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      to_execute_next_valid       : in     std_logic;
      to_execute_rs1_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      to_execute_rs2_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      to_execute_rs3_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      to_execute_sign_extension   : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      from_execute_ready          : buffer std_logic;

      --quash_execute input isn't needed as mispredicts have already resolved
      execute_idle : out std_logic;

      --To PC correction
      to_pc_correction_data        : out    unsigned(REGISTER_SIZE-1 downto 0);
      to_pc_correction_source_pc   : out    unsigned(REGISTER_SIZE-1 downto 0);
      to_pc_correction_valid       : buffer std_logic;
      to_pc_correction_predictable : out    std_logic;
      from_pc_correction_ready     : in     std_logic;

      --To register file
      to_rf_select : buffer std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      to_rf_data   : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
      to_rf_valid  : buffer std_logic;

      --Data Orca-internal memory-mapped master
      lsu_oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_byteenable    : out    std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
      lsu_oimm_requestvalid  : buffer std_logic;
      lsu_oimm_readnotwrite  : buffer std_logic;
      lsu_oimm_writedata     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdata      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      lsu_oimm_readdatavalid : in     std_logic;
      lsu_oimm_waitrequest   : in     std_logic;

      --ICache control (Invalidate/flush/writeback/enable/disable)
      from_icache_control_ready : in     std_logic;
      to_icache_control_valid   : buffer std_logic;
      to_icache_control_command : out    cache_control_command;

      --DCache control (Invalidate/flush/writeback/enable/disable)
      from_dcache_control_ready : in     std_logic;
      to_dcache_control_valid   : buffer std_logic;
      to_dcache_control_command : out    cache_control_command;

      interrupt_pending : buffer std_logic
      );
  end component execute;

  component instruction_fetch is
    generic (
      REGISTER_SIZE          : positive;
      RESET_VECTOR           : std_logic_vector(31 downto 0);
      MAX_IFETCHES_IN_FLIGHT : positive range 1 to 4;
      BTB_ENTRIES            : natural
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      interrupt_pending : in std_logic;

      to_pc_correction_data        : in     unsigned(REGISTER_SIZE-1 downto 0);
      to_pc_correction_source_pc   : in     unsigned(REGISTER_SIZE-1 downto 0);
      to_pc_correction_valid       : in     std_logic;
      to_pc_correction_predictable : in     std_logic;
      from_pc_correction_ready     : buffer std_logic;

      --quash_ifetch is handled by to_pc_correction_valid
      ifetch_idle : out std_logic;

      from_ifetch_instruction     : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      from_ifetch_program_counter : out unsigned(REGISTER_SIZE-1 downto 0);
      from_ifetch_predicted_pc    : out unsigned(REGISTER_SIZE-1 downto 0);
      from_ifetch_valid           : out std_logic;
      to_ifetch_ready             : in  std_logic;

      program_counter : buffer unsigned(REGISTER_SIZE-1 downto 0);

      --Orca-internal memory-mapped master
      oimm_address       : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
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
      FAMILY              : string
      );
    port (
      clk                : in  std_logic;
      valid_instr        : in  std_logic;
      simd_op_size       : in  std_logic_vector(1 downto 0);
      from_execute_ready : in  std_logic;
      rs1_data           : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data           : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction        : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension     : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      current_pc         : in  unsigned(REGISTER_SIZE-1 downto 0);
      data_out           : out std_logic_vector(REGISTER_SIZE-1 downto 0);

      data_out_valid : out std_logic;
      alu_ready      : out std_logic;

      lve_data1        : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_data2        : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_source_valid : in std_logic
      );
  end component arithmetic_unit;

  component branch_unit is
    generic (
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer;
      BTB_ENTRIES         : natural
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      to_branch_valid : in std_logic;
      rs1_data        : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data        : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      current_pc      : in unsigned(REGISTER_SIZE-1 downto 0);
      predicted_pc    : in unsigned(REGISTER_SIZE-1 downto 0);
      instruction     : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension  : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

      from_branch_valid : out std_logic;
      from_branch_data  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      to_branch_ready   : in  std_logic;

      to_pc_correction_data      : out unsigned(REGISTER_SIZE-1 downto 0);
      to_pc_correction_source_pc : out unsigned(REGISTER_SIZE-1 downto 0);
      to_pc_correction_valid     : out std_logic;
      from_pc_correction_ready   : in  std_logic
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

      lsu_idle : out std_logic;

      valid                    : in     std_logic;
      rs1_data                 : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data                 : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction              : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension           : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      writeback_stall_from_lsu : buffer std_logic;
      lsu_ready                : out    std_logic;
      data_out                 : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable              : out    std_logic;
      load_in_progress         : buffer std_logic;

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
    generic (
      REGISTER_SIZE          : positive;
      REGISTER_NAME_SIZE     : positive;
      READ_PORTS             : positive range 1 to 3;
      WRITE_FIRST_SMALL_RAMS : boolean
      );
    port (
      clk        : in std_logic;
      rs1_select : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      rs2_select : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      rs3_select : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      wb_select  : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      wb_data    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      wb_enable  : in std_logic;

      rs1_data : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs3_data : out std_logic_vector(REGISTER_SIZE-1 downto 0)
      );
  end component register_file;

  component system_calls is
    generic (
      REGISTER_SIZE   : natural;
      COUNTER_LENGTH  : natural;
      POWER_OPTIMIZED : boolean;

      INTERRUPT_VECTOR : std_logic_vector(31 downto 0);

      ENABLE_EXCEPTIONS     : boolean;
      ENABLE_EXT_INTERRUPTS : natural range 0 to 1;
      NUM_EXT_INTERRUPTS    : positive range 1 to 32;

      HAS_ICACHE : boolean;
      HAS_DCACHE : boolean
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      global_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);
      core_idle         : in std_logic;
      memory_idle       : in std_logic;
      program_counter   : in unsigned(REGISTER_SIZE-1 downto 0);

      to_syscall_valid   : in  std_logic;
      current_pc         : in  unsigned(REGISTER_SIZE-1 downto 0);
      instruction        : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      rs1_data           : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      from_syscall_ready : out std_logic;

      from_syscall_valid : out std_logic;
      from_syscall_data  : out std_logic_vector(REGISTER_SIZE-1 downto 0);

      to_pc_correction_data    : out unsigned(REGISTER_SIZE-1 downto 0);
      to_pc_correction_valid   : out std_logic;
      from_pc_correction_ready : in  std_logic;

      from_icache_control_ready : in     std_logic;
      to_icache_control_valid   : buffer std_logic;
      to_icache_control_command : out    cache_control_command;

      from_dcache_control_ready : in     std_logic;
      to_dcache_control_valid   : buffer std_logic;
      to_dcache_control_command : out    cache_control_command;

      interrupt_pending : buffer std_logic
      );
  end component system_calls;

  type VCUSTOM_ENUM is (VCUSTOM0, VCUSTOM1, VCUSTOM2, VCUSTOM3, VCUSTOM4, VCUSTOM5, VCUSTOM6, VCUSTOM7);
  component lve_ci is
    generic (
      REGISTER_SIZE : positive
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      pause : in std_logic;

      func : in VCUSTOM_ENUM;

      valid_in : in std_logic;
      data1_in : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      data2_in : in std_logic_vector(REGISTER_SIZE-1 downto 0);

      align1_in : in std_logic_vector(1 downto 0);
      align2_in : in std_logic_vector(1 downto 0);

      valid_out        : out std_logic;
      byte_en_out      : out std_logic_vector(3 downto 0);
      write_enable_out : out std_logic;
      data_out         : out std_logic_vector(REGISTER_SIZE-1 downto 0)
      );
  end component lve_ci;

  component lve_top is
    generic (
      REGISTER_SIZE    : natural;
      SLAVE_DATA_WIDTH : natural;
      POWER_OPTIMIZED  : boolean;
      SCRATCHPAD_SIZE  : integer;
      FAMILY           : string
      );
    port (
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;
      instruction    : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      valid_instr    : in std_logic;
      rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs3_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);

      slave_address  : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
      slave_read_en  : in  std_logic;
      slave_write_en : in  std_logic;
      slave_byte_en  : in  std_logic_vector((SLAVE_DATA_WIDTH/8)-1 downto 0);
      slave_data_in  : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
      slave_data_out : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
      slave_ack      : out std_logic;

      lve_ready            : out std_logic;
      lve_executing        : out std_logic;
      lve_alu_data1        : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_alu_data2        : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_alu_op_size      : out std_logic_vector(1 downto 0);
      lve_alu_source_valid : out std_logic;
      lve_alu_result       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      lve_alu_result_valid : in  std_logic
      );
  end component;

  component ram_mux is
    generic (
      ADDRESS_WIDTH : natural;
      DATA_WIDTH    : natural
      );
    port (
      -- init signals
      nvm_addr     : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      nvm_wdata    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      nvm_wen      : in  std_logic;
      nvm_byte_sel : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      nvm_strb     : in  std_logic;
      nvm_ack      : out std_logic;
      nvm_rdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);

      -- user signals
      user_ARREADY : out std_logic;
      user_ARADDR  : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      user_ARVALID : in  std_logic;

      user_RREADY : out std_logic;
      user_RDATA  : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      user_RVALID : out std_logic;

      user_AWADDR  : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      user_AWVALID : in  std_logic;
      user_AWREADY : out std_logic;

      user_WDATA  : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      user_WVALID : in  std_logic;
      user_WREADY : out std_logic;

      user_BREADY : in  std_logic;
      user_BVALID : out std_logic;

      -- mux signals/ram inputs
      SEL          : in  std_logic;
      ram_addr     : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
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
      RAM_DEPTH : integer;
      RAM_WIDTH : integer
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
      ADDRESS_WIDTH            : integer;
      DATA_WIDTH               : integer;
      MAX_OUTSTANDING_REQUESTS : natural
      );
    port (
      clk     : in std_logic;
      reset   : in std_logic;
      aresetn : in std_logic;

      master_idle : out std_logic;

      --Orca-internal memory-mapped slave
      oimm_address       : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      oimm_byteenable    : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      oimm_requestvalid  : in  std_logic;
      oimm_readnotwrite  : in  std_logic;
      oimm_writedata     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdatavalid : out std_logic;
      oimm_waitrequest   : out std_logic;

      --AXI4-Lite memory-mapped master
      AWADDR  : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
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

      ARADDR  : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
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
      ADDRESS_WIDTH            : integer;
      DATA_WIDTH               : integer;
      ID_WIDTH                 : positive;
      MAX_BURSTLENGTH          : positive;
      MAX_OUTSTANDING_REQUESTS : natural;
      REQUEST_REGISTER         : natural range 0 to 2;
      RETURN_REGISTER          : natural range 0 to 1
      );
    port (
      clk     : in std_logic;
      reset   : in std_logic;
      aresetn : in std_logic;

      master_idle : out std_logic;

      --Orca-internal memory-mapped slave
      oimm_address            : in     std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      oimm_burstlength        : in     std_logic_vector(log2(MAX_BURSTLENGTH+1)-1 downto 0);
      oimm_burstlength_minus1 : in     std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
      oimm_byteenable         : in     std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      oimm_requestvalid       : in     std_logic;
      oimm_readnotwrite       : in     std_logic;
      oimm_writedata          : in     std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_writelast          : in     std_logic;
      oimm_readdata           : out    std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdatavalid      : out    std_logic;
      oimm_waitrequest        : buffer std_logic;

      --AXI memory-mapped master
      AWID    : out std_logic_vector(ID_WIDTH-1 downto 0);
      AWADDR  : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
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
      ARADDR  : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
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
      FAMILY          : string
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

  component cache_controller is
    generic (
      CACHE_SIZE            : natural;
      LINE_SIZE             : positive range 16 to 256;
      ADDRESS_WIDTH         : positive;
      INTERNAL_WIDTH        : positive;
      EXTERNAL_WIDTH        : positive;
      MAX_BURSTLENGTH       : positive;
      WRITE_FIRST_SUPPORTED : boolean;
      BURST_EN              : natural range 0 to 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      --Cache control (Invalidate/flush/writeback)
      from_cache_control_ready : out std_logic;
      to_cache_control_valid   : in  std_logic;
      to_cache_control_command : in  cache_control_command;

      precache_idle : in std_logic;
      cache_idle    : out std_logic;

      --Cache interface Orca-internal memory-mapped slave
      cacheint_oimm_address       : in     std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      cacheint_oimm_byteenable    : in     std_logic_vector((INTERNAL_WIDTH/8)-1 downto 0);
      cacheint_oimm_requestvalid  : in     std_logic;
      cacheint_oimm_readnotwrite  : in     std_logic;
      cacheint_oimm_writedata     : in     std_logic_vector(INTERNAL_WIDTH-1 downto 0);
      cacheint_oimm_readdata      : out    std_logic_vector(INTERNAL_WIDTH-1 downto 0);
      cacheint_oimm_readdatavalid : out    std_logic;
      cacheint_oimm_waitrequest   : buffer std_logic;

      --Cached Orca-internal memory-mapped master
      c_oimm_address            : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      c_oimm_burstlength        : out std_logic_vector(log2(MAX_BURSTLENGTH+1)-1 downto 0);
      c_oimm_burstlength_minus1 : out std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
      c_oimm_byteenable         : out std_logic_vector((EXTERNAL_WIDTH/8)-1 downto 0);
      c_oimm_requestvalid       : out std_logic;
      c_oimm_readnotwrite       : out std_logic;
      c_oimm_writedata          : out std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
      c_oimm_writelast          : out std_logic;
      c_oimm_readdata           : in  std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
      c_oimm_readdatavalid      : in  std_logic;
      c_oimm_waitrequest        : in  std_logic
      );
  end component cache_controller;

  component cache is
    generic (
      NUM_LINES             : positive;
      LINE_SIZE             : positive;
      ADDRESS_WIDTH         : positive;
      WIDTH                 : positive;
      DIRTY_BITS            : natural;
      WRITE_FIRST_SUPPORTED : boolean
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      --Read-only data Orca-internal memory-mapped slave
      read_oimm_address       : in     std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      read_oimm_requestvalid  : in     std_logic;
      read_oimm_speculative   : in     std_logic;
      read_oimm_readdata      : out    std_logic_vector(WIDTH-1 downto 0);
      read_oimm_readdatavalid : out    std_logic;
      read_oimm_readabort     : out    std_logic;
      read_oimm_waitrequest   : buffer std_logic;
      read_miss               : out    std_logic;
      read_lastaddress        : buffer std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      read_dirty_valid        : out    std_logic_vector(DIRTY_BITS downto 0);

      --Write-only data Orca-internal memory-mapped slave
      write_oimm_address      : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      write_oimm_byteenable   : in std_logic_vector((WIDTH/8)-1 downto 0);
      write_oimm_requestvalid : in std_logic;
      write_oimm_writedata    : in std_logic_vector(WIDTH-1 downto 0);
      write_tag_update        : in std_logic;
      write_dirty_valid       : in std_logic_vector(DIRTY_BITS downto 0)
      );
  end component;

  component cache_mux is
    generic (
      ADDRESS_WIDTH             : positive;
      DATA_WIDTH                : positive;
      MAX_OUTSTANDING_READS     : positive;
      INTERNAL_REQUEST_REGISTER : natural range 0 to 2;
      INTERNAL_RETURN_REGISTER  : natural range 0 to 1;
      CACHE_SIZE                : natural;
      CACHE_LINE_SIZE           : positive range 16 to 256;

      UC_REQUEST_REGISTER       : natural range 0 to 2;
      UC_RETURN_REGISTER        : natural range 0 to 1;
      UC_ADDR_BASE              : std_logic_vector(31 downto 0);
      UC_ADDR_LAST              : std_logic_vector(31 downto 0);

      AUX_REQUEST_REGISTER      : natural range 0 to 2;
      AUX_RETURN_REGISTER       : natural range 0 to 1;
      AUX_ADDR_BASE             : std_logic_vector(31 downto 0);
      AUX_ADDR_LAST             : std_logic_vector(31 downto 0)
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      internal_register_idle  : out std_logic;
      external_registers_idle : out std_logic;

      --Orca-internal memory-mapped slave
      oimm_address       : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      oimm_byteenable    : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0) := (others => '1');
      oimm_requestvalid  : in  std_logic;
      oimm_readnotwrite  : in  std_logic := '1';
      oimm_writedata     : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '-');
      oimm_readdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
      oimm_readdatavalid : out std_logic;
      oimm_waitrequest   : out std_logic;

      --Cache interface Orca-internal memory-mapped master
      cacheint_oimm_address       : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      cacheint_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      cacheint_oimm_requestvalid  : out std_logic;
      cacheint_oimm_readnotwrite  : out std_logic;
      cacheint_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      cacheint_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      cacheint_oimm_readdatavalid : in  std_logic;
      cacheint_oimm_waitrequest   : in  std_logic;

      --Uncached Orca-internal memory-mapped master
      uc_oimm_address       : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      uc_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      uc_oimm_requestvalid  : out std_logic;
      uc_oimm_readnotwrite  : out std_logic;
      uc_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      uc_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      uc_oimm_readdatavalid : in  std_logic;
      uc_oimm_waitrequest   : in  std_logic;

      --Tightly-coupled memory Orca-internal memory-mapped master
      aux_oimm_address       : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      aux_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      aux_oimm_requestvalid  : out std_logic;
      aux_oimm_readnotwrite  : out std_logic;
      aux_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      aux_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      aux_oimm_readdatavalid : in  std_logic;
      aux_oimm_waitrequest   : in  std_logic
      );
  end component;

  component oimm_register is
    generic (
      ADDRESS_WIDTH    : positive;
      DATA_WIDTH       : positive;
      MAX_BURSTLENGTH  : positive := 2;
      REQUEST_REGISTER : natural range 0 to 2;
      RETURN_REGISTER  : natural range 0 to 1
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      register_idle : out std_logic;

      --Orca-internal memory-mapped slave
      slave_oimm_address            : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      slave_oimm_burstlength        : in  std_logic_vector(log2(MAX_BURSTLENGTH+1)-1 downto 0) := (0      => '1', others => '0');
      slave_oimm_burstlength_minus1 : in  std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0)   := (others => '0');
      slave_oimm_byteenable         : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      slave_oimm_requestvalid       : in  std_logic;
      slave_oimm_readnotwrite       : in  std_logic;
      slave_oimm_writedata          : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      slave_oimm_writelast          : in  std_logic                                            := '1';
      slave_oimm_readdata           : out std_logic_vector(DATA_WIDTH-1 downto 0);
      slave_oimm_readdatavalid      : out std_logic;
      slave_oimm_waitrequest        : out std_logic;

      --Orca-internal memory-mapped master
      master_oimm_address            : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
      master_oimm_burstlength        : out std_logic_vector(log2(MAX_BURSTLENGTH+1)-1 downto 0);
      master_oimm_burstlength_minus1 : out std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
      master_oimm_byteenable         : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
      master_oimm_requestvalid       : out std_logic;
      master_oimm_readnotwrite       : out std_logic;
      master_oimm_writedata          : out std_logic_vector(DATA_WIDTH-1 downto 0);
      master_oimm_writelast          : out std_logic;
      master_oimm_readdata           : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      master_oimm_readdatavalid      : in  std_logic;
      master_oimm_waitrequest        : in  std_logic
      );
  end component;

  component oimm_throttler is
    generic (
      MAX_OUTSTANDING_REQUESTS : natural
      );
    port (
      clk   : in std_logic;
      reset : in std_logic;

      throttler_idle : out std_logic;

      --Orca-internal memory-mapped slave
      slave_oimm_requestvalid : in  std_logic;
      slave_oimm_readnotwrite : in  std_logic;
      slave_oimm_writelast    : in  std_logic;
      slave_oimm_waitrequest  : out std_logic;

      --Orca-internal memory-mapped master
      master_oimm_requestvalid  : out std_logic;
      master_oimm_readcomplete  : in  std_logic;
      master_oimm_writecomplete : in  std_logic;
      master_oimm_waitrequest   : in  std_logic
      );
  end component;

  component bram_sdp_write_first is
    generic (
      DEPTH                 : positive;
      WIDTH                 : positive;
      WRITE_FIRST_SUPPORTED : boolean
      );
    port (
      clk           : in  std_logic;
      read_address  : in  std_logic_vector(log2(DEPTH)-1 downto 0);
      read_data     : out std_logic_vector(WIDTH-1 downto 0);
      write_address : in  std_logic_vector(log2(DEPTH)-1 downto 0);
      write_enable  : in  std_logic;
      write_data    : in  std_logic_vector(WIDTH-1 downto 0)
      );
  end component;


end package rv_components;
