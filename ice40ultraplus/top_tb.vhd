library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
entity top_tb is
end entity;


architecture rtl of top_tb is
  component verilog_top is
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

  constant CAM_NUM_COLS : integer := 48;
  constant CAM_NUM_ROWS : integer := 16;

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

  signal ovm_pclk  : std_logic := '0';
  signal ovm_vsync : std_logic;
  signal ovm_href  : std_logic;
  signal ovm_dat   : std_logic_vector(7 downto 0);

  signal pclk_count : integer := 0;

begin
  process
  begin
    ovm_pclk <= not ovm_pclk;
    wait for (18.518 ns /2)*4;
  end process;

  dut : component verilog_top
    generic map (
      CAM_NUM_COLS => CAM_NUM_COLS,
      CAM_NUM_ROWS => CAM_NUM_ROWS)
    port map(
      spi_miso  => spi_miso,
      spi_ss    => spi_ss,
      spi_sclk  => spi_sclk,

      cam_xclk  => ovm_pclk,
      cam_vsync => ovm_vsync,
      cam_href  => ovm_href,
      cam_dat   => ovm_dat,


      txd => txd,


      sccb_scl => sccb_scl,
      sccb_sda => sccb_sda
      );
  spi_miso <= '0';

  sccb_scl <= 'H';
  sccb_sda <= 'H';

  process
  begin
    reset <= '0';
    wait for CLOCK_PERIOD*5;
    reset <= not reset;
    wait;
  end process;

  process(spi_sclk, spi_ss)


  begin
    if falling_edge(spi_ss) then

      bit_sel <= mydata'right+6;
    end if;
    if falling_edge(spi_sclk) then
      if bit_sel = 0 then
        mydata <= mydata+1;
      end if;
      if bit_sel = mydata'right then
        bit_sel <= mydata'left;
      else
        bit_sel <= bit_sel-1;
      end if;
      spi_miso <= mydata(bit_sel);
    end if;
  end process;



  ovm_dat <= x"A3";

  process(ovm_pclk)
    constant pclk_interval : integer := CAM_NUM_COLS*2;
  begin
    if rising_edge(ovm_pclk) then
      pclk_count <= pclk_count +1;

      ovm_vsync <= '0';
      if pclk_count >0 and pclk_count < 10 then
        ovm_vsync <= '1';
      end if;


      if  pclk_count < PCLK_INTERVAL then
        ovm_href <= '0';
      elsif pclk_count mod PCLK_INTERVAL = 0 then
        ovm_href <= not ovm_href;
      elsif pclk_count > (PCLK_INTERVAL*CAM_NUM_ROWS*2) then
        pclk_count <= -PCLK_INTERVAL*2;
      end if;
    end if;
  end process;

end architecture;
