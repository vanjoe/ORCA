library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.top_component_pkg.all;
use work.top_util_pkg.all;
use work.rv_components.all;

entity top is
  generic (
    USE_PLL : boolean := FALSE);
  port(
    reset_btn : in std_logic;

    --uart
    rxd : in  std_logic;
    txd : out std_logic;
    cts : in  std_logic;
    rts : out std_logic;

    i2s_sd_mic1_mic2 : in  std_logic := '1';
    i2s_ws_mic1_mic2 : out std_logic;
    i2s_clk          : out std_logic;

    i2s_out_sdin         : out std_logic;
    i2s_out_sck          : out std_logic;
    i2s_out_lrck         : out std_logic;

    gpio : inout std_logic_vector(1 downto 0)
    );
end entity;

architecture rtl of top is

  constant REGISTER_SIZE : integer := 32;

  --for combined memory
  constant RAM_SIZE      : natural := 8*1024;
  --for seperate memory
  constant INST_RAM_SIZE : natural := 4*1024;
  constant DATA_RAM_SIZE : natural := 4*1024;

  constant SEPERATE_MEMS : boolean := true;

  -- I2S Constants
  constant I2S_BUFFER_SIZE_LOG2 : positive range 4 to 15 := 8;
  constant I2S_ADDR_WIDTH       : positive               := I2S_BUFFER_SIZE_LOG2+1;
  constant I2S_DATA_WIDTH       : positive               := 16;

  -- I2S Signals
  signal i2s_ADR_I     : std_logic_vector(I2S_ADDR_WIDTH-1 downto 0);
  signal i2s_DAT_I     : std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
  signal i2s_WE_I      : std_logic;
  signal i2s_CYC_I     : std_logic;
  signal i2s_STB_I     : std_logic;
  signal i2s_SEL_I     : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal i2s_CTI_I     : std_logic_vector(2 downto 0);
  signal i2s_BTE_I     : std_logic_vector(1 downto 0);
  signal i2s_LOCK_I    : std_logic;
  signal i2s_STALL_O   : std_logic;
  signal i2s_DAT_O     : std_logic_vector(I2S_DATA_WIDTH-1 downto 0);
  signal i2s_ACK_O     : std_logic;
  signal i2s_DAT_O_32  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal i2s_DAT_I_32  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal i2s_ADR_O_32  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal i2s_interrupt : std_logic;

--  constant reset_btn: std_logic := '1';

  signal reset : std_logic;

  signal data_ADR_O  : std_logic_vector(31 downto 0);
  signal data_DAT_O  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_WE_O   : std_logic;
  signal data_CYC_O  : std_logic;
  signal data_STB_O  : std_logic;
  signal data_SEL_O  : std_logic_vector(REGISTER_SIZE/8-1 downto 0);
  signal data_CTI_O  : std_logic_vector(2 downto 0);
  signal data_BTE_O  : std_logic_vector(1 downto 0);
  signal data_LOCK_O : std_logic;

  signal data_STALL_I : std_logic;
  signal data_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_ACK_I   : std_logic;
  signal data_ERR_I   : std_logic;
  signal data_RTY_I   : std_logic;

  signal instr_ADR_O  : std_logic_vector(31 downto 0);
  signal instr_CYC_O  : std_logic;
  signal instr_STB_O  : std_logic;
  signal instr_CTI_O  : std_logic_vector(2 downto 0);

  signal instr_STALL_I : std_logic;
  signal instr_DAT_I   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_ACK_I   : std_logic;
  signal instr_ERR_I   : std_logic;
  signal instr_RTY_I   : std_logic;

  signal gpio_adr_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal gpio_dat_i   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal gpio_dat_o   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal gpio_stb_i   : std_logic;
  signal gpio_cyc_i   : std_logic;
  signal gpio_we_i    : std_logic;
  signal gpio_sel_i   : std_logic_vector(3 downto 0);
  signal gpio_cti_i   : std_logic_vector(2 downto 0);
  signal gpio_bte_i   : std_logic_vector(1 downto 0);
  signal gpio_ack_o   : std_logic;
  signal gpio_stall_o : std_logic;
  signal gpio_lock_i  : std_logic;
  signal gpio_err_o   : std_logic;
  signal gpio_rty_o   : std_logic;


  constant MIC_BUFFER_SIZE : integer := 1024;
  signal mic_1_2_adr_i     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mic_1_2_dat_i     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mic_1_2_dat_o     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mic_1_2_stb_i     : std_logic;
  signal mic_1_2_cyc_i     : std_logic;
  signal mic_1_2_we_i      : std_logic;
  signal mic_1_2_sel_i     : std_logic_vector(3 downto 0);
  signal mic_1_2_cti_i     : std_logic_vector(2 downto 0);
  signal mic_1_2_bte_i     : std_logic_vector(1 downto 0);
  signal mic_1_2_ack_o     : std_logic;
  signal mic_1_2_stall_o   : std_logic;
  signal mic_1_2_lock_i    : std_logic;
  signal mic_1_2_err_o     : std_logic;
  signal mic_1_2_rty_o     : std_logic;

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


  constant DEBUG_ENABLE  : boolean := False;
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
  signal clk_int         : std_logic;
  signal clk_3x_int      : std_logic;
  signal clk_3x          : std_logic;
  signal clk_reset_count : signed(3 downto 0) := (others => '0');
  signal clk_12          : std_logic;

  constant UART_ADDR_DAT         : std_logic_vector(7 downto 0) := "00000000";
  constant UART_ADDR_LSR         : std_logic_vector(7 downto 0) := "00000011";
  constant UART_LSR_8BIT_DEFAULT : std_logic_vector(7 downto 0) := "00000011";
  signal uart_stall              : std_logic;
  signal mem_instr_stall         : std_logic;
  signal mem_instr_ack           : std_logic;

  signal hp_pwm      : std_logic;

  constant SYSCLK_FREQ_HZ         : natural                                     := 8000000;
  constant HEARTBEAT_COUNTER_BITS : positive                                    := log2(SYSCLK_FREQ_HZ);  -- ~1 second to roll over
  signal heartbeat_counter        : unsigned(HEARTBEAT_COUNTER_BITS-1 downto 0) := (others => '0');

  signal nreset           : std_logic;
  signal auto_reset_count : unsigned(3 downto 0) := (others => '0');
  signal auto_reset       : std_logic;
begin

  CLK_LOGIC_DIVIDER : if not USE_PLL generate

    hf_osc : component osc_48MHz
      generic map (
        DIVIDER => "00") -- 48 MHz
      port map (
        CLKOUT    => osc_clk);

    process (osc_clk)
    begin
      if rising_edge(osc_clk) then
        clk_count <= clk_count + 1;
        clk_3x_int <= not clk_3x_int;
        if clk_count = 2 then
          clk_count <= (others => '0');
          clk_int   <= not clk_int;
        end if;

        if clk_reset_count /= -1 then
          clk_reset_count <= clk_reset_count + 1;
          clk_3x_int <= '0';
          clk_int <= '0';
          clk_count <= (others => '0');
        end if;

        if reset_btn = '0' then
          clk_reset_count <= (others => '0');
        end if;
      end if;
    end process;

    process (clk_3x)
    begin
      if rising_edge(clk_3x) then
        clk_12 <= not clk_12;
        if reset = '1' then
          clk_12 <= '0';
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

  end generate;

  CLK_PLL : if USE_PLL generate

  hf_osc : component osc_48MHz
    generic map (
      DIVIDER => "10") -- 12 MHz
    port map (
      CLKOUT => clk);

  pll_3x : SB_PLL40_CORE
    generic map(

      -- Entity Parameters
      FEEDBACK_PATH                  => "PHASE_AND_DELAY",
      DELAY_ADJUSTMENT_MODE_FEEDBACK => "FIXED",  -- FIXED/DYNAMIC
      DELAY_ADJUSTMENT_MODE_RELATIVE => "FIXED",  -- FIXED/DYNAMIC
      SHIFTREG_DIV_MODE              => "00",  -- 00 (div by 4)/ 01 (div by 7)/11 (div by 5)
      FDA_FEEDBACK                   => "0000",
      FDA_RELATIVE                   => "0000",
      PLLOUT_SELECT                  => "SHIFTREG_0deg",

      DIVR         => "0000",
      DIVF         => "0000010",
      DIVQ         => "001",
      FILTER_RANGE => "001",

      ENABLE_ICEGATE => '0')
    port map (
      REFERENCECLK => clk,

      PLLOUTGLOBAL    => clk_3x,
      EXTFEEDBACK     => 'X',
      DYNAMICDELAY    => (others => 'X'),
      BYPASS          => '0',
      RESETB          => nreset,
      SDI             => 'X',
      SCLK            => 'X',
      LATCHINPUTVALUE => 'X');

    clk_12 <= clk;

  end generate;

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

  reset <= not reset_btn or auto_reset;
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

  rv : component orca_wishbone
    generic map (
      REGISTER_SIZE      => REGISTER_SIZE,
      MULTIPLY_ENABLE    => 1,
      DIVIDE_ENABLE      => 1,
      SHIFTER_MAX_CYCLES => 32,
      COUNTER_LENGTH     => 32,
      PIPELINE_STAGES    => 4,
      LVE_ENABLE         => 1,
      PLIC_ENABLE        => FALSE,
      NUM_EXT_INTERRUPTS => 2,
      SCRATCHPAD_SIZE    => 128*1024,
      FAMILY             => "LATTICE")
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

      global_interrupts => (others => '0'));

  data_BTE_O   <= "00";
  data_LOCK_O  <= '0';

  split_wb_data : component wb_splitter
    generic map(
      master0_address => (0+INST_RAM_SIZE, DATA_RAM_SIZE), -- RAM
      master1_address => (16#00010000#, 4*1024),           -- MIC
      master2_address => (16#00020000#, 4*1024),           -- UART
      master3_address => (16#00030000#, 4*1024),           -- GPIO
      master4_address => (16#00040000#, 4*1024))           -- I2S

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

      master1_ADR_O   => mic_1_2_ADR_I,
      master1_DAT_O   => mic_1_2_DAT_I,
      master1_WE_O    => mic_1_2_WE_I,
      master1_CYC_O   => mic_1_2_CYC_I,
      master1_STB_O   => mic_1_2_STB_I,
      master1_SEL_O   => mic_1_2_SEL_I,
      master1_CTI_O   => mic_1_2_CTI_I,
      master1_BTE_O   => mic_1_2_BTE_I,
      master1_LOCK_O  => mic_1_2_LOCK_I,
      master1_STALL_I => mic_1_2_STALL_O,
      master1_DAT_I   => mic_1_2_DAT_O,
      master1_ACK_I   => mic_1_2_ACK_O,
      master1_ERR_I   => mic_1_2_ERR_O,
      master1_RTY_I   => mic_1_2_RTY_O,

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

      master3_ADR_O   => gpio_ADR_I,
      master3_DAT_O   => gpio_DAT_I,
      master3_WE_O    => gpio_WE_I,
      master3_CYC_O   => gpio_CYC_I,
      master3_STB_O   => gpio_STB_I,
      master3_SEL_O   => gpio_SEL_I,
      master3_CTI_O   => gpio_CTI_I,
      master3_BTE_O   => gpio_BTE_I,
      master3_LOCK_O  => gpio_LOCK_I,
      master3_STALL_I => gpio_STALL_O,
      master3_DAT_I   => gpio_DAT_O,
      master3_ACK_I   => gpio_ACK_O,
      master3_ERR_I   => gpio_ERR_O,
      master3_RTY_I   => gpio_RTY_O,

      master4_ADR_O   => i2s_ADR_O_32,
      master4_DAT_O   => i2s_DAT_I_32,
      master4_WE_O    => i2s_WE_I,
      master4_CYC_O   => i2s_CYC_I,
      master4_STB_O   => i2s_STB_I,
      master4_SEL_O   => i2s_SEL_I,
      master4_CTI_O   => i2s_CTI_I,
      master4_BTE_O   => i2s_BTE_I,
      master4_LOCK_O  => i2s_LOCK_I,
      master4_STALL_I => i2s_STALL_O,
      master4_DAT_I   => i2s_DAT_O_32,
      master4_ACK_I   => i2s_ACK_O,
      master4_ERR_I   => OPEN,
      master4_RTY_I   => OPEN,

      master5_ADR_O   => OPEN,
      master5_DAT_O   => OPEN,
      master5_WE_O    => OPEN,
      master5_CYC_O   => OPEN,
      master5_STB_O   => OPEN,
      master5_SEL_O   => OPEN,
      master5_CTI_O   => OPEN,
      master5_BTE_O   => OPEN,
      master5_LOCK_O  => OPEN,
      master5_STALL_I => OPEN,
      master5_DAT_I   => OPEN,
      master5_ACK_I   => OPEN,
      master5_ERR_I   => OPEN,
      master5_RTY_I   => OPEN,

      master6_ADR_O   => OPEN,
      master6_DAT_O   => OPEN,
      master6_WE_O    => OPEN,
      master6_CYC_O   => OPEN,
      master6_STB_O   => OPEN,
      master6_SEL_O   => OPEN,
      master6_CTI_O   => OPEN,
      master6_BTE_O   => OPEN,
      master6_LOCK_O  => OPEN,
      master6_STALL_I => OPEN,
      master6_DAT_I   => OPEN,
      master6_ACK_I   => OPEN,
      master6_ERR_I   => OPEN,
      master6_RTY_I   => OPEN,

      master7_ADR_O   => OPEN,
      master7_DAT_O   => OPEN,
      master7_WE_O    => OPEN,
      master7_CYC_O   => OPEN,
      master7_STB_O   => OPEN,
      master7_SEL_O   => OPEN,
      master7_CTI_O   => OPEN,
      master7_BTE_O   => OPEN,
      master7_LOCK_O  => OPEN,
      master7_STALL_I => OPEN,
      master7_DAT_I   => OPEN,
      master7_ACK_I   => OPEN,
      master7_ERR_I   => OPEN,
      master7_RTY_I   => OPEN);

  -- Resizing to fit the REGISTER_SIZE bit wishbone splitter.
  i2s_DAT_O_32 <= i2s_DAT_O & i2s_DAT_O;
  i2s_DAT_I <= i2s_DAT_I_32(I2S_DATA_WIDTH-1 downto 0);

--The i2s module uses a 16bit bus, use the sel bits to choose which address is
--appropriate
  i2s_ADR_I <= i2s_ADR_O_32(I2S_ADDR_WIDTH downto 2) & not i2s_SEL_I(0);
  i2s_stall_o <= i2s_STB_I and not i2s_ACK_O;

  instr_stall_i <= uart_stall or mem_instr_stall;
  instr_ack_i   <= not uart_stall and mem_instr_ack;


    gpio_pio : component wb_pio
    generic map (
       DATA_WIDTH => gpio'length)
    port map(
      CLK_I => clk,
      RST_I => reset,

      ADR_I   => gpio_ADR_I,
      DAT_I   => gpio_DAT_I(gpio'range),
      WE_I    => gpio_WE_I,
      CYC_I   => gpio_CYC_I,
      STB_I   => gpio_STB_I,
      SEL_I   => gpio_SEL_I,
      CTI_I   => gpio_CTI_I,
      BTE_I   => gpio_BTE_I,
      LOCK_I  => gpio_LOCK_I,
      ACK_O   => gpio_ACK_O,
      STALL_O => gpio_STALL_O,
      DATA_O  => gpio_DAT_O(gpio'range),
      ERR_O   => gpio_ERR_O,
      RTY_O   => gpio_RTY_O,
      input_output  => gpio);

    i2s_tx : component tx_i2s_topm
      generic map (
        DATA_WIDTH => I2S_DATA_WIDTH,
        ADDR_WIDTH => I2S_ADDR_WIDTH)
      port map (
        wb_clk_i  => clk,
        wb_rst_i => reset,
        wb_sel_i => '1',
        wb_stb_i => i2s_STB_I,
        wb_we_i => i2s_WE_I,
        wb_cyc_i => i2s_CYC_I,
        wb_bte_i => i2s_BTE_I,
        wb_cti_i => i2s_CTI_I,
        wb_adr_i => i2s_ADR_I,
        wb_dat_i => i2s_DAT_I,
        wb_ack_o => i2s_ACK_O,
        wb_dat_o => i2s_DAT_O,

        tx_int_o => i2s_interrupt,

        i2s_sd_o => i2s_out_sdin,
        i2s_sck_o => i2s_out_sck,
        i2s_ws_o => i2s_out_lrck);

  -- This is not used while operating in external serial mode.
  --i2s_out_mclk <= clk_12;

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

  mics : component i2s_wb
    generic map (
      DATA_WIDTH => 32,
      ADDR_WIDTH => log2(MIC_BUFFER_SIZE*2))
    port map(
      wb_clk_i   => clk,
      wb_rst_i   => reset,
      wb_sel_i   => '1',
      wb_stb_i   => mic_1_2_stb_i,
      wb_we_i    => mic_1_2_we_i,
      wb_cyc_i   => mic_1_2_cyc_i,
      wb_bte_i   => mic_1_2_bte_i,
      wb_cti_i   => mic_1_2_cti_i,
      wb_adr_i   => mic_1_2_adr_i(log2(MIC_BUFFER_SIZE*2)-1 downto 0),
      wb_dat_i   => mic_1_2_dat_i,
      i2s_sd_i   => i2s_sd_mic1_mic2,
      wb_ack_o   => mic_1_2_ack_o,
      wb_dat_o   => mic_1_2_dat_o,
      wb_stall_o => mic_1_2_stall_o,
--      rx_int_o  => mic_1_2_rx_int_o,
      i2s_sck_o  => i2s_clk,
      i2s_ws_o   => i2s_ws_mic1_mic2);
end architecture rtl;
