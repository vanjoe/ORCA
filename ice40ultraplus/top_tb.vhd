library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
entity top_tb is
end entity;


architecture rtl of top_tb is
  component verilog_top is
    generic (
      USE_PLL : integer := 0;
      USE_LVE : integer := 0;
      USE_CAM : integer := 0);

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

  dut : component verilog_top

    port map(
      spi_miso => spi_miso,
      spi_mosi => spi_mosi,
      spi_ss   => spi_ss,
      spi_sclk => spi_sclk,

      cam_xclk  => ovm_pclk,
      cam_vsync => ovm_vsync,
      cam_href  => ovm_href,
      cam_dat   => ovm_dat,


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


  ovm_dat <= x"F0" when (pclk_count mod 2) /= 0 else x"0F";

  process(ovm_pclk)
    constant BYTES_PER_PIXEL : integer := 2;
    constant PCLK_INTERVAL   : integer := CAM_NUM_COLS*BYTES_PER_PIXEL;
  begin
    if rising_edge(ovm_pclk) then
      pclk_count <= pclk_count +1;

      ovm_vsync <= '0';
      if pclk_count > 0 and pclk_count < 10 then
        ovm_vsync <= '1';
      end if;


      if pclk_count < PCLK_INTERVAL then
        ovm_href <= '0';
      elsif pclk_count mod PCLK_INTERVAL = 0 then
        ovm_href <= not ovm_href;
      elsif pclk_count > (PCLK_INTERVAL*CAM_NUM_ROWS*2) then
        pclk_count <= -PCLK_INTERVAL*2;
      end if;
    end if;
  end process;

end architecture;
