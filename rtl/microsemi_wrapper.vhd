library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.rv_components.all;

entity microsemi_wrapper is
  generic
    (
      REGISTER_SIZE         : integer                     := 32;
      RESET_VECTOR          : natural                     := 16#00000000#;
      INTERRUPT_VECTOR      : natural                     := 16#00000200#;
      MULTIPLY_ENABLE       : natural range 0 to 1        := 1;
      DIVIDE_ENABLE         : natural range 0 to 1        := 1;
      SHIFTER_MAX_CYCLES    : natural                     := 1;
      COUNTER_LENGTH        : natural                     := 32;
      ENABLE_EXCEPTIONS     : natural                     := 1;
      BRANCH_PREDICTORS     : natural                     := 0;
      PIPELINE_STAGES       : natural range 4 to 5        := 5;
      LVE_ENABLE            : natural range 0 to 1        := 0;
      ENABLE_EXT_INTERRUPTS : natural range 0 to 1        := 0;
      NUM_EXT_INTERRUPTS    : natural range 1 to 32       := 1;
      SCRATCHPAD_ADDR_BITS  : integer                     := 10;
      IUC_ADDR_BASE         : natural                     := 0;
      IUC_ADDR_LAST         : natural                     := 0;
      ICACHE_SIZE           : natural                     := 0;
      ICACHE_LINE_SIZE      : integer range 16 to 256     := 32;
      ICACHE_EXTERNAL_WIDTH : integer                     := 32;
      ICACHE_BURST_EN       : integer                     := 0;
      POWER_OPTIMIZED       : integer range 0 to 1        := 0;
      TCRAM_SIZE            : natural range 8192 to 65536 := 65536
      );
  port (
    clk    : in std_logic;
    clk_2x : in std_logic;
    reset  : in std_logic;

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

    ram_AWID    : in std_logic_vector(3 downto 0);
    ram_AWADDR  : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    ram_AWLEN   : in std_logic_vector(3 downto 0);
    ram_AWSIZE  : in std_logic_vector(2 downto 0);
    ram_AWBURST : in std_logic_vector(1 downto 0);

    ram_AWLOCK  : in  std_logic_vector(1 downto 0);
    ram_AWCACHE : in  std_logic_vector(3 downto 0);
    ram_AWPROT  : in  std_logic_vector(2 downto 0);
    ram_AWVALID : in  std_logic;
    ram_AWREADY : out std_logic;

    ram_WID    : in  std_logic_vector(3 downto 0);
    ram_WDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    ram_WSTRB  : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    ram_WLAST  : in  std_logic;
    ram_WVALID : in  std_logic;
    ram_WREADY : out std_logic;

    ram_BID    : out std_logic_vector(3 downto 0);
    ram_BRESP  : out std_logic_vector(1 downto 0);
    ram_BVALID : out std_logic;
    ram_BREADY : in  std_logic;

    ram_ARID    : in  std_logic_vector(3 downto 0);
    ram_ARADDR  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    ram_ARLEN   : in  std_logic_vector(3 downto 0);
    ram_ARSIZE  : in  std_logic_vector(2 downto 0);
    ram_ARBURST : in  std_logic_vector(1 downto 0);
    ram_ARLOCK  : in  std_logic_vector(1 downto 0);
    ram_ARCACHE : in  std_logic_vector(3 downto 0);
    ram_ARPROT  : in  std_logic_vector(2 downto 0);
    ram_ARVALID : in  std_logic;
    ram_ARREADY : out std_logic;

    ram_RID    : out std_logic_vector(3 downto 0);
    ram_RDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    ram_RRESP  : out std_logic_vector(1 downto 0);
    ram_RLAST  : out std_logic;
    ram_RVALID : out std_logic;
    ram_RREADY : in  std_logic;

    -- INSTRUCTION 
    -- state machine feeds into mux (include SEL)
    -- avalon feeds into mux
    -- mux feeds into RAM

    -- INSTRUCTION NVM INPUT
    -- feeds into state machine so init can access IRAM
    nvm_PADDR   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    nvm_PENABLE : in  std_logic;
    nvm_PWRITE  : in  std_logic;
    nvm_PRDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    nvm_PWDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    nvm_PREADY  : out std_logic;
    nvm_PSEL    : in  std_logic
    );
end entity microsemi_wrapper;

architecture rtl of microsemi_wrapper is
  signal orca_reset : std_logic;

  signal IUC_AWID    : std_logic_vector(3 downto 0);
  signal IUC_AWADDR  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal IUC_AWLEN   : std_logic_vector(3 downto 0);
  signal IUC_AWSIZE  : std_logic_vector(2 downto 0);
  signal IUC_AWBURST : std_logic_vector(1 downto 0);
  signal IUC_AWLOCK  : std_logic_vector(1 downto 0);
  signal IUC_AWCACHE : std_logic_vector(3 downto 0);
  signal IUC_AWPROT  : std_logic_vector(2 downto 0);
  signal IUC_AWVALID : std_logic;
  signal IUC_AWREADY : std_logic;
  signal IUC_WID     : std_logic_vector(3 downto 0);
  signal IUC_WDATA   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal IUC_WSTRB   : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal IUC_WLAST   : std_logic;
  signal IUC_WVALID  : std_logic;
  signal IUC_WREADY  : std_logic;
  signal IUC_BID     : std_logic_vector(3 downto 0);
  signal IUC_BRESP   : std_logic_vector(1 downto 0);
  signal IUC_BVALID  : std_logic;
  signal IUC_BREADY  : std_logic;
  signal IUC_ARID    : std_logic_vector(3 downto 0);
  signal IUC_ARADDR  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal IUC_ARLEN   : std_logic_vector(3 downto 0);
  signal IUC_ARSIZE  : std_logic_vector(2 downto 0);
  signal IUC_ARBURST : std_logic_vector(1 downto 0);
  signal IUC_ARLOCK  : std_logic_vector(1 downto 0);
  signal IUC_ARCACHE : std_logic_vector(3 downto 0);
  signal IUC_ARPROT  : std_logic_vector(2 downto 0);
  signal IUC_ARVALID : std_logic;
  signal IUC_ARREADY : std_logic;
  signal IUC_RID     : std_logic_vector(3 downto 0);
  signal IUC_RDATA   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal IUC_RRESP   : std_logic_vector(1 downto 0);
  signal IUC_RLAST   : std_logic;
  signal IUC_RVALID  : std_logic;
  signal IUC_RREADY  : std_logic;

  -- APB bus
  signal nvm_addr     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal nvm_wdata    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal nvm_wen      : std_logic;
  signal nvm_byte_sel : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal nvm_strb     : std_logic;
  signal nvm_ack      : std_logic;
  signal nvm_rdata    : std_logic_vector(REGISTER_SIZE-1 downto 0);

  -- INSTR MUX
  signal SEL               : std_logic;
  signal iram_addr         : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal iram_wdata        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal iram_wen          : std_logic;
  signal iram_byte_sel     : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal iram_strb         : std_logic;
  signal iram_ack          : std_logic;
  signal iram_rdata        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ram_addr     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ram_wdata    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ram_wen      : std_logic;
  signal data_ram_byte_sel : std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
  signal data_ram_strb     : std_logic;
  signal data_ram_ack      : std_logic;
  signal data_ram_rdata    : std_logic_vector(REGISTER_SIZE-1 downto 0);

  -- AXI Bus signals 
  signal ARESETN       : std_logic;
  signal data_sel      : std_logic;
  signal data_sel_prev : std_logic;

  constant BURST_LEN    : std_logic_vector(3 downto 0) := "0001";
  constant BURST_SIZE   : std_logic_vector(2 downto 0) := "010";
  constant BURST_FIXED  : std_logic_vector(1 downto 0) := "00";
  constant DATA_ACCESS  : std_logic_vector(2 downto 0) := "001";
  constant INSTR_ACCESS : std_logic_vector(2 downto 0) := "101";
  constant NORMAL_MEM   : std_logic_vector(3 downto 0) := "0011";

begin

  ARESETN <= not reset;

  rv : entity work.orca(rtl)
    generic map (
      REGISTER_SIZE         => REGISTER_SIZE,
      AVALON_ENABLE         => 0,
      WISHBONE_ENABLE       => 0,
      AXI_ENABLE            => 1,
      RESET_VECTOR          => std_logic_vector(to_unsigned(RESET_VECTOR, 32)),
      INTERRUPT_VECTOR      => std_logic_vector(to_unsigned(INTERRUPT_VECTOR, 32)),
      MULTIPLY_ENABLE       => MULTIPLY_ENABLE,
      DIVIDE_ENABLE         => DIVIDE_ENABLE,
      SHIFTER_MAX_CYCLES    => SHIFTER_MAX_CYCLES,
      COUNTER_LENGTH        => COUNTER_LENGTH,
      ENABLE_EXCEPTIONS     => ENABLE_EXCEPTIONS,
      BRANCH_PREDICTORS     => BRANCH_PREDICTORS,
      PIPELINE_STAGES       => PIPELINE_STAGES,
      LVE_ENABLE            => LVE_ENABLE,
      ENABLE_EXT_INTERRUPTS => ENABLE_EXT_INTERRUPTS,
      NUM_EXT_INTERRUPTS    => NUM_EXT_INTERRUPTS,
      SCRATCHPAD_ADDR_BITS  => SCRATCHPAD_ADDR_BITS,
      IUC_ADDR_BASE         => std_logic_vector(to_unsigned(IUC_ADDR_BASE, 32)),
      IUC_ADDR_LAST         => std_logic_vector(to_unsigned(IUC_ADDR_BASE, 32)),
      ICACHE_SIZE           => ICACHE_SIZE,
      ICACHE_LINE_SIZE      => ICACHE_LINE_SIZE,
      ICACHE_BURST_EN       => ICACHE_BURST_EN,
      POWER_OPTIMIZED       => POWER_OPTIMIZED,
      -- Hardcoded because string generics are not supported by Libero.
      FAMILY                => "MICROSEMI")
    port map (
      clk            => clk,
      scratchpad_clk => clk_2x,
      reset          => orca_reset,  -- While the iram is being initialized, don't start.

      avm_data_address       => open,
      avm_data_byteenable    => open,
      avm_data_read          => open,
      avm_data_readdata      => (others => '-'),
      avm_data_write         => open,
      avm_data_writedata     => open,
      avm_data_waitrequest   => '-',
      avm_data_readdatavalid => '-',

      avm_instruction_address       => open,
      avm_instruction_read          => open,
      avm_instruction_readdata      => open,
      avm_instruction_waitrequest   => '-',
      avm_instruction_readdatavalid => open,

      data_ADR_O   => open,
      data_DAT_I   => (others => '-'),
      data_DAT_O   => open,
      data_WE_O    => open,
      data_SEL_O   => open,
      data_STB_O   => open,
      data_ACK_I   => '-',
      data_CYC_O   => open,
      data_CTI_O   => open,
      data_STALL_I => '-',

      instr_ADR_O   => open,
      instr_DAT_I   => (others => '-'),
      instr_STB_O   => open,
      instr_ACK_I   => '-',
      instr_CYC_O   => open,
      instr_CTI_O   => open,
      instr_STALL_I => '-',

      DUC_AWID    => DUC_AWID,
      DUC_AWADDR  => DUC_AWADDR,
      DUC_AWLEN   => DUC_AWLEN,
      DUC_AWSIZE  => DUC_AWSIZE,
      DUC_AWBURST => DUC_AWBURST,
      DUC_AWLOCK  => DUC_AWLOCK,
      DUC_AWCACHE => DUC_AWCACHE,
      DUC_AWPROT  => DUC_AWPROT,
      DUC_AWVALID => DUC_AWVALID,
      DUC_AWREADY => DUC_AWREADY,

      DUC_WID    => DUC_WID,
      DUC_WDATA  => DUC_WDATA,
      DUC_WSTRB  => DUC_WSTRB,
      DUC_WLAST  => DUC_WLAST,
      DUC_WVALID => DUC_WVALID,
      DUC_WREADY => DUC_WREADY,

      DUC_BID    => DUC_BID,
      DUC_BRESP  => DUC_BRESP,
      DUC_BVALID => DUC_BVALID,
      DUC_BREADY => DUC_BREADY,

      DUC_ARID    => DUC_ARID,
      DUC_ARADDR  => DUC_ARADDR,
      DUC_ARLEN   => DUC_ARLEN,
      DUC_ARSIZE  => DUC_ARSIZE,
      DUC_ARBURST => DUC_ARBURST,
      DUC_ARLOCK  => DUC_ARLOCK,
      DUC_ARCACHE => DUC_ARCACHE,
      DUC_ARPROT  => DUC_ARPROT,
      DUC_ARVALID => DUC_ARVALID,
      DUC_ARREADY => DUC_ARREADY,

      DUC_RID    => DUC_RID,
      DUC_RDATA  => DUC_RDATA,
      DUC_RRESP  => DUC_RRESP,
      DUC_RLAST  => DUC_RLAST,
      DUC_RVALID => DUC_RVALID,
      DUC_RREADY => DUC_RREADY,

      IUC_ARID    => IUC_ARID,
      IUC_ARADDR  => IUC_ARADDR,
      IUC_ARLEN   => IUC_ARLEN,
      IUC_ARSIZE  => IUC_ARSIZE,
      IUC_ARBURST => IUC_ARBURST,
      IUC_ARLOCK  => IUC_ARLOCK,
      IUC_ARCACHE => IUC_ARCACHE,
      IUC_ARPROT  => IUC_ARPROT,
      IUC_ARVALID => IUC_ARVALID,
      IUC_ARREADY => IUC_ARREADY,

      IUC_RID    => IUC_RID,
      IUC_RDATA  => IUC_RDATA,
      IUC_RRESP  => IUC_RRESP,
      IUC_RLAST  => IUC_RLAST,
      IUC_RVALID => IUC_RVALID,
      IUC_RREADY => IUC_RREADY,

      IUC_AWID    => IUC_AWID,
      IUC_AWADDR  => IUC_AWADDR,
      IUC_AWLEN   => IUC_AWLEN,
      IUC_AWSIZE  => IUC_AWSIZE,
      IUC_AWBURST => IUC_AWBURST,
      IUC_AWLOCK  => IUC_AWLOCK,
      IUC_AWCACHE => IUC_AWCACHE,
      IUC_AWPROT  => IUC_AWPROT,
      IUC_AWVALID => IUC_AWVALID,
      IUC_AWREADY => IUC_AWREADY,

      IUC_WID    => IUC_WID,
      IUC_WDATA  => IUC_WDATA,
      IUC_WSTRB  => IUC_WSTRB,
      IUC_WLAST  => IUC_WLAST,
      IUC_WVALID => IUC_WVALID,
      IUC_WREADY => IUC_WREADY,

      IUC_BID    => IUC_BID,
      IUC_BRESP  => IUC_BRESP,
      IUC_BVALID => IUC_BVALID,
      IUC_BREADY => IUC_BREADY,

      IC_ARID    => open,
      IC_ARADDR  => open,
      IC_ARLEN   => open,
      IC_ARSIZE  => open,
      IC_ARBURST => open,
      IC_ARLOCK  => open,
      IC_ARCACHE => open,
      IC_ARPROT  => open,
      IC_ARVALID => open,
      IC_ARREADY => '-',

      IC_RID    => (others => '-'),
      IC_RDATA  => (others => '-'),
      IC_RRESP  => (others => '-'),
      IC_RLAST  => '-',
      IC_RVALID => '-',
      IC_RREADY => open,

      IC_AWID    => open,
      IC_AWADDR  => open,
      IC_AWLEN   => open,
      IC_AWSIZE  => open,
      IC_AWBURST => open,
      IC_AWLOCK  => open,
      IC_AWCACHE => open,
      IC_AWPROT  => open,
      IC_AWVALID => open,
      IC_AWREADY => '-',

      IC_WID    => open,
      IC_WDATA  => open,
      IC_WSTRB  => open,
      IC_WLAST  => open,
      IC_WVALID => open,
      IC_WREADY => '-',

      IC_BID    => (others => '-'),
      IC_BRESP  => (others => '-'),
      IC_BVALID => '-',
      IC_BREADY => open,

      avm_scratch_address       => (others => '-'),
      avm_scratch_byteenable    => (others => '-'),
      avm_scratch_read          => '-',
      avm_scratch_readdata      => open,
      avm_scratch_write         => '-',
      avm_scratch_writedata     => (others => '-'),
      avm_scratch_waitrequest   => open,
      avm_scratch_readdatavalid => open,

      sp_ADR_I   => (others => '-'),
      sp_DAT_O   => open,
      sp_DAT_I   => (others => '-'),
      sp_WE_I    => '-',
      sp_SEL_I   => (others => '-'),
      sp_STB_I   => '-',
      sp_ACK_O   => open,
      sp_CYC_I   => '-',
      sp_CTI_I   => (others => '-'),
      sp_STALL_O => open,

      global_interrupts => (others => '0')
      );

  mux : entity work.ram_mux(rtl)
    generic map (
      ADDRESS_WIDTH => REGISTER_SIZE,
      DATA_WIDTH    => REGISTER_SIZE
      )
    port map (
      nvm_addr     => nvm_addr,
      nvm_wdata    => nvm_wdata,
      nvm_wen      => nvm_wen,
      nvm_byte_sel => nvm_byte_sel,
      nvm_strb     => nvm_strb,
      nvm_ack      => nvm_ack,
      nvm_rdata    => nvm_rdata,

      user_ARREADY => IUC_ARREADY,
      user_ARADDR  => IUC_ARADDR,
      user_ARVALID => IUC_ARVALID,

      user_RREADY => IUC_RREADY,
      user_RDATA  => IUC_RDATA,
      user_RVALID => IUC_RVALID,

      user_AWADDR  => IUC_AWADDR,
      user_AWVALID => IUC_AWVALID,
      user_AWREADY => IUC_AWREADY,

      user_WDATA  => IUC_WDATA,
      user_WVALID => IUC_WVALID,

      user_BREADY => IUC_BREADY,
      user_BVALID => IUC_BVALID,

      SEL          => SEL,
      ram_addr     => iram_addr,
      ram_wdata    => iram_wdata,
      ram_wen      => iram_wen,
      ram_byte_sel => iram_byte_sel,
      ram_strb     => iram_strb,
      ram_ack      => iram_ack,
      ram_rdata    => iram_rdata
      );

  apb_bus : entity work.apb_to_ram(rtl)
    generic map (
      REGISTER_SIZE => REGISTER_SIZE,
      RAM_SIZE      => TCRAM_SIZE
      )
    port map (
      reset        => reset,
      clk          => clk,
      SEL          => SEL,
      nvm_PADDR    => nvm_PADDR,
      nvm_PENABLE  => nvm_PENABLE,
      nvm_PWRITE   => nvm_PWRITE,
      nvm_PRDATA   => nvm_PRDATA,
      nvm_PWDATA   => nvm_PWDATA,
      nvm_PREADY   => nvm_PREADY,
      nvm_PSEL     => nvm_PSEL,
      nvm_addr     => nvm_addr,
      nvm_wdata    => nvm_wdata,
      nvm_wen      => nvm_wen,
      nvm_byte_sel => nvm_byte_sel,
      nvm_strb     => nvm_strb,
      nvm_ack      => nvm_ack,
      nvm_rdata    => nvm_rdata
      );

  iram : entity work.iram(rtl)
    generic map (
      SIZE      => TCRAM_SIZE,
      RAM_WIDTH => REGISTER_SIZE
      )
    port map (
      clk   => clk,
      reset => reset,

      addr     => iram_addr,
      wdata    => iram_wdata,
      wen      => iram_wen,
      byte_sel => iram_byte_sel,
      strb     => iram_strb,
      ack      => iram_ack,
      rdata    => iram_rdata,

      ram_AWID    => ram_AWID,
      ram_AWADDR  => ram_AWADDR,
      ram_AWLEN   => ram_AWLEN,
      ram_AWSIZE  => ram_AWSIZE,
      ram_AWBURST => ram_AWBURST,

      ram_AWLOCK  => ram_AWLOCK,
      ram_AWCACHE => ram_AWCACHE,
      ram_AWPROT  => ram_AWPROT,
      ram_AWVALID => ram_AWVALID,
      ram_AWREADY => ram_AWREADY,

      ram_WID    => ram_WID,
      ram_WDATA  => ram_WDATA,
      ram_WSTRB  => ram_WSTRB,
      ram_WLAST  => ram_WLAST,
      ram_WVALID => ram_WVALID,
      ram_WREADY => ram_WREADY,

      ram_BID    => ram_BID,
      ram_BRESP  => ram_BRESP,
      ram_BVALID => ram_BVALID,
      ram_BREADY => ram_BREADY,

      ram_ARID    => ram_ARID,
      ram_ARADDR  => ram_ARADDR,
      ram_ARLEN   => ram_ARLEN,
      ram_ARSIZE  => ram_ARSIZE,
      ram_ARBURST => ram_ARBURST,
      ram_ARLOCK  => ram_ARLOCK,
      ram_ARCACHE => ram_ARCACHE,
      ram_ARPROT  => ram_ARPROT,
      ram_ARVALID => ram_ARVALID,
      ram_ARREADY => ram_ARREADY,

      ram_RID    => ram_RID,
      ram_RDATA  => ram_RDATA,
      ram_RRESP  => ram_RRESP,
      ram_RLAST  => ram_RLAST,
      ram_RVALID => ram_RVALID,
      ram_RREADY => ram_RREADY
      );

  orca_reset <= reset or (not SEL);

end architecture rtl;
