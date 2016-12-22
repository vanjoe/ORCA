library ieee;
use IEEE.std_logic_1164.all;

entity top_tb is
end entity;


architecture rtl of top_tb is
  component top is
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
  end component;

  signal reset : std_logic;

  signal spi_mosi : std_logic;
  signal spi_miso : std_logic;
  signal spi_ss   : std_logic;
  signal spi_sclk : std_logic;

  signal rxd : std_logic;
  signal txd : std_logic;
  signal cts : std_logic;
  signal rts : std_logic;

  signal sccb_scl : std_logic;
  signal sccb_sda : std_logic;

  constant CLOCK_PERIOD : time := 83.33 ns;
begin
  dut : component top
    port map(
      reset_btn => reset,

      spi_mosi => open,
      spi_miso => '0',
      spi_ss   => open,
      spi_sclk => open,

      rxd => rxd,
      txd => txd,
      cts => cts,
      rts => rts,

      cam_xclk => '0',

      sccb_scl => sccb_scl,
      sccb_sda => sccb_sda
      );
  spi_miso <= '0';
  cts      <= '0';
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
