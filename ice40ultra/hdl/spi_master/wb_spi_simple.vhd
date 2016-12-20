library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;

use work.top_util_pkg.all;


entity wb_spimaster is
  generic (
    dat_sz : natural := 8;
    slaves : natural := 1
    );
  port (
    clk_i   : in  std_logic;
    rst_i   : in  std_logic;
    --
    -- Wishbone Interface
    --
    adr_i   : in  std_logic_vector(7 downto 0);
    dat_i   : in  std_logic_vector((dat_sz - 1) downto 0);
    dat_o   : out std_logic_vector((dat_sz - 1) downto 0);
    cyc_i   : in  std_logic;
    sel_i   : in  std_logic;
    we_i    : in  std_logic;
    ack_o   : out std_logic;
    stall_o : out std_logic;
    stb_i   : in  std_logic;

    --aux signals
    done_transfer : out std_logic;
    data_out      : out std_logic_vector(dat_sz -1 downto 0);

    --
    -- SPI Master Signals
    --
    spi_mosi : out std_logic;
    spi_miso : in  std_logic;
    spi_ss   : out std_logic_vector(slaves- 1 downto 0);
    spi_sclk : out std_logic
    );
end entity;



architecture rtl of wb_spimaster is

  signal write_register : std_logic_vector(7 downto 0);
  signal read_register  : std_logic_vector(7 downto 0);

  signal w_shift_register : std_logic_vector(7 downto 0);
  signal bits_to_shift    : integer range 0 to write_register'length;

  signal done_xfer    : std_logic;
  signal restart_xfer : std_logic;

  signal slave_select : std_logic_vector(slaves-1 downto 0);



  constant CLOCK_DIVIDE_BITS   : integer                     := 1;
  signal clock_count           : unsigned(CLOCK_DIVIDE_BITS-1 downto 0);
  constant CLOCK_COUNT_WRITE   : unsigned(clock_count'range) := (others => '1');
  constant CLOCK_COUNT_READ    : unsigned(clock_count'range) := SHIFT_RIGHT(clock_count_write, 1);

  constant TXRX_REG : std_logic_vector(adr_i'range) := std_logic_vector(to_unsigned(0, adr_i'length));
  constant SS_REG   : std_logic_vector(adr_i'range) := std_logic_vector(to_unsigned(1, adr_i'length));
  constant STAT_REG : std_logic_vector(adr_i'range) := std_logic_vector(to_unsigned(2, adr_i'length));

begin  -- architecture rtl
  stall_o <= '0';

  --wishbone process
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      restart_xfer <= '0';
      --write
      if (we_i and stb_i and cyc_i) = '1' then
        if adr_i = TXRX_REG then
          write_register <= dat_i;
          restart_xfer   <= '1';
        elsif adr_i = SS_REG then
          slave_select <= dat_i(slave_select'range);
        end if;

      end if;
                                        --read
      if adr_i = TXRX_REG then
        dat_o <= read_register;
      elsif adr_i = SS_REG then
        dat_o(slave_select'range)                     <= slave_select;
        dat_o(dat_o'left downto slave_select'left +1) <= (others => '0');
      else
        dat_o <= "0000000" & done_xfer;
      end if;
      ack_o <= stb_i and cyc_i;
      if rst_i = '1' then
        slave_select <= (others => '1');
      end if;
    end if;
  end process;


  spi_ss <= slave_select;


  --shift register process
  done_xfer <= '1' when bits_to_shift = 0 else '0';
  spi_sclk  <= clock_count(clock_count'left) and not done_xfer;
  spi_mosi  <= w_shift_register(w_shift_register'left);

  done_transfer <= done_xfer and not restart_xfer;
  data_out <= read_register;
  process(clk_i)
  begin
    if rising_edge(clk_i) then

      if restart_xfer = '1' then
        bits_to_shift         <= 8;
        w_shift_register      <= write_register;
        clock_count           <= (others => '0');
      else
        if done_xfer = '0' then
          if clock_count = CLOCK_COUNT_WRITE then
            w_shift_register <= w_shift_register(w_shift_register'left-1 downto 0) & '0';
            bits_to_shift    <= bits_to_shift -1;
          elsif clock_count = CLOCK_COUNT_READ then
            read_register <= read_register(read_register'left -1 downto 0) & spi_miso;
          end if;
          clock_count           <= clock_count +1;

        end if;

      end if;

      if rst_i = '1' then
        read_register    <= (others => '0');
        w_shift_register <= (others => '0');
        bits_to_shift <= 0;
      end if;

    end if;
  end process;

end architecture rtl;
