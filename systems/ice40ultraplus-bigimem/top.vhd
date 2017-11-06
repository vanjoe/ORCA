library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.top_component_pkg.all;
use work.top_util_pkg.all;
use work.rv_components.all;

entity vhdl_top is
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
    led : out std_logic
    );
end entity;

architecture rtl of vhdl_top is

  constant SYSCLK_FREQ_HZ : natural := 24000000;

  constant REGISTER_SIZE : integer := 32;

  signal reset : std_logic := '1';


  -----------------------------------------------------------------------------
  --  Connection Summary
  --
  --        |           MASTER              |                |
  --        | flash | orca-data | orca-instr| Address        |
  -- SLAVE  |-------|-----------|-----------|----------------|
  -- boot   |       |           |     X     | 0 -0x3FF       | (bitstream-initialized)
  -- imem   |   X   |      X    |     X     | 0x10000-0x1FFFF|
  -- dmem   |   X   |      X    |           | 0x20000-0x2FFFF|
  -- uart   |       |      X    |           | 0x30000-0x3FFFF|
  -- pio    |       |      X    |           | 0x40000-0x4FFFF|
  -- flash  |       |      X    |           | 0x50000-0x5FFFF|
  ----------------------------------------------------------------------

  constant BOOTMEM_ADDR    : integer := 0;
  constant BOOTMEM_SIZE    : integer := 1024;
  constant IMEM_ADDR       : integer := 16#10000#;
  constant IMEM_SIZE       : integer := 64*1024;
  constant DMEM_ADDR       : integer := 16#20000#;
  constant DMEM_SIZE       : integer := 64*1024;
  constant UART_ADDR       : integer := 16#30000#;
  constant UART_SIZE       : integer := 1024;
  constant PIO_ADDR        : integer := 16#40000#;
  constant PIO_SIZE        : integer := 1024;
  constant FLASH_CTRL_ADDR : integer := 16#50000#;
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

  signal dmem_wb : wishbone_bus;
  signal boot_wb : wishbone_bus;
  signal imem_wb : wishbone_bus;




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

  signal clk     : std_logic;
  signal osc_clk : std_logic;

  constant UART_ADDR_DAT         : std_logic_vector(7 downto 0) := "00000000";
  constant UART_ADDR_LSR         : std_logic_vector(7 downto 0) := "00000011";
  constant UART_LSR_8BIT_DEFAULT : std_logic_vector(7 downto 0) := "00000011";
  signal uart_stall              : std_logic;
  signal mem_instr_stall         : std_logic;
  signal mem_instr_ack           : std_logic;


  signal reset_count       : unsigned(3 downto 0) := (others => '0');



  signal pio_in  : std_logic_vector(7 downto 0);
  signal pio_out : std_logic_vector(7 downto 0);
  signal pio_oe  : std_logic_vector(7 downto 0);


  for bootmem : wb_ram
    use entity work.wb_ram(bram);
  for dmem, imem : wb_ram
    use entity work.wb_ram(spram);



begin

  hf_osc : component osc_48MHz
    generic map (
      DIVIDER => "01")                  -- 24 MHz
    port map (
      CLKOUT => osc_clk);
  clk_gb : SB_GB
    port map (
      GLOBAL_BUFFER_OUTPUT         => clk,
      USER_SIGNAL_TO_GLOBAL_BUFFER => osc_clk);



  process(clk)
  begin
    if rising_edge(clk) then
      if reset_count /= "1111" then
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
      INIT_FILE_NAME   => "bootmem.mem",
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


      slave0_ADR_I   => spi_dmem_wb.ADR,
      slave0_DAT_I   => spi_dmem_wb.WDAT,
      slave0_DAT_O   => spi_dmem_wb.RDAT,
      slave0_WE_I    => spi_dmem_wb.WE,
      slave0_CYC_I   => spi_dmem_wb.CYC,
      slave0_STB_I   => spi_dmem_wb.STB,
      slave0_SEL_I   => spi_dmem_wb.SEL,
      slave0_STALL_O => spi_dmem_wb.STALL,
      slave0_ACK_O   => spi_dmem_wb.ACK,

      slave1_ADR_I   => data_dmem_wb.ADR,
      slave1_DAT_I   => data_dmem_wb.WDAT,
      slave1_DAT_O   => data_dmem_wb.RDAT,
      slave1_WE_I    => data_dmem_wb.WE,
      slave1_CYC_I   => data_dmem_wb.CYC,
      slave1_STB_I   => data_dmem_wb.STB,
      slave1_SEL_I   => data_dmem_wb.SEL,
      slave1_STALL_O => data_dmem_wb.STALL,
      slave1_ACK_O   => data_dmem_wb.ACK,


      slave2_ADR_I => (others => '-'),
      slave2_DAT_I => (others => '-'),
      slave2_WE_I  => '-',
      slave2_CYC_I => '0',
      slave2_STB_I => '0',
      slave2_SEL_I => (others => '-'),

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
      SUB_ADDRESS_BITS => 16,
      NUM_MASTERS      => 3,
      JUST_OR_ACKS     => false)
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

      master1_ADR_O   => spi_imem_wb.ADR,
      master1_DAT_O   => spi_imem_wb.WDAT,
      master1_WE_O    => spi_imem_wb.WE,
      master1_CYC_O   => spi_imem_wb.CYC,
      master1_STB_O   => spi_imem_wb.STB,
      master1_SEL_O   => spi_imem_wb.SEL,
      master1_CTI_O   => spi_imem_wb.CTI,
      master1_BTE_O   => spi_imem_wb.BTE,
      master1_LOCK_O  => spi_imem_wb.LOCK,
      master1_STALL_I => spi_imem_wb.STALL,
      master1_DAT_I   => spi_imem_wb.RDAT,
      master1_ACK_I   => spi_imem_wb.ACK,
      master1_ERR_I   => spi_imem_wb.ERR,
      master1_RTY_I   => spi_imem_wb.RTY,

      master2_ADR_O   => spi_dmem_wb.ADR,
      master2_DAT_O   => spi_dmem_wb.WDAT,
      master2_WE_O    => spi_dmem_wb.WE,
      master2_CYC_O   => spi_dmem_wb.CYC,
      master2_STB_O   => spi_dmem_wb.STB,
      master2_SEL_O   => spi_dmem_wb.SEL,
      master2_CTI_O   => spi_dmem_wb.CTI,
      master2_BTE_O   => spi_dmem_wb.BTE,
      master2_LOCK_O  => spi_dmem_wb.LOCK,
      master2_STALL_I => spi_dmem_wb.STALL,
      master2_DAT_I   => spi_dmem_wb.RDAT,
      master2_ACK_I   => spi_dmem_wb.ACK,
      master2_ERR_I   => spi_dmem_wb.ERR,
      master2_RTY_I   => spi_dmem_wb.RTY);

  rv : component orca
    generic map (
      REGISTER_SIZE      => REGISTER_SIZE,
      WISHBONE_AUX       => 1,
      MULTIPLY_ENABLE    => 1,
      DIVIDE_ENABLE      => 0,
      SHIFTER_MAX_CYCLES => 32,
      COUNTER_LENGTH     => 32,
      PIPELINE_STAGES    => 4,
      LVE_ENABLE         => 0,
      ENABLE_EXCEPTIONS  => 0,
      FAMILY             => "LATTICE")
    port map(

      clk            => clk,
      scratchpad_clk => '0',
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

  instr_wb.WE <= '0';

  orca_data_splitter : component wb_splitter

    generic map(
      SUB_ADDRESS_BITS => 16,
      NUM_MASTERS      => 6,
      JUST_OR_ACKS     => false)
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

      master1_ADR_O   => data_imem_wb.ADR,
      master1_DAT_O   => data_imem_wb.WDAT,
      master1_WE_O    => data_imem_wb.WE,
      master1_CYC_O   => data_imem_wb.CYC,
      master1_STB_O   => data_imem_wb.STB,
      master1_SEL_O   => data_imem_wb.SEL,
      master1_CTI_O   => data_imem_wb.CTI,
      master1_BTE_O   => data_imem_wb.BTE,
      master1_LOCK_O  => data_imem_wb.LOCK,
      master1_STALL_I => data_imem_wb.STALL,
      master1_DAT_I   => data_imem_wb.RDAT,
      master1_ACK_I   => data_imem_wb.ACK,
      master1_ERR_I   => data_imem_wb.ERR,
      master1_RTY_I   => data_imem_wb.RTY,

      master2_ADR_O   => data_dmem_wb.ADR,
      master2_DAT_O   => data_dmem_wb.WDAT,
      master2_WE_O    => data_dmem_wb.WE,
      master2_CYC_O   => data_dmem_wb.CYC,
      master2_STB_O   => data_dmem_wb.STB,
      master2_SEL_O   => data_dmem_wb.SEL,
      master2_CTI_O   => data_dmem_wb.CTI,
      master2_BTE_O   => data_dmem_wb.BTE,
      master2_LOCK_O  => data_dmem_wb.LOCK,
      master2_STALL_I => data_dmem_wb.STALL,
      master2_DAT_I   => data_dmem_wb.RDAT,
      master2_ACK_I   => data_dmem_wb.ACK,
      master2_ERR_I   => data_dmem_wb.ERR,
      master2_RTY_I   => data_dmem_wb.RTY,

      master3_ADR_O   => uart_wb.ADR,
      master3_DAT_O   => uart_wb.WDAT,
      master3_WE_O    => uart_wb.WE,
      master3_CYC_O   => uart_wb.CYC,
      master3_STB_O   => uart_wb.STB,
      master3_SEL_O   => uart_wb.SEL,
      master3_CTI_O   => uart_wb.CTI,
      master3_BTE_O   => uart_wb.BTE,
      master3_LOCK_O  => uart_wb.LOCK,
      master3_STALL_I => uart_wb.STALL,
      master3_DAT_I   => uart_wb.RDAT,
      master3_ACK_I   => uart_wb.ACK,
      master3_ERR_I   => uart_wb.ERR,
      master3_RTY_I   => uart_wb.RTY,

      master4_ADR_O   => pio_wb.ADR,
      master4_DAT_O   => pio_wb.WDAT,
      master4_WE_O    => pio_wb.WE,
      master4_CYC_O   => pio_wb.CYC,
      master4_STB_O   => pio_wb.STB,
      master4_SEL_O   => pio_wb.SEL,
      master4_CTI_O   => pio_wb.CTI,
      master4_BTE_O   => pio_wb.BTE,
      master4_LOCK_O  => pio_wb.LOCK,
      master4_STALL_I => pio_wb.STALL,
      master4_DAT_I   => pio_wb.RDAT,
      master4_ACK_I   => pio_wb.ACK,
      master4_ERR_I   => pio_wb.ERR,
      master4_RTY_I   => pio_wb.RTY,

      master5_ADR_O   => flash_ctrl_wb.ADR,
      master5_DAT_O   => flash_ctrl_wb.WDAT,
      master5_WE_O    => flash_ctrl_wb.WE,
      master5_CYC_O   => flash_ctrl_wb.CYC,
      master5_STB_O   => flash_ctrl_wb.STB,
      master5_SEL_O   => flash_ctrl_wb.SEL,
      master5_CTI_O   => flash_ctrl_wb.CTI,
      master5_BTE_O   => flash_ctrl_wb.BTE,
      master5_LOCK_O  => flash_ctrl_wb.LOCK,
      master5_STALL_I => flash_ctrl_wb.STALL,
      master5_DAT_I   => flash_ctrl_wb.RDAT,
      master5_ACK_I   => flash_ctrl_wb.ACK,
      master5_ERR_I   => flash_ctrl_wb.ERR,
      master5_RTY_I   => flash_ctrl_wb.RTY);
  orca_instr_splitter : component wb_splitter
    generic map(
      SUB_ADDRESS_BITS => 16,
      NUM_MASTERS      => 2,
      JUST_OR_ACKS     => false)
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



  led       <= pio_out(4) and led_counter(15) and led_counter(14);
  pio_in(4) <= pio_out(4);

  pio_in(7 downto 5) <= pio_out(7 downto 5);

-----------------------------------------------------------------------------
-- UART signals and interface
-----------------------------------------------------------------------------
--cts_n     <= cts;
  txd           <= serial_out;
  serial_in     <= '0';
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
