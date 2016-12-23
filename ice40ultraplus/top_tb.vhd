library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
entity top_tb is
end entity;


architecture rtl of top_tb is
  component top is
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

  signal reset     : std_logic;
  signal clk       : std_logic := '1';
  signal uart_pmod : std_logic_vector(3 downto 0);
  signal rxd       : std_logic;
  signal txd       : std_logic;
  signal cts       : std_logic;
  signal rts       : std_logic;

  signal spi_miso       : std_logic;
  signal spi_ss         : std_logic;
  signal spi_sclk       : std_logic;

  signal bit_sel : integer := 0;
  signal  mydata : unsigned(7 downto 0) := x"0E";
  constant CLOCK_PERIOD : time := 83.33 ns;

begin
  dut : component top
    port map(
      --    clk       => clk,
      reset_btn => reset,
      spi_miso  => spi_miso,
      spi_ss    => spi_ss,
      spi_sclk  => spi_sclk,

      cam_xclk  => '0',
      rxd       => rxd,
      txd       => txd,
      cts       => cts,
      rts       => rts);

  cts <= '0';
  process
  begin
    clk <= not clk;
    wait for CLOCK_PERIOD/2;
  end process;

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

end architecture;
