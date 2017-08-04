library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
library fmf;

entity top_tb is
end entity;




architecture rtl of top_tb is
  component vhdl_top is
    port(
      --spi
      spi_mosi : out std_logic;
      spi_miso : in  std_logic;
      spi_ss   : out std_logic;
      spi_sclk : out std_logic;

      --uart
      txd : out std_logic
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


  signal bit_sel        : integer              := 0;
  signal mydata         : unsigned(7 downto 0) := x"0E";
  constant CLOCK_PERIOD : time                 := 83.33 ns;
  constant PCLK_PERIOD  : time                 := 74.074 ns;

  signal ovm_pclk  : std_logic := '0';
  signal ovm_vsync : std_logic;
  signal ovm_href  : std_logic;
  signal ovm_dat   : std_logic_vector(7 downto 0);

  signal pclk_count : integer := -35000;

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

begin
  process
  begin
    ovm_pclk <= not ovm_pclk;
    wait for (PCLK_PERIOD/2);
  end process;

  dut : component vhdl_top
    port map(
      spi_miso => spi_miso,
      spi_mosi => spi_mosi,
      spi_ss   => spi_ss,
      spi_sclk => spi_sclk,

      txd => txd

      );


  process
  begin
    reset <= '0';
    wait for CLOCK_PERIOD*5;
    reset <= not reset;
    wait;
  end process;

  the_flash : entity work.m25p80(vhdl_behavioral)
    generic map (
      UserPreload => true,
      mem_file_name => "flash.mem")
    port map (
      HOLDNEg => '1',
      C       => spi_sclk,
      D       => spi_mosi,
      SNeg    => SPI_SS,
      WNeg    => '1',
      Q       => spi_miso);

    ovm_dat <= x"F0" when (pclk_count mod 2) /= 0 else x"0F";



end architecture;
