library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.top_component_pkg.all;
use work.top_util_pkg.all;
use work.rv_components.all;

entity top is
  generic (
    USE_PLL : boolean := false);
  port(
    reset_btn : in std_logic;

    --spi
    spi_mosi : out std_logic;
    spi_miso : in  std_logic;
    spi_ss   : out std_logic;
    spi_sclk : out std_logic;

    --uart
    rxd : in  std_logic;
    txd : out std_logic;
    cts : in  std_logic;
    rts : out std_logic;

    --clk
    cam_xclk : in std_logic;

    --sccb
    sccb_scl : inout std_logic;
    sccb_sda : inout std_logic
    );
end entity;

architecture rtl of top is

  constant SCRATCHPAD_SIZE : integer := 128*1024;
  constant SYSCLK_FREQ_HZ  : natural := 8000000;

  constant REGISTER_SIZE : integer := 32;

  --for combined memory
  constant RAM_SIZE      : natural := 12*1024;
  --for seperate memory
  constant INST_RAM_SIZE : natural := 8*1024;
  constant DATA_RAM_SIZE : natural := 4*1024;

  constant SEPERATE_MEMS : boolean := true;


--  constant reset_btn: std_logic := '1';

  signal reset : std_logic;

  signal data_ADR_O   : std_logic_vector(31 downto 0);
  signal data_DAT_O   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_WE_O    : std_logic;
  signal data_CYC_O   : std_logic;
  signal data_STB_O   : std_logic;
  signal data_SEL_O   : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal data_CTI_O   : std_logic_vector(2 downto 0);
  signal data_BTE_O   : std_logic_vector(1 downto 0);
  signal data_LOCK_O  : std_logic;
  signal data_STALL_I : std_logic;
  signal data_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ACK_I   : std_logic;
  signal data_ERR_I   : std_logic;
  signal data_RTY_I   : std_logic;

  signal spi_sp_ADR_O   : std_logic_vector(31 downto 0);
  signal spi_sp_DAT_O   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal spi_sp_WE_O    : std_logic;
  signal spi_sp_CYC_O   : std_logic;
  signal spi_sp_STB_O   : std_logic;
  signal spi_sp_SEL_O   : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal spi_sp_CTI_O   : std_logic_vector(2 downto 0);
  signal spi_sp_BTE_O   : std_logic_vector(1 downto 0);
  signal spi_sp_LOCK_O  : std_logic;
  signal spi_sp_STALL_I : std_logic;
  signal spi_sp_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal spi_sp_ACK_I   : std_logic;
  signal spi_sp_ERR_I   : std_logic;
  signal spi_sp_RTY_I   : std_logic;

  signal data_sp_ADR_O   : std_logic_vector(31 downto 0);
  signal data_sp_DAT_O   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_sp_WE_O    : std_logic;
  signal data_sp_CYC_O   : std_logic;
  signal data_sp_STB_O   : std_logic;
  signal data_sp_SEL_O   : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal data_sp_CTI_O   : std_logic_vector(2 downto 0);
  signal data_sp_BTE_O   : std_logic_vector(1 downto 0);
  signal data_sp_LOCK_O  : std_logic;
  signal data_sp_STALL_I : std_logic;
  signal data_sp_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_sp_ACK_I   : std_logic;
  signal data_sp_ERR_I   : std_logic;
  signal data_sp_RTY_I   : std_logic;



  signal sp_ADR32 : std_logic_vector(31 downto 0);
  signal sp_ADR   : std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
  signal sp_RDAT  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sp_WDAT  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sp_WE    : std_logic;
  signal sp_ACK   : std_logic;
  signal sp_STALL : std_logic;
  signal sp_CYC   : std_logic;
  signal sp_STB   : std_logic;
  signal sp_SEL   : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal sp_CTI   : std_logic_vector(2 downto 0);



  signal instr_ADR_O : std_logic_vector(31 downto 0);
  signal instr_CYC_O : std_logic;
  signal instr_STB_O : std_logic;
  signal instr_CTI_O : std_logic_vector(2 downto 0);

  signal instr_STALL_I : std_logic;
  signal instr_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_ACK_I   : std_logic;
  signal instr_ERR_I   : std_logic;
  signal instr_RTY_I   : std_logic;

  signal data_uart_adr_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_uart_dat_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_uart_dat_o   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_uart_stb_i   : std_logic;
  signal data_uart_cyc_i   : std_logic;
  signal data_uart_we_i    : std_logic;
  signal data_uart_sel_i   : std_logic_vector(3 downto 0);
  signal data_uart_cti_i   : std_logic_vector(2 downto 0);
  signal data_uart_bte_i   : std_logic_vector(1 downto 0);
  signal data_uart_ack_o   : std_logic;
  signal data_uart_stall_o : std_logic;
  signal data_uart_lock_i  : std_logic;
  signal data_uart_err_o   : std_logic;
  signal data_uart_rty_o   : std_logic;

  signal sccb_pio_adr_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sccb_pio_dat_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sccb_pio_dat_o   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sccb_pio_stb_i   : std_logic;
  signal sccb_pio_cyc_i   : std_logic;
  signal sccb_pio_we_i    : std_logic;
  signal sccb_pio_sel_i   : std_logic_vector(3 downto 0);
  signal sccb_pio_cti_i   : std_logic_vector(2 downto 0);
  signal sccb_pio_bte_i   : std_logic_vector(1 downto 0);
  signal sccb_pio_ack_o   : std_logic;
  signal sccb_pio_stall_o : std_logic;
  signal sccb_pio_lock_i  : std_logic;
  signal sccb_pio_err_o   : std_logic;
  signal sccb_pio_rty_o   : std_logic;

  signal data_ram_adr_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ram_dat_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ram_dat_o   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ram_stb_i   : std_logic;
  signal data_ram_cyc_i   : std_logic;
  signal data_ram_we_i    : std_logic;
  signal data_ram_sel_i   : std_logic_vector(3 downto 0);
  signal data_ram_cti_i   : std_logic_vector(2 downto 0);
  signal data_ram_bte_i   : std_logic_vector(1 downto 0);
  signal data_ram_ack_o   : std_logic;
  signal data_ram_lock_i  : std_logic;
  signal data_ram_stall_o : std_logic;
  signal data_ram_err_o   : std_logic;
  signal data_ram_rty_o   : std_logic;


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

  signal spi_adr_i   : std_logic_vector(31 downto 0);
  signal spi_dat_i   : std_logic_vector(31 downto 0);
  signal spi_dat_o   : std_logic_vector(31 downto 0);
  signal spi_stb_i   : std_logic;
  signal spi_cyc_i   : std_logic;
  signal spi_we_i    : std_logic;
  signal spi_sel_i   : std_logic_vector(3 downto 0);
  signal spi_cti_i   : std_logic_vector(2 downto 0);
  signal spi_bte_i   : std_logic_vector(1 downto 0);
  signal spi_ack_o   : std_logic;
  signal spi_stall_o : std_logic;

  signal spi_ss_tmp : std_logic_vector(0 downto 0);

  signal uart_adr_i     : std_logic_vector(7 downto 0);
  signal uart_dat_i     : std_logic_vector(15 downto 0);
  signal uart_dat_o     : std_logic_vector(15 downto 0);
  signal uart_data_32   : std_logic_vector(31 downto 0);
  signal uart_stb_i     : std_logic;
  signal uart_cyc_i     : std_logic;
  signal uart_we_i      : std_logic;
  signal uart_sel_i     : std_logic_vector(3 downto 0);
  signal uart_cti_i     : std_logic_vector(2 downto 0);
  signal uart_bte_i     : std_logic_vector(1 downto 0);
  signal uart_ack_o     : std_logic;
  signal uart_interrupt : std_logic;
  signal uart_debug_ack : std_logic;


  signal clk             : std_logic;
  signal osc_clk         : std_logic;
  signal clk_count       : unsigned(3 downto 0) := (others => '0');
  signal clk_int         : std_logic := '0';
  signal clk_3x_int      : std_logic := '0';
  signal clk_3x          : std_logic;
  signal clk_reset_count : signed(3 downto 0)   := (others => '0');

  constant UART_ADDR_DAT         : std_logic_vector(7 downto 0) := "00000000";
  constant UART_ADDR_LSR         : std_logic_vector(7 downto 0) := "00000011";
  constant UART_LSR_8BIT_DEFAULT : std_logic_vector(7 downto 0) := "00000011";
  signal uart_stall              : std_logic;
  signal mem_instr_stall         : std_logic;
  signal mem_instr_ack           : std_logic;


  signal nreset           : std_logic;
  signal auto_reset_count : unsigned(3 downto 0) := (others => '0');
  signal auto_reset       : std_logic;


begin

  hf_osc : component osc_48MHz
    generic map (
      DIVIDER => "00")                -- 48 MHz
    port map (
      CLKOUT => osc_clk);


  process (osc_clk)
  begin
    if rising_edge(osc_clk) then
      clk_count  <= clk_count + 1;
      clk_3x_int <= not clk_3x_int;
      if clk_count = 2  then
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



  process(clk)
  begin
    if rising_edge(clk) then
      if auto_reset_count /= "1111" then
        auto_reset_count <= auto_reset_count +1;
        auto_reset       <= '1';
      else
        auto_reset <= '0';
      end if;
    end if;
  end process;

  reset  <= not reset_btn or auto_reset;
  nreset <= not reset;

  COMBINED_RAM_GEN : if not SEPERATE_MEMS generate
    signal RAM_ADR_I  : std_logic_vector(31 downto 0);
    signal RAM_DAT_I  : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal RAM_WE_I   : std_logic;
    signal RAM_CYC_I  : std_logic;
    signal RAM_STB_I  : std_logic;
    signal RAM_SEL_I  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
    signal RAM_CTI_I  : std_logic_vector(2 downto 0);
    signal RAM_BTE_I  : std_logic_vector(1 downto 0);
    signal RAM_LOCK_I : std_logic;

    signal RAM_STALL_O : std_logic;
    signal RAM_DAT_O   : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal RAM_ACK_O   : std_logic;
    signal RAM_ERR_O   : std_logic;
    signal RAM_RTY_O   : std_logic;
  begin
    mem : component wb_ram
      generic map(
        SIZE             => RAM_SIZE,
        INIT_FILE_FORMAT => "hex",
        INIT_FILE_NAME   => "test.mem",
        LATTICE_FAMILY   => "iCE5LP")
      port map(
        CLK_I => clk,
        RST_I => reset,

        ADR_I  => RAM_ADR_I,
        DAT_I  => RAM_DAT_I,
        WE_I   => RAM_WE_I,
        CYC_I  => RAM_CYC_I,
        STB_I  => RAM_STB_I,
        SEL_I  => RAM_SEL_I,
        CTI_I  => RAM_CTI_I,
        BTE_I  => RAM_BTE_I,
        LOCK_I => RAM_LOCK_I,

        STALL_O => RAM_STALL_O,
        DAT_O   => RAM_DAT_O,
        ACK_O   => RAM_ACK_O,
        ERR_O   => RAM_ERR_O,
        RTY_O   => RAM_RTY_O);

    arbiter : component wb_arbiter
      port map (
        CLK_I => clk,
        RST_I => reset,

        slave1_ADR_I  => data_ram_ADR_I,
        slave1_DAT_I  => data_ram_DAT_I,
        slave1_WE_I   => data_ram_WE_I,
        slave1_CYC_I  => data_ram_CYC_I,
        slave1_STB_I  => data_ram_STB_I,
        slave1_SEL_I  => data_ram_SEL_I,
        slave1_CTI_I  => data_ram_CTI_I,
        slave1_BTE_I  => data_ram_BTE_I,
        slave1_LOCK_I => data_ram_LOCK_I,

        slave1_STALL_O => data_ram_STALL_O,
        slave1_DAT_O   => data_ram_DAT_O,
        slave1_ACK_O   => data_ram_ack_O,
--      slave1_ERR_O   => data_ERR_I,
--      slave1_RTY_O   => data_RTY_I,

        slave2_ADR_I  => instr_ADR_O,
        slave2_DAT_I  => (others => '0'),
        slave2_WE_I   => '0',
        slave2_CYC_I  => instr_CYC_O,
        slave2_STB_I  => instr_STB_O,
        slave2_SEL_I  => (others => '0'),
        slave2_CTI_I  => instr_CTI_O,
        slave2_BTE_I  => (others => '0'),
        slave2_LOCK_I => '0',

        slave2_STALL_O => mem_instr_stall,
        slave2_DAT_O   => instr_DAT_I,
        slave2_ACK_O   => mem_instr_ACK,
        slave2_ERR_O   => instr_ERR_I,
        slave2_RTY_O   => instr_RTY_I,

        master_ADR_O  => RAM_ADR_I,
        master_DAT_O  => RAM_DAT_I,
        master_WE_O   => RAM_WE_I,
        master_CYC_O  => RAM_CYC_I,
        master_STB_O  => RAM_STB_I,
        master_SEL_O  => RAM_SEL_I,
        master_CTI_O  => RAM_CTI_I,
        master_BTE_O  => RAM_BTE_I,
        master_LOCK_O => RAM_LOCK_I,

        master_STALL_I => ram_STALL_O,
        master_DAT_I   => RAM_DAT_O,
        master_ACK_I   => RAM_ACK_O,
        master_ERR_I   => RAM_ERR_O,
        master_RTY_I   => RAM_RTY_O);


  end generate;

  SEPERATE_MEM_GEN : if SEPERATE_MEMS generate
    imem : component wb_ram
      generic map(
        SIZE             => INST_RAM_SIZE,
        INIT_FILE_FORMAT => "hex",
        INIT_FILE_NAME   => "imem.mem",
        LATTICE_FAMILY   => "iCE5LP")
      port map(
        CLK_I => clk,
        RST_I => reset,

        ADR_I  => instr_ADR_O,
        DAT_I  => (others => '0'),
        WE_I   => '0',
        CYC_I  => instr_CYC_O,
        STB_I  => instr_STB_O,
        SEL_I  => (others => '0'),
        CTI_I  => instr_CTI_O,
        BTE_I  => (others => '0'),
        LOCK_I => '0',

        STALL_O => mem_instr_stall,
        DAT_O   => instr_DAT_I,
        ACK_O   => mem_instr_ACK,
        ERR_O   => instr_ERR_I,
        RTY_O   => instr_RTY_I);

    dmem : component wb_ram
      generic map(
        SIZE             => DATA_RAM_SIZE,
        INIT_FILE_FORMAT => "hex",
        INIT_FILE_NAME   => "dmem.mem",
        LATTICE_FAMILY   => "iCE5LP")
      port map(
        CLK_I => clk,
        RST_I => reset,

        ADR_I   => data_ram_ADR_I,
        DAT_I   => data_ram_DAT_I,
        WE_I    => data_ram_WE_I,
        CYC_I   => data_ram_CYC_I,
        STB_I   => data_ram_STB_I,
        SEL_I   => data_ram_SEL_I,
        CTI_I   => data_ram_CTI_I,
        BTE_I   => data_ram_BTE_I,
        LOCK_I  => data_ram_LOCK_I,
        STALL_O => data_ram_STALL_O,
        DAT_O   => data_ram_DAT_O,
        ACK_O   => data_ram_ack_O,
        ERR_O   => data_ram_ERR_O,
        RTY_O   => data_ram_RTY_O);

  end generate SEPERATE_MEM_GEN;



--arbiter for scratchpad port
 arbiter : component wb_arbiter
      port map (
        CLK_I => clk,
        RST_I => reset,

        slave1_ADR_I  => spi_sp_ADR_O,
        slave1_DAT_I  => spi_sp_DAT_O,
        slave1_WE_I   => spi_sp_WE_O,
        slave1_CYC_I  => spi_sp_CYC_O,
        slave1_STB_I  => spi_sp_STB_O,
        slave1_SEL_I  => spi_sp_SEL_O,
        slave1_CTI_I  => spi_sp_CTI_O,
        slave1_BTE_I  => spi_sp_BTE_O,
        slave1_LOCK_I => spi_sp_LOCK_O,

        slave1_STALL_O => spi_sp_STALL_I,
        slave1_DAT_O   => spi_sp_DAT_I,
        slave1_ACK_O   => spi_sp_ack_I,
--      slave1_ERR_O   => data_ERR_I,
--      slave1_RTY_O   => data_RTY_I,

        slave2_ADR_I  => data_sp_ADR_O,
        slave2_DAT_I  => data_sp_DAT_O,
        slave2_WE_I   => data_sp_WE_O,
        slave2_CYC_I  => data_sp_CYC_O,
        slave2_STB_I  => data_sp_STB_O,
        slave2_SEL_I  => data_sp_SEL_O,
        slave2_CTI_I  => data_sp_CTI_O,
        slave2_BTE_I  => (others => '0'),
        slave2_LOCK_I => '0',

        slave2_STALL_O => data_sp_stall_i,
        slave2_DAT_O   => data_sp_DAT_I,
        slave2_ACK_O   => data_sp_ACK_I,
--        slave2_ERR_O   => data_sp_ERR_I,
--        slave2_RTY_O   => data_sp_RTY_I,

        master_ADR_O  => sp_ADR32,
        master_DAT_O  => sp_WDAT,
        master_WE_O   => sp_WE,
        master_CYC_O  => sp_CYC,
        master_STB_O  => sp_STB,
        master_SEL_O  => sp_SEL,
        master_CTI_O  => sp_CTI,
        master_BTE_O  => open,
        master_LOCK_O => open,

        master_STALL_I => sp_STALL,
        master_DAT_I   => sp_RDAT,
        master_ACK_I   => sp_ACK,
        master_ERR_I   => '0',
        master_RTY_I   => '0');

  rv : component orca
    generic map (
      REGISTER_SIZE        => REGISTER_SIZE,
      WISHBONE_ENABLE      => 1,
      MULTIPLY_ENABLE      => 1,
      DIVIDE_ENABLE        => 0,
      SHIFTER_MAX_CYCLES   => 32,
      COUNTER_LENGTH       => 32,
      PIPELINE_STAGES      => 4,
      LVE_ENABLE           => 1,
      ENABLE_EXCEPTIONS    => 1,
      NUM_EXT_INTERRUPTS   => 2,
      SCRATCHPAD_ADDR_BITS => log2(SCRATCHPAD_SIZE),
      FAMILY               => "LATTICE")
    port map(

      clk            => clk,
      scratchpad_clk => clk_3x,
      reset          => reset,

      data_ADR_O   => data_ADR_O,
      data_DAT_I   => data_DAT_I,
      data_DAT_O   => data_DAT_O,
      data_WE_O    => data_WE_O,
      data_SEL_O   => data_SEL_O,
      data_STB_O   => data_STB_O,
      data_ACK_I   => data_ACK_I,
      data_CYC_O   => data_CYC_O,
      data_STALL_I => data_STALL_I,
      data_CTI_O   => data_CTI_O,

      instr_ADR_O   => instr_ADR_O,
      instr_DAT_I   => instr_DAT_I,
      instr_STB_O   => instr_STB_O,
      instr_ACK_I   => instr_ACK_I,
      instr_CYC_O   => instr_CYC_O,
      instr_CTI_O   => instr_CTI_O,
      instr_STALL_I => instr_STALL_I,

      sp_ADR_I   => sp_ADR,
      sp_DAT_O   => sp_RDAT,
      sp_DAT_I   => sp_WDAT,
      sp_WE_I    => sp_WE,
      sp_SEL_I   => sp_SEL,
      sp_STB_I   => sp_STB,
      sp_ACK_O   => sp_ACK,
      sp_CYC_I   => sp_CYC,
      sp_CTI_I   => sp_CTI,
      sp_STALL_O => sp_STALL,

      global_interrupts => (others => '0'));

  sp_ADR <= sp_ADR32(sp_ADR'range);

  data_BTE_O  <= "00";
  data_LOCK_O <= '0';

  split_wb_data : component wb_splitter
    generic map(
      master0_address => (0+INST_RAM_SIZE, DATA_RAM_SIZE),  -- RAM
      master1_address => (16#00010000#, 1024),              -- SPI
      master2_address => (16#00020000#, 4*1024),            -- UART
      master3_address => (16#80000000#, SCRATCHPAD_SIZE),
      master6_address => (16#00050000#, 1024)               -- SCCB PIO
      )
    port map(
      clk_i => clk,
      rst_i => reset,

      slave_ADR_I   => data_ADR_O,
      slave_DAT_I   => data_DAT_O,
      slave_WE_I    => data_WE_O,
      slave_CYC_I   => data_CYC_O,
      slave_STB_I   => data_STB_O,
      slave_SEL_I   => data_SEL_O,
      slave_CTI_I   => data_CTI_O,
      slave_BTE_I   => data_BTE_O,
      slave_LOCK_I  => data_LOCK_O,
      slave_STALL_O => data_STALL_I,
      slave_DAT_O   => data_DAT_I,
      slave_ACK_O   => data_ACK_I,
      slave_ERR_O   => data_ERR_I,
      slave_RTY_O   => data_RTY_I,

      master0_ADR_O   => data_ram_ADR_I,
      master0_DAT_O   => data_ram_DAT_I,
      master0_WE_O    => data_ram_WE_I,
      master0_CYC_O   => data_ram_CYC_I,
      master0_STB_O   => data_ram_STB_I,
      master0_SEL_O   => data_ram_SEL_I,
      master0_CTI_O   => data_ram_CTI_I,
      master0_BTE_O   => data_ram_BTE_I,
      master0_LOCK_O  => data_ram_LOCK_I,
      master0_STALL_I => data_ram_STALL_O,
      master0_DAT_I   => data_ram_DAT_O,
      master0_ACK_I   => data_ram_ACK_O,
      master0_ERR_I   => data_ram_ERR_O,
      master0_RTY_I   => data_ram_RTY_O,

      master1_ADR_O   => spi_ADR_I,
      master1_DAT_O   => spi_DAT_I,
      master1_WE_O    => spi_WE_I,
      master1_CYC_O   => spi_CYC_I,
      master1_STB_O   => spi_STB_I,
      master1_SEL_O   => spi_SEL_I,
      master1_CTI_O   => spi_CTI_I,
      master1_BTE_O   => spi_BTE_I,
      master1_LOCK_O  => open,
      master1_STALL_I => spi_STALL_O,
      master1_DAT_I   => spi_DAT_O,
      master1_ACK_I   => spi_ACK_O,
      master1_ERR_I   => open,
      master1_RTY_I   => open,

      master2_ADR_O   => data_uart_ADR_I,
      master2_DAT_O   => data_uart_DAT_I,
      master2_WE_O    => data_uart_WE_I,
      master2_CYC_O   => data_uart_CYC_I,
      master2_STB_O   => data_uart_STB_I,
      master2_SEL_O   => data_uart_SEL_I,
      master2_CTI_O   => data_uart_CTI_I,
      master2_BTE_O   => data_uart_BTE_I,
      master2_LOCK_O  => data_uart_LOCK_I,
      master2_STALL_I => data_uart_STALL_O,
      master2_DAT_I   => data_uart_DAT_O,
      master2_ACK_I   => data_uart_ACK_O,
      master2_ERR_I   => data_uart_ERR_O,
      master2_RTY_I   => data_uart_RTY_O,


      master3_ADR_O   => data_sp_ADR_O,
      master3_DAT_O   => data_sp_DAT_O,
      master3_WE_O    => data_sp_WE_O,
      master3_CYC_O   => data_sp_CYC_O,
      master3_STB_O   => data_sp_STB_O,
      master3_SEL_O   => data_sp_SEL_O,
      master3_CTI_O   => open,
      master3_BTE_O   => open,
      master3_LOCK_O  => open,
      master3_STALL_I => data_sp_stall_i,
      master3_DAT_I   => data_sp_DAT_I,
      master3_ACK_I   => data_sp_ACK_I,
      master3_ERR_I   => open,
      master3_RTY_I   => open,

      master6_ADR_O   => sccb_pio_ADR_I,
      master6_DAT_O   => sccb_pio_DAT_I,
      master6_WE_O    => sccb_pio_WE_I,
      master6_CYC_O   => sccb_pio_CYC_I,
      master6_STB_O   => sccb_pio_STB_I,
      master6_SEL_O   => sccb_pio_SEL_I,
      master6_CTI_O   => sccb_pio_CTI_I,
      master6_BTE_O   => sccb_pio_BTE_I,
      master6_LOCK_O  => sccb_pio_LOCK_I,
      master6_STALL_I => sccb_pio_STALL_O,
      master6_DAT_I   => sccb_pio_DAT_O,
      master6_ACK_I   => sccb_pio_ACK_O,
      master6_ERR_I   => sccb_pio_ERR_O,
      master6_RTY_I   => sccb_pio_RTY_O);

  instr_stall_i <= uart_stall or mem_instr_stall;
  instr_ack_i   <= not uart_stall and mem_instr_ack;

  --dma controller for reading blocks of flash
  the_spi : wb_flash_dma
    generic map(
      MAX_LENGTH => 64*1024)
    port map(
      clk_i         => clk,
      rst_i         => reset,
      slave_ADR_I   => spi_adr_i(3 downto 0),
      slave_DAT_O   => spi_dat_o,
      slave_DAT_I   => spi_DAT_I,
      slave_WE_I    => spi_WE_I,
      slave_SEL_I   => spi_SEL_I,
      slave_STB_I   => spi_STB_I,
      slave_ACK_O   => spi_ACK_O,
      slave_CYC_I   => spi_CYC_I,
      slave_CTI_I   => spi_CTI_I,
      slave_STALL_O => spi_STALL_O,

      master_ADR_O   => spi_sp_ADR_O,
      master_DAT_I   => spi_sp_DAT_I,
      master_DAT_O   => spi_sp_DAT_O,
      master_WE_O    => spi_sp_WE_O,
      master_SEL_O   => spi_sp_SEL_O,
      master_STB_O   => spi_sp_STB_O,
      master_ACK_I   => spi_sp_ACK_I,
      master_CYC_O   => spi_sp_CYC_O,
      master_CTI_O   => spi_sp_CTI_O,
      master_STALL_I => spi_sp_STALL_I,

      base_clk => clk_3x,
      spi_mosi => spi_mosi,
      spi_miso => spi_miso,
      spi_ss   => spi_ss,
      spi_sclk => spi_sclk
      );

  the_sccb_pio : wb_pio
    generic map (
      DATA_WIDTH => 2
      )
    port map(
      clk_i => clk,
      rst_i => reset,

      adr_i   => sccb_pio_adr_i,
      dat_i   => sccb_pio_dat_i(1 downto 0),
      we_i    => sccb_pio_we_i,
      cyc_i   => sccb_pio_cyc_i,
      stb_i   => sccb_pio_stb_i,
      sel_i   => sccb_pio_sel_i,
      cti_i   => sccb_pio_cti_i,
      bte_i   => sccb_pio_bte_i,
      lock_i  => sccb_pio_lock_i,
      ack_o   => sccb_pio_ack_o,
      stall_o => sccb_pio_stall_o,
      data_o  => sccb_pio_dat_o(1 downto 0),
      err_o   => sccb_pio_err_o,
      rty_o   => sccb_pio_rty_o,

      input_output(1) => sccb_scl,
      input_output(0) => sccb_sda
      );
  sccb_pio_dat_o(sccb_pio_dat_o'left downto 2) <= (others => '0');

-----------------------------------------------------------------------------
-- Debugging logic (PC over UART)
-- This is useful if we can't figure out why
-- the program isn't running.
-----------------------------------------------------------------------------
  debug_gen : if DEBUG_ENABLE generate
    signal last_valid_address : std_logic_vector(31 downto 0);
    signal last_valid_data    : std_logic_vector(31 downto 0);
    type debug_state_type is (INIT, IDLE, SPACE, ADR, DAT, CR, LF);
    signal debug_state        : debug_state_type;
    signal debug_count        : unsigned(log2((last_valid_data'length+3)/4)-1 downto 0);
    signal debug_wait         : std_logic;

                                        --Convert a hex digit to ASCII for outputting on the UART
    function to_ascii_hex (
      signal hex_in : std_logic_vector)
      return std_logic_vector is
    begin
      if unsigned(hex_in) > to_unsigned(9, hex_in'length) then
                                        --value + 'A' - 10
        return std_logic_vector(resize(unsigned(hex_in), 8) + to_unsigned(55, 8));
      end if;

                                        --value + '0'
      return std_logic_vector(resize(unsigned(hex_in), 8) + to_unsigned(48, 8));
    end to_ascii_hex;


  begin
    process (clk)
    begin  -- process
      if clk'event and clk = '1' then   -- rising clock edge
        case debug_state is
          when INIT =>
            debug_address   <= UART_ADDR_LSR;
            debug_writedata <= UART_LSR_8BIT_DEFAULT;
            debug_write     <= '1';
            if debug_write = '1' and debug_wait = '0' then
              debug_state   <= IDLE;
              debug_address <= UART_ADDR_DAT;
              debug_write   <= '0';
            end if;
          when IDLE =>
            uart_stall <= '1';
            if instr_CYC_O = '1' then
              debug_write        <= '1';
              last_valid_address <= instr_ADR_O(instr_ADR_O'left-4 downto 0) & "0000";
              debug_writedata    <= to_ascii_hex(instr_ADR_O(last_valid_address'left downto last_valid_address'left-3));
              debug_state        <= ADR;
              debug_count        <= to_unsigned(0, debug_count'length);
            end if;
          when ADR =>
            if debug_wait = '0' then
              if debug_count = to_unsigned(((last_valid_address'length+3)/4)-1, debug_count'length) then
                debug_writedata <= std_logic_vector(to_unsigned(32, 8));
                debug_count     <= to_unsigned(0, debug_count'length);
                debug_state     <= SPACE;
                last_valid_data <= instr_DAT_I;
              else
                debug_writedata    <= to_ascii_hex(last_valid_address(last_valid_address'left downto last_valid_address'left-3));
                last_valid_address <= last_valid_address(last_valid_address'left-4 downto 0) & "0000";
                debug_count        <= debug_count + to_unsigned(1, debug_count'length);
              end if;
            end if;
          when SPACE =>
            if debug_wait = '0' then
              debug_writedata <= to_ascii_hex(last_valid_data(last_valid_data'left downto last_valid_data'left-3));
              last_valid_data <= last_valid_data(last_valid_data'left-4 downto 0) & "0000";
              debug_state     <= DAT;
            end if;
          when DAT =>
            if debug_wait = '0' then
              if debug_count = to_unsigned(((last_valid_data'length+3)/4)-1, debug_count'length) then
                debug_writedata <= std_logic_vector(to_unsigned(13, 8));
                debug_count     <= to_unsigned(0, debug_count'length);
                debug_state     <= CR;
              else
                debug_writedata <= to_ascii_hex(last_valid_data(last_valid_data'left downto last_valid_data'left-3));
                last_valid_data <= last_valid_data(last_valid_data'left-4 downto 0) & "0000";
                debug_count     <= debug_count + to_unsigned(1, debug_count'length);
              end if;
            end if;

          when CR =>
            if debug_wait = '0' then
              debug_writedata <= std_logic_vector(to_unsigned(10, 8));
              debug_state     <= LF;
            end if;
          when LF =>
            if debug_wait = '0' then
              debug_write <= '0';
              debug_state <= IDLE;
              uart_stall  <= '0';
            end if;

          when others =>
            debug_state <= IDLE;
        end case;

        if reset = '1' then
          debug_state <= INIT;
          debug_write <= '0';
          uart_stall  <= '1';
        end if;
      end if;
    end process;
    debug_wait <= not uart_ack_o;
  end generate debug_gen;
  no_debug_gen : if not DEBUG_ENABLE generate
    debug_write     <= '0';
    debug_writedata <= (others => '0');
    debug_address   <= (others => '0');
    uart_stall      <= '0';
  end generate no_debug_gen;

                                        -----------------------------------------------------------------------------
                                        -- UART signals and interface
                                        -----------------------------------------------------------------------------
  cts_n     <= cts;
  txd       <= serial_out;
  serial_in <= rxd;
  rts       <= rts_n;

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
      UART_ADR_I => uart_adr_i,
      UART_DAT_I => uart_dat_i,
      UART_DAT_O => uart_dat_o,
      UART_STB_I => uart_stb_i,
      UART_CYC_I => uart_cyc_i,
      UART_WE_I  => uart_we_i,
      UART_SEL_I => uart_sel_i,
      UART_CTI_I => uart_cti_i,
      UART_BTE_I => uart_bte_i,
      UART_ACK_O => uart_ack_o,
      INTR       => uart_interrupt,
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


                                        -----------------------------------------------------------------------------
                                        --
                                        -----------------------------------------------------------------------------
  uart_pc : if DEBUG_ENABLE generate
  begin
    uart_dat_i(15 downto 8) <= (others => '0');
    uart_dat_i(7 downto 0)  <= debug_writedata;
    uart_we_i               <= debug_write;

    uart_stb_i <= uart_we_i and (not txrdy_n);
    uart_adr_i <= debug_address;
    uart_cyc_i <= uart_stb_i and (not txrdy_n);

    uart_cti_i <= WB_CTI_CLASSIC;

                                        --constant ack to the riscv port
    data_uart_ack_o   <= '1';
    data_uart_stall_o <= not data_uart_ack_O;
  end generate uart_pc;
  uart_data_bus : if not DEBUG_ENABLE generate
  begin
    uart_adr_i        <= data_uart_adr_i(9 downto 2);
    uart_dat_i        <= data_uart_dat_i(15 downto 0);
    data_uart_dat_o   <= x"0000" & uart_dat_o(15 downto 0);
    uart_stb_i        <= data_uart_stb_i;
    uart_cyc_i        <= data_uart_cyc_i;
    uart_we_i         <= data_uart_we_i;
    uart_sel_i        <= data_uart_sel_i;
    uart_cti_i        <= data_uart_cti_i;
    uart_bte_i        <= data_uart_bte_i;
    data_uart_ack_o   <= uart_ack_o;
    data_uart_stall_o <= not data_uart_ack_O;
  end generate uart_data_bus;


end architecture rtl;
