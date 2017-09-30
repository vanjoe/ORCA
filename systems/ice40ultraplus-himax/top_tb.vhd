library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
entity top_tb is
end entity;


architecture rtl of top_tb is
  component verilog_top is
    generic (
      USE_PLL  : integer := 0;
      USE_LVE  : integer := 1;
      USE_UART : integer := 0;
      USE_CAM  : integer := 1);

    port(
      --spi
      spi_mosi : out std_logic;
      spi_miso : in  std_logic;
      spi_ss   : out std_logic;
      spi_sclk : out std_logic;

      --uart
      txd : out std_logic;

      --clk
      cam_xclk  : in std_logic;
      cam_vsync : in std_logic;
      cam_href  : in std_logic;
      cam_dat   : in std_logic_vector(7 downto 0);

      --sccb
      sccb_scl : inout std_logic;
      sccb_sda : inout std_logic
      );
  end component;

  constant CAM_NUM_COLS : integer := 40;
  constant CAM_NUM_ROWS : integer := 30;

  signal reset : std_logic;

  signal spi_mosi : std_logic;
  signal spi_miso : std_logic;
  signal spi_ss   : std_logic;
  signal spi_sclk : std_logic;


  signal txd : std_logic;

  signal sccb_scl : std_logic;
  signal sccb_sda : std_logic;


  constant CLOCK_PERIOD : time := 83.33 ns;
  constant PCLK_PERIOD  : time := 74.074 ns;

  signal cam_pclk  : std_logic;
  signal cam_vsync : std_logic;
  signal cam_href  : std_logic;
  signal cam_dat   : std_logic_vector(7 downto 0);


  component m25p80 is
    generic (
      -- memory file to be loaded
      mem_file_name : string := "m25p80.mem";

      UserPreload : boolean := false;   --TRUE;
      DebugInfo   : boolean := false;
      LongTimming : boolean := true);
    port (
      C       : in  std_ulogic := 'U';  --serial clock input
      D       : in  std_ulogic := 'U';  --serial data input
      SNeg    : in  std_ulogic := 'U';  -- chip select input
      HOLDNeg : in  std_ulogic := 'U';  -- hold input
      WNeg    : in  std_ulogic := 'U';  -- write protect input
      Q       : out std_ulogic := 'U'   --serial data output
      );

  end component;
  component hm01b0 is

    port (
      pclk  : out std_logic;
      hsync : out std_logic;
      vsync : out std_logic;
      dat   : out std_logic_vector(7 downto 0);
      trig  : out std_logic);

  end component;

  component uart_rx_tb is
    generic (
      BAUD_RATE   : integer := 115200;
      OUTPUT_FILE : string  := "uart.out");
    port (
      rxd : in std_logic);
  end component;

begin

  rx : component uart_rx_tb
    port map(
      rxd => txd);
  himax_cam : component hm01b0
    port map (
      pclk  => cam_pclk,
      vsync => cam_vsync,
      hsync => cam_href,
      dat   => cam_dat);


    dut : component verilog_top

    port map(
      spi_miso => spi_miso,
      spi_mosi => spi_mosi,
      spi_ss   => spi_ss,
      spi_sclk => spi_sclk,

      cam_xclk  => cam_pclk,
      cam_vsync => cam_vsync,
      cam_href  => cam_href,
      cam_dat   => cam_dat,


      txd => txd,


      sccb_scl => sccb_scl,
      sccb_sda => sccb_sda
      );

  the_flash : entity work.m25p80(vhdl_behavioral)
    generic map (
      UserPreload   => true,
      mem_file_name => "flash.mem")
    port map (
      HOLDNEg => '1',
      C       => spi_sclk,
      D       => spi_mosi,
      SNeg    => SPI_SS,
      WNeg    => '1',
      Q       => spi_miso);


  sccb_scl <= 'H';
  sccb_sda <= 'H';

  process
  begin
    reset <= '0';
    wait for CLOCK_PERIOD*5;
    reset <= not reset;
    wait;
  end process;

end architecture;
