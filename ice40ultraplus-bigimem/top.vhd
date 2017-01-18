library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.top_component_pkg.all;
use work.top_util_pkg.all;
use work.rv_components.all;

entity vhdl_top is
  generic (
    USE_PLL      : natural range 0 to 2 := 0;
    USE_CAM      : natural range 0 to 1 := 1;
    CAM_NUM_COLS : integer              := 48;
    CAM_NUM_ROWS : integer              := 16);
  port(

    --spi
    spi_mosi : out std_logic;
    spi_miso : in  std_logic;
    spi_ss   : out std_logic;
    spi_sclk : out std_logic;

    --uart
    txd : out std_logic;
    rxd : out std_logic;

    --led
    led : out std_logic;

    --clk
    cam_xclk  : in std_logic;
    cam_vsync : in std_logic;
    cam_href  : in std_logic;
    cam_dat   : in std_logic_vector(7 downto 0);

    --sccb
    sccb_scl : inout std_logic;
    sccb_sda : inout std_logic
    );
end entity;

architecture rtl of vhdl_top is

  constant SYSCLK_FREQ_HZ : natural := 8000000 + (8000000*USE_PLL);

  constant REGISTER_SIZE : integer := 32;

  signal reset : std_logic := '1';


  -----------------------------------------------------------------------------
  --  Connection Summary
  --
  --        |                  MASTER              |                |
  --        | cam  | flash | orca-data | orca-instr| Address        |
  -- SLAVE  |------|-------|-----------|-----------|----------------|
  -- boot   |      |       |           |     X     | 0 -0x3FF       | (bitstream-initialized)
  -- imem   |      |   X   |      X    |     X     | 0x10000-0x1FFFF|
  -- dmem   |  X   |   X   |      X    |           | 0x20000-0x2FFFF|
  -- uart   |      |       |      X    |           |                |
  -- pio    |      |       |      X    |           |                |
  -- flash  |      |       |      X    |           |                |
  -----------------------------------------------------------------------------

  constant BOOTMEM_ADDR    : integer := 0;
  constant BOOTMEM_SIZE    : integer := 1024;
  constant IMEM_ADDR       : integer := 16#10000#;
  constant IMEM_SIZE       : integer := 64*1024;
  constant DMEM_ADDR       : integer := 16#20000#;
  constant DMEM_SIZE       : integer := 64*1024;
  constant UART_ADDR       : integer := 16#100000#;
  constant UART_SIZE       : integer := 1024;
  constant PIO_ADDR        : integer := 16#110000#;
  constant PIO_SIZE        : integer := 1024;
  constant FLASH_CTRL_ADDR : integer := 16#120000#;
  constant FLASH_CTRL_SIZE : integer := 1024;

  signal instr_wb      : wishbone_bus;
  signal instr_imem_wb : wishbone_bus;

  signal spi_dmem_wb : wishbone_bus;
  signal spi_imem_wb : wishbone_bus;
  signal spi_wb      : wishbone_bus;

  signal data_wb       : wishbone_bus;
  signal data_imem_wb  : wishbone_bus;
  signal data_dmem_wb  : wishbone_bus;
  signal pio_wb        : wishbone_bus;
  signal uart_wb       : wishbone_bus;
  signal flash_ctrl_wb : wishbone_bus;

  signal cam_wb : wishbone_bus;

  signal dmem_wb : wishbone_bus;
  signal boot_wb : wishbone_bus;
  signal imem_wb : wishbone_bus;



  signal pll_lock : std_logic;

  constant DEBUG_ENABLE  : boolean := false;
  signal debug_en        : std_logic;
  signal debug_write     : std_logic;
  signal debug_writedata : std_logic_vector(7 downto 0);
  signal debug_address   : std_logic_vector(7 downto 0);

  signal serial_in  : std_logic;
  signal rxrdy_n    : std_logic;
  signal cts_n      : std_logic;
  signal serial_out : std_logic;
  signal txrdy_n    : std_logic;
  signal rts_n      : std_logic;
  signal dir_n      : std_logic;

  signal led_counter : unsigned(15 downto 0);

  signal clk        : std_logic;
  signal osc_clk    : std_logic;
  signal clk_6x_int : std_logic;
  signal clk_int    : std_logic            := '0';
  signal clk_3x_int : std_logic            := '0';
  signal clk_3x     : std_logic;
  signal clk_count  : unsigned(1 downto 0) := (others => '0');

  constant UART_ADDR_DAT         : std_logic_vector(7 downto 0) := "00000000";
  constant UART_ADDR_LSR         : std_logic_vector(7 downto 0) := "00000011";
  constant UART_LSR_8BIT_DEFAULT : std_logic_vector(7 downto 0) := "00000011";
  signal uart_stall              : std_logic;
  signal mem_instr_stall         : std_logic;
  signal mem_instr_ack           : std_logic;


  signal pll_resetn        : std_logic            := '0';
  signal auto_reset_count  : unsigned(3 downto 0) := (others => '0');
  signal auto_reset        : std_logic            := '1';
  signal auto_reset_on_clk : std_logic            := '1';
  signal reset_count       : unsigned(3 downto 0) := (others => '0');

  signal ovm_dma_start : std_logic;
  signal ovm_dma_done  : std_logic;
  signal ovm_dma_busy  : std_logic;

  signal cam_pclk : std_logic;

  signal cam_dat_internal : std_logic_vector(7 downto 0);

  signal pio_in  : std_logic_vector(7 downto 0);
  signal pio_out : std_logic_vector(7 downto 0);
  signal pio_oe  : std_logic_vector(7 downto 0);

  signal cam_aux_out : std_logic_vector(7 downto 0);

  for bootmem : wb_ram
    use entity work.wb_ram(bram);
  for dmem, imem : wb_ram
    use entity work.wb_ram(spram);



begin

  hf_osc : component osc_48MHz
    generic map (
      DIVIDER => "00")                  -- 48 MHz
    port map (
      CLKOUT => osc_clk);

  pwm_counter : process (osc_clk) is
  begin
    if rising_edge(osc_clk) then
      led_counter <= led_counter + 1;
    end if;
  end process;

  pll_3x_gen : if USE_PLL = 2 generate
    pll_x3 : SB_PLL40_CORE_wrapper_x3
      port map (
        REFERENCECLK => osc_clk,

        PLLOUTCORE      => clk_6x_int,
        PLLOUTGLOBAL    => open,
        EXTFEEDBACK     => 'X',
        DYNAMICDELAY    => (others => 'X'),
        LOCK            => pll_lock,
        BYPASS          => '0',
        RESETB          => pll_resetn,
        SDO             => open,
        SDI             => 'X',
        SCLK            => 'X',
        LATCHINPUTVALUE => 'X');
  end generate pll_3x_gen;

  pll_2x_gen : if USE_PLL = 1 generate
    pll_div3 : SB_PLL40_CORE_wrapper_div3
      port map (
        REFERENCECLK => clk_3x,

        PLLOUTCORE      => open,
        PLLOUTGLOBAL    => clk,
        EXTFEEDBACK     => clk,
        DYNAMICDELAY    => (others => 'X'),
        LOCK            => pll_lock,
        BYPASS          => '0',
        RESETB          => pll_resetn,
        SDO             => open,
        SDI             => 'X',
        SCLK            => 'X',
        LATCHINPUTVALUE => 'X');

    clk_gb : SB_GB
      port map (
        GLOBAL_BUFFER_OUTPUT         => clk_3x,
        USER_SIGNAL_TO_GLOBAL_BUFFER => osc_clk);
  end generate pll_2x_gen;

  no_pll_gen : if USE_PLL = 0 generate
    clk_6x_int <= osc_clk;
    pll_lock   <= '1';
  end generate no_pll_gen;

  logic_clock_divider_gen : if USE_PLL /= 1 generate
    process (clk_6x_int)
    begin
      if rising_edge(clk_6x_int) then
        clk_count  <= clk_count + 1;
        clk_3x_int <= not clk_3x_int;
        if clk_count = to_unsigned(2, clk_count'length) then
          clk_count <= (others => '0');
          clk_int   <= not clk_int;
        end if;
      end if;
    end process;

    clk_gb : SB_GB
      port map (
        GLOBAL_BUFFER_OUTPUT         => clk,
        USER_SIGNAL_TO_GLOBAL_BUFFER => clk_int);

    clk3x_gb : SB_GB
      port map (
        GLOBAL_BUFFER_OUTPUT         => clk_3x,
        USER_SIGNAL_TO_GLOBAL_BUFFER => clk_3x_int);
  end generate logic_clock_divider_gen;


  cam_dat_internal <= cam_dat;
  cam_pclk         <= cam_xclk;
  --REPLACE the previous SB_IO_OD with the following lines during simulation
  --cam_dat_internal <= cam_dat;
  --cam_xclk_internal <= cam_xclk;


  --Reset the PLL's on startup
  process(osc_clk)
  begin
    if rising_edge(osc_clk) then
      if auto_reset_count /= "1111" then
        auto_reset_count <= auto_reset_count +1;
        auto_reset       <= '1';
      else
        auto_reset <= '0';
      end if;
      pll_resetn <= not auto_reset;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      auto_reset_on_clk <= auto_reset or (not pll_lock);
      if auto_reset_on_clk = '1' then
        reset_count <= to_unsigned(0, reset_count'length);
        reset       <= '1';
      elsif reset_count /= "1111" then
        reset_count <= reset_count + to_unsigned(1, reset_count'length);
        reset       <= '1';
      else
        reset <= '0';
      end if;
    end if;
  end process;

  bootmem : wb_ram
    generic map(
      MEM_SIZE         => BOOTMEM_SIZE,
      INIT_FILE_FORMAT => "hex",
      INIT_FILE_NAME   => "boot.mem",
      LATTICE_FAMILY   => "iCE5LP")
    port map(
      CLK_I => clk,
      RST_I => reset,

      ADR_I  => boot_wb.ADR(log2(BOOTMEM_SIZE)-1 downto 0),
      DAT_I  => boot_wb.wdat,
      WE_I   => '0',
      CYC_I  => boot_wb.CYC,
      STB_I  => boot_wb.STB,
      SEL_I  => boot_wb.sel,
      CTI_I  => boot_wb.CTI,
      BTE_I  => boot_wb.bte,
      LOCK_I => boot_wb.lock,

      STALL_O => boot_wb.stall,
      DAT_O   => boot_wb.RDAT,
      ACK_O   => boot_wb.ACK,
      ERR_O   => boot_wb.ERR,
      RTY_O   => boot_wb.RTY);

  imem : wb_ram
    generic map(
      MEM_SIZE         => IMEM_SIZE,
      INIT_FILE_FORMAT => "hex",
      INIT_FILE_NAME   => "imem.mem",
      LATTICE_FAMILY   => "iCE5LP")
    port map(
      CLK_I => clk,
      RST_I => reset,

      ADR_I  => imem_wb.ADR(log2(IMEM_SIZE)-1 downto 0),
      DAT_I  => imem_wb.WDAT,
      WE_I   => imem_wb.WE,
      CYC_I  => imem_wb.CYC,
      STB_I  => imem_wb.STB,
      SEL_I  => imem_wb.SEL,
      CTI_I  => imem_wb.CTI,
      BTE_I  => imem_wb.BTE,
      LOCK_I => imem_wb.LOCK,

      STALL_O => imem_wb.STALL,
      DAT_O   => imem_wb.RDAT,
      ACK_O   => imem_wb.ACK,
      ERR_O   => imem_wb.ERR,
      RTY_O   => imem_wb.RTY);


  dmem : wb_ram
    generic map(
      MEM_SIZE         => DMEM_SIZE,
      INIT_FILE_FORMAT => "mem",
      INIT_FILE_NAME   => "dmem.mem",
      LATTICE_FAMILY   => "iCE5LP")
    port map(
      CLK_I => clk,
      RST_I => reset,

      ADR_I   => dmem_wb.ADR(log2(DMEM_SIZE)-1 downto 0),
      DAT_I   => dmem_wb.WDAT,
      WE_I    => dmem_wb.WE,
      CYC_I   => dmem_wb.CYC,
      STB_I   => dmem_wb.STB,
      SEL_I   => dmem_wb.SEL,
      CTI_I   => dmem_wb.CTI,
      BTE_I   => dmem_wb.BTE,
      LOCK_I  => dmem_wb.LOCK,
      STALL_O => dmem_wb.STALL,
      DAT_O   => dmem_wb.RDAT,
      ACK_O   => dmem_wb.ack,
      ERR_O   => dmem_wb.ERR,
      RTY_O   => dmem_wb.RTY);

  imem_arbiter : wb_arbiter
    port map(
      clk_i => clk,
      rst_i => reset,

      slave0_ADR_I   => spi_imem_wb.ADR,
      slave0_DAT_I   => spi_imem_wb.WDAT,
      slave0_DAT_O   => spi_imem_wb.RDAT,
      slave0_WE_I    => spi_imem_wb.WE,
      slave0_CYC_I   => spi_imem_wb.CYC,
      slave0_STB_I   => spi_imem_wb.STB,
      slave0_SEL_I   => spi_imem_wb.SEL,
      slave0_STALL_O => spi_imem_wb.STALL,
      slave0_ACK_O   => spi_imem_wb.ACK,

      slave1_ADR_I   => data_imem_wb.ADR,
      slave1_DAT_I   => data_imem_wb.WDAT,
      slave1_DAT_O   => data_imem_wb.RDAT,
      slave1_WE_I    => data_imem_wb.WE,
      slave1_CYC_I   => data_imem_wb.CYC,
      slave1_STB_I   => data_imem_wb.STB,
      slave1_SEL_I   => data_imem_wb.SEL,
      slave1_STALL_O => data_imem_wb.STALL,
      slave1_ACK_O   => data_imem_wb.ACK,

      slave2_ADR_I   => instr_imem_wb.ADR,
      slave2_DAT_I   => instr_imem_wb.WDAT,
      slave2_DAT_O   => instr_imem_wb.RDAT,
      slave2_WE_I    => instr_imem_wb.WE,
      slave2_CYC_I   => instr_imem_wb.CYC,
      slave2_STB_I   => instr_imem_wb.STB,
      slave2_SEL_I   => instr_imem_wb.SEL,
      slave2_STALL_O => instr_imem_wb.STALL,
      slave2_ACK_O   => instr_imem_wb.ACK,

      master_ADR_O   => imem_wb.ADR,
      master_DAT_O   => imem_wb.WDAT,
      master_WE_O    => imem_wb.WE,
      master_CYC_O   => imem_wb.CYC,
      master_STB_O   => imem_wb.STB,
      master_SEL_O   => imem_wb.SEL,
      master_STALL_I => imem_wb.STALL,
      master_DAT_I   => imem_wb.RDAT,
      master_ACK_I   => imem_wb.ACK);

  dmem_arbiter : wb_arbiter
    port map(

      clk_i => clk,
      rst_i => reset,

      slave0_ADR_I   => cam_wb.ADR,
      slave0_DAT_I   => cam_wb.WDAT,
      slave0_DAT_O   => cam_wb.RDAT,
      slave0_WE_I    => cam_wb.WE,
      slave0_CYC_I   => cam_wb.CYC,
      slave0_STB_I   => cam_wb.STB,
      slave0_SEL_I   => cam_wb.SEL,
      slave0_STALL_O => cam_wb.STALL,
      slave0_ACK_O   => cam_wb.ACK,

      slave1_ADR_I   => spi_dmem_wb.ADR,
      slave1_DAT_I   => spi_dmem_wb.WDAT,
      slave1_DAT_O   => spi_dmem_wb.RDAT,
      slave1_WE_I    => spi_dmem_wb.WE,
      slave1_CYC_I   => spi_dmem_wb.CYC,
      slave1_STB_I   => spi_dmem_wb.STB,
      slave1_SEL_I   => spi_dmem_wb.SEL,
      slave1_STALL_O => spi_dmem_wb.STALL,
      slave1_ACK_O   => spi_dmem_wb.ACK,

      slave2_ADR_I   => data_dmem_wb.ADR,
      slave2_DAT_I   => data_dmem_wb.WDAT,
      slave2_DAT_O   => data_dmem_wb.RDAT,
      slave2_WE_I    => data_dmem_wb.WE,
      slave2_CYC_I   => data_dmem_wb.CYC,
      slave2_STB_I   => data_dmem_wb.STB,
      slave2_SEL_I   => data_dmem_wb.SEL,
      slave2_STALL_O => data_dmem_wb.STALL,
      slave2_ACK_O   => data_dmem_wb.ACK,

      master_ADR_O   => dmem_wb.ADR,
      master_DAT_O   => dmem_wb.WDAT,
      master_WE_O    => dmem_wb.WE,
      master_CYC_O   => dmem_wb.CYC,
      master_STB_O   => dmem_wb.STB,
      master_SEL_O   => dmem_wb.SEL,
      master_STALL_I => dmem_wb.STALL,
      master_DAT_I   => dmem_wb.RDAT,
      master_ACK_I   => dmem_wb.ACK);

  flash_splitter : wb_splitter
    generic map (
      --imem
      master0_address => (IMEM_ADDR, IMEM_SIZE),
      --dmem
      master1_address => (DMEM_ADDR, DMEM_SIZE))
    port map(
      clk_i => clk,
      rst_i => reset,

      slave_ADR_I   => spi_wb.ADR,
      slave_DAT_I   => spi_wb.WDAT,
      slave_WE_I    => spi_wb.WE,
      slave_CYC_I   => spi_wb.CYC,
      slave_STB_I   => spi_wb.STB,
      slave_SEL_I   => spi_wb.SEL,
      slave_CTI_I   => spi_wb.CTI,
      slave_BTE_I   => spi_wb.BTE,
      slave_LOCK_I  => spi_wb.LOCK,
      slave_STALL_O => spi_wb.STALL,
      slave_DAT_O   => spi_wb.RDAT,
      slave_ACK_O   => spi_wb.ACK,
      slave_ERR_O   => spi_wb.ERR,
      slave_RTY_O   => spi_wb.RTY,

      master0_ADR_O   => spi_imem_wb.ADR,
      master0_DAT_O   => spi_imem_wb.WDAT,
      master0_WE_O    => spi_imem_wb.WE,
      master0_CYC_O   => spi_imem_wb.CYC,
      master0_STB_O   => spi_imem_wb.STB,
      master0_SEL_O   => spi_imem_wb.SEL,
      master0_CTI_O   => spi_imem_wb.CTI,
      master0_BTE_O   => spi_imem_wb.BTE,
      master0_LOCK_O  => spi_imem_wb.LOCK,
      master0_STALL_I => spi_imem_wb.STALL,
      master0_DAT_I   => spi_imem_wb.RDAT,
      master0_ACK_I   => spi_imem_wb.ACK,
      master0_ERR_I   => spi_imem_wb.ERR,
      master0_RTY_I   => spi_imem_wb.RTY,

      master1_ADR_O   => spi_dmem_wb.ADR,
      master1_DAT_O   => spi_dmem_wb.WDAT,
      master1_WE_O    => spi_dmem_wb.WE,
      master1_CYC_O   => spi_dmem_wb.CYC,
      master1_STB_O   => spi_dmem_wb.STB,
      master1_SEL_O   => spi_dmem_wb.SEL,
      master1_CTI_O   => spi_dmem_wb.CTI,
      master1_BTE_O   => spi_dmem_wb.BTE,
      master1_LOCK_O  => spi_dmem_wb.LOCK,
      master1_STALL_I => spi_dmem_wb.STALL,
      master1_DAT_I   => spi_dmem_wb.RDAT,
      master1_ACK_I   => spi_dmem_wb.ACK,
      master1_ERR_I   => spi_dmem_wb.ERR,
      master1_RTY_I   => spi_dmem_wb.RTY);


  rv : component orca
    generic map (
      REGISTER_SIZE      => REGISTER_SIZE,
      WISHBONE_ENABLE    => 1,
      MULTIPLY_ENABLE    => 1,
      DIVIDE_ENABLE      => 0,
      SHIFTER_MAX_CYCLES => 32,
      COUNTER_LENGTH     => 32,
      PIPELINE_STAGES    => 4,
      LVE_ENABLE         => 0,
      ENABLE_EXCEPTIONS  => 0,
      NUM_EXT_INTERRUPTS => 2,
      FAMILY             => "LATTICE")
    port map(

      clk            => clk,
      scratchpad_clk => clk_3x,
      reset          => reset,

      data_ADR_O   => data_wb.adr,
      data_DAT_I   => data_wb.rdat,
      data_DAT_O   => data_wb.wdat,
      data_WE_O    => data_wb.WE,
      data_SEL_O   => data_wb.SEL,
      data_STB_O   => data_wb.STB,
      data_ACK_I   => data_wb.ACK,
      data_CYC_O   => data_wb.CYC,
      data_STALL_I => data_wb.STALL,
      data_CTI_O   => data_wb.CTI,

      instr_ADR_O   => instr_wb.ADR,
      instr_DAT_I   => instr_wb.RDAT,
      instr_STB_O   => instr_wb.STB,
      instr_ACK_I   => instr_wb.ACK,
      instr_CYC_O   => instr_wb.CYC,
      instr_CTI_O   => instr_wb.CTI,
      instr_STALL_I => instr_wb.STALL,

      global_interrupts => (others => '0'));

  orca_data_splitter : component wb_splitter
    generic map(
      master0_address => (IMEM_ADDR, IMEM_SIZE),
      master1_address => (DMEM_ADDR, DMEM_SIZE),
      master2_address => (UART_ADDR, UART_SIZE),
      master3_address => (PIO_ADDR, PIO_SIZE),
      master4_address => (FLASH_CTRL_ADDR, FLASH_CTRL_SIZE)
      )
    port map(
      clk_i => clk,
      rst_i => reset,

      slave_ADR_I   => data_wb.ADR,
      slave_DAT_I   => data_wb.WDAT,
      slave_WE_I    => data_wb.WE,
      slave_CYC_I   => data_wb.CYC,
      slave_STB_I   => data_wb.STB,
      slave_SEL_I   => data_wb.SEL,
      slave_CTI_I   => data_wb.CTI,
      slave_BTE_I   => data_wb.BTE,
      slave_LOCK_I  => data_wb.LOCK,
      slave_STALL_O => data_wb.STALL,
      slave_DAT_O   => data_wb.RDAT,
      slave_ACK_O   => data_wb.ACK,
      slave_ERR_O   => data_wb.ERR,
      slave_RTY_O   => data_wb.RTY,

      master0_ADR_O   => data_imem_wb.ADR,
      master0_DAT_O   => data_imem_wb.WDAT,
      master0_WE_O    => data_imem_wb.WE,
      master0_CYC_O   => data_imem_wb.CYC,
      master0_STB_O   => data_imem_wb.STB,
      master0_SEL_O   => data_imem_wb.SEL,
      master0_CTI_O   => data_imem_wb.CTI,
      master0_BTE_O   => data_imem_wb.BTE,
      master0_LOCK_O  => data_imem_wb.LOCK,
      master0_STALL_I => data_imem_wb.STALL,
      master0_DAT_I   => data_imem_wb.RDAT,
      master0_ACK_I   => data_imem_wb.ACK,
      master0_ERR_I   => data_imem_wb.ERR,
      master0_RTY_I   => data_imem_wb.RTY,

      master1_ADR_O   => data_dmem_wb.ADR,
      master1_DAT_O   => data_dmem_wb.WDAT,
      master1_WE_O    => data_dmem_wb.WE,
      master1_CYC_O   => data_dmem_wb.CYC,
      master1_STB_O   => data_dmem_wb.STB,
      master1_SEL_O   => data_dmem_wb.SEL,
      master1_CTI_O   => data_dmem_wb.CTI,
      master1_BTE_O   => data_dmem_wb.BTE,
      master1_LOCK_O  => data_dmem_wb.LOCK,
      master1_STALL_I => data_dmem_wb.STALL,
      master1_DAT_I   => data_dmem_wb.RDAT,
      master1_ACK_I   => data_dmem_wb.ACK,
      master1_ERR_I   => data_dmem_wb.ERR,
      master1_RTY_I   => data_dmem_wb.RTY,

      master2_ADR_O   => uart_wb.ADR,
      master2_DAT_O   => uart_wb.WDAT,
      master2_WE_O    => uart_wb.WE,
      master2_CYC_O   => uart_wb.CYC,
      master2_STB_O   => uart_wb.STB,
      master2_SEL_O   => uart_wb.SEL,
      master2_CTI_O   => uart_wb.CTI,
      master2_BTE_O   => uart_wb.BTE,
      master2_LOCK_O  => uart_wb.LOCK,
      master2_STALL_I => uart_wb.STALL,
      master2_DAT_I   => uart_wb.RDAT,
      master2_ACK_I   => uart_wb.ACK,
      master2_ERR_I   => uart_wb.ERR,
      master2_RTY_I   => uart_wb.RTY,

      master3_ADR_O   => pio_wb.ADR,
      master3_DAT_O   => pio_wb.WDAT,
      master3_WE_O    => pio_wb.WE,
      master3_CYC_O   => pio_wb.CYC,
      master3_STB_O   => pio_wb.STB,
      master3_SEL_O   => pio_wb.SEL,
      master3_CTI_O   => pio_wb.CTI,
      master3_BTE_O   => pio_wb.BTE,
      master3_LOCK_O  => pio_wb.LOCK,
      master3_STALL_I => pio_wb.STALL,
      master3_DAT_I   => pio_wb.RDAT,
      master3_ACK_I   => pio_wb.ACK,
      master3_ERR_I   => pio_wb.ERR,
      master3_RTY_I   => pio_wb.RTY,

      master4_ADR_O   => flash_ctrl_wb.ADR,
      master4_DAT_O   => flash_ctrl_wb.WDAT,
      master4_WE_O    => flash_ctrl_wb.WE,
      master4_CYC_O   => flash_ctrl_wb.CYC,
      master4_STB_O   => flash_ctrl_wb.STB,
      master4_SEL_O   => flash_ctrl_wb.SEL,
      master4_CTI_O   => flash_ctrl_wb.CTI,
      master4_BTE_O   => flash_ctrl_wb.BTE,
      master4_LOCK_O  => flash_ctrl_wb.LOCK,
      master4_STALL_I => flash_ctrl_wb.STALL,
      master4_DAT_I   => flash_ctrl_wb.RDAT,
      master4_ACK_I   => flash_ctrl_wb.ACK,
      master4_ERR_I   => flash_ctrl_wb.ERR,
      master4_RTY_I   => flash_ctrl_wb.RTY);
  orca_instr_splitter : component wb_splitter
    generic map(
      master0_address => (BOOTMEM_ADDR,BOOTMEM_SIZE),
      master1_address => (IMEM_ADDR, IMEM_SIZE)
      )
    port map (
      clk_i => clk,
      rst_i => reset,

      slave_ADR_I   => instr_wb.ADR,
      slave_DAT_I   => instr_wb.WDAT,
      slave_WE_I    => instr_wb.WE,
      slave_CYC_I   => instr_wb.CYC,
      slave_STB_I   => instr_wb.STB,
      slave_SEL_I   => instr_wb.SEL,
      slave_CTI_I   => instr_wb.CTI,
      slave_BTE_I   => instr_wb.BTE,
      slave_LOCK_I  => instr_wb.LOCK,
      slave_STALL_O => instr_wb.STALL,
      slave_DAT_O   => instr_wb.RDAT,
      slave_ACK_O   => instr_wb.ACK,
      slave_ERR_O   => instr_wb.ERR,
      slave_RTY_O   => instr_wb.RTY,

      master0_ADR_O   => boot_wb.ADR,
      master0_DAT_O   => boot_wb.WDAT,
      master0_WE_O    => boot_wb.WE,
      master0_CYC_O   => boot_wb.CYC,
      master0_STB_O   => boot_wb.STB,
      master0_SEL_O   => boot_wb.SEL,
      master0_CTI_O   => boot_wb.CTI,
      master0_BTE_O   => boot_wb.BTE,
      master0_LOCK_O  => boot_wb.LOCK,
      master0_STALL_I => boot_wb.STALL,
      master0_DAT_I   => boot_wb.RDAT,
      master0_ACK_I   => boot_wb.ACK,
      master0_ERR_I   => boot_wb.ERR,
      master0_RTY_I   => boot_wb.RTY,

      master1_ADR_O   => instr_imem_wb.ADR,
      master1_DAT_O   => instr_imem_wb.WDAT,
      master1_WE_O    => instr_imem_wb.WE,
      master1_CYC_O   => instr_imem_wb.CYC,
      master1_STB_O   => instr_imem_wb.STB,
      master1_SEL_O   => instr_imem_wb.SEL,
      master1_CTI_O   => instr_imem_wb.CTI,
      master1_BTE_O   => instr_imem_wb.BTE,
      master1_LOCK_O  => instr_imem_wb.LOCK,
      master1_STALL_I => instr_imem_wb.STALL,
      master1_DAT_I   => instr_imem_wb.RDAT,
      master1_ACK_I   => instr_imem_wb.ACK,
      master1_ERR_I   => instr_imem_wb.ERR,
      master1_RTY_I   => instr_imem_wb.RTY);

  the_spi : wb_flash_dma
    generic map(
      MAX_LENGTH => 1024*1024)
    port map(
      clk_i         => clk,
      rst_i         => reset,
      slave_ADR_I   => flash_ctrl_wb.ADR(3 downto 0),
      slave_DAT_O   => flash_ctrl_wb.RDAT,
      slave_DAT_I   => flash_ctrl_wb.wDAT,
      slave_WE_I    => flash_ctrl_wb.WE,
      slave_SEL_I   => flash_ctrl_wb.SEL,
      slave_STB_I   => flash_ctrl_wb.STB,
      slave_ACK_O   => flash_ctrl_wb.ACK,
      slave_CYC_I   => flash_ctrl_wb.CYC,
      slave_CTI_I   => flash_ctrl_wb.CTI,
      slave_STALL_O => flash_ctrl_wb.STALL,

      master_ADR_O   => spi_wb.ADR,
      master_DAT_I   => spi_wb.RDAT,
      master_DAT_O   => spi_wb.WDAT,
      master_WE_O    => spi_wb.WE,
      master_SEL_O   => spi_wb.SEL,
      master_STB_O   => spi_wb.STB,
      master_ACK_I   => spi_wb.ACK,
      master_CYC_O   => spi_wb.CYC,
      master_CTI_O   => spi_wb.CTI,
      master_STALL_I => spi_wb.STALL,

      spi_mosi => spi_mosi,
      spi_miso => spi_miso,
      spi_ss   => spi_ss,
      spi_sclk => spi_sclk
      );

  the_pio : wb_pio
    generic map (
      DATA_WIDTH => 8
      )
    port map(
      clk_i => clk,
      rst_i => reset,

      adr_i   => pio_wb.adr,
      dat_i   => pio_wb.wdat(7 downto 0),
      we_i    => pio_wb.we,
      cyc_i   => pio_wb.cyc,
      stb_i   => pio_wb.stb,
      sel_i   => pio_wb.sel,
      cti_i   => pio_wb.cti,
      bte_i   => pio_wb.bte,
      lock_i  => pio_wb.lock,
      ack_o   => pio_wb.ack,
      stall_o => pio_wb.stall,
      data_o  => pio_wb.rdat(7 downto 0),
      err_o   => pio_wb.err,
      rty_o   => pio_wb.rty,

      output    => pio_out,
      output_en => pio_oe,
      input     => pio_in

      );
  pio_wb.rdat(pio_wb.rdat'left downto 8) <= (others => '0');

  sccb_sda  <= pio_out(0) when pio_oe(0) = '1' else 'Z';
  pio_in(0) <= sccb_sda;

  sccb_scl  <= pio_out(1) when pio_oe(1) = '1' else 'Z';
  pio_in(1) <= sccb_scl;

  ovm_dma_start <= pio_out(2);
  pio_in(2)     <= pio_out(2);

  pio_in(3)    <= ovm_dma_busy;
  ovm_dma_busy <= '1' when ovm_dma_done = '0' else '0';

  led       <= pio_out(4) and led_counter(15) and led_counter(14);
  pio_in(4) <= pio_out(4);

  pio_in(7 downto 5) <= pio_out(7 downto 5);

  no_cam_gen : if USE_CAM = 0 generate

    cam_wb.ADR <= (others => '0');
    cam_wb.WDAT <= (others => '0');
    cam_wb.WE  <= '0';
    cam_wb.SEL <= (others => '0');
    cam_wb.STB <= '0';
    cam_wb.CYC <= '0';
    cam_wb.CTI <= (others => '0');
    ovm_dma_done <= '1';
    cam_aux_out  <= (others => '0');
  end generate no_cam_gen;
  cam_gen : if USE_CAM /= 0 generate
    with pio_out(7 downto 5) select
      rxd <=
      cam_aux_out(0) when "000",
      cam_aux_out(1) when "001",
      cam_aux_out(2) when "010",
      cam_aux_out(3) when "011",
      cam_aux_out(4) when "100",
      cam_aux_out(5) when "101",
      cam_aux_out(6) when "110",
      cam_aux_out(7) when others;
    cam_ctrl : wb_cam
      port map(
        clk_i => clk,
        rst_i => reset,

        master_ADR_O   => cam_wb.ADR,
        master_DAT_O   => cam_wb.WDAT,
        master_WE_O    => cam_wb.WE,
        master_SEL_O   => cam_wb.SEL,
        master_STB_O   => cam_wb.STB,
        master_CYC_O   => cam_wb.CYC,
        master_CTI_O   => cam_wb.CTI,
        master_STALL_I => cam_wb.STALL,

        --pio control signals
        cam_start => ovm_dma_start,
        cam_done  => ovm_dma_done,

        --camera signals
        ovm_pclk    => cam_pclk,
        ovm_vsync   => cam_vsync,
        ovm_href    => cam_href,
        ovm_dat     => cam_dat_internal,
        cam_aux_out => cam_aux_out
        );
  end generate cam_gen;
  -----------------------------------------------------------------------------
  -- UART signals and interface
  -----------------------------------------------------------------------------
  --cts_n     <= cts;
  txd       <= serial_out;
  serial_in <= '0';
  --rts       <= rts_n;
  uart_wb.stall <= not uart_wb.ack;

  the_uart : uart_core
    generic map (
      CLK_IN_MHZ => (SYSCLK_FREQ_HZ+500000)/1000000,
      BAUD_RATE  => 115200,
      ADDRWIDTH  => 3,
      DATAWIDTH  => 8,
      MODEM_B    => false,              --true by default...
      FIFO       => false
      )
    port map (
                                        -- Global reset and clock
      CLK        => clk,
      RESET      => reset,
                                        -- WISHBONE interface
      UART_ADR_I => uart_wb.adr(9 downto 2),
      UART_DAT_I => uart_wb.wdat(15 downto 0),
      UART_DAT_O => uart_wb.rdat(15 downto 0),
      UART_STB_I => uart_wb.stb,
      UART_CYC_I => uart_wb.cyc,
      UART_WE_I  => uart_wb.we,
      UART_SEL_I => uart_wb.sel,
      UART_CTI_I => uart_wb.cti,
      UART_BTE_I => uart_wb.bte,
      UART_ACK_O => uart_wb.ack,
      --INTR       => uart_interrupt,
                                        -- Receiver interface
      SIN        => serial_in,
      RXRDY_N    => rxrdy_n,
                                        -- MODEM
      DCD_N      => '1',
      CTS_N      => cts_n,
      DSR_N      => '1',
      RI_N       => '1',
      DTR_N      => dir_n,
      RTS_N      => rts_n,
                                        -- Transmitter interface
      SOUT       => serial_out,
      TXRDY_N    => txrdy_n
      );

end architecture rtl;
