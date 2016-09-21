library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;


library work;
use work.top_util_pkg.all;
-------------------------------------------------------------------------------
-- Address Map
-- 0x00 Version
-- 0x04 clock_divider (Max 0xFFFF)
-- 0x08 DATA

-- The DATA register at 0x08 reads a fifo. the fifo always has the latest data
-- in it. If the data is not read often enough, the oldest data will be dropped
-------------------------------------------------------------------------------



entity i2s_wb is
  generic (DATA_WIDTH : integer range 16 to 32;
           ADDR_WIDTH : integer range 5 to 32);
  port (
    wb_clk_i   : in  std_logic;
    wb_rst_i   : in  std_logic;
    wb_sel_i   : in  std_logic;
    wb_stb_i   : in  std_logic;
    wb_we_i    : in  std_logic;
    wb_cyc_i   : in  std_logic;
    wb_bte_i   : in  std_logic_vector(1 downto 0);
    wb_cti_i   : in  std_logic_vector(2 downto 0);
    wb_adr_i   : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    wb_dat_i   : in  std_logic_vector(DATA_WIDTH -1 downto 0);
    i2s_sd_i   : in  std_logic;         -- I2S data input
    wb_ack_o   : out std_logic;
    wb_stall_o : out std_logic;
    wb_dat_o   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    rx_int_o   : out std_logic;         -- Interrupt line
    i2s_sck_o  : out std_logic;         -- I2S clock out
    i2s_ws_o   : out std_logic);        -- I2S word select out

end entity i2s_wb;


architecture rtl of i2s_wb is
  alias clk : std_logic is wb_clk_i;

  component i2s_decode is

    port (
      clk         : in  std_logic;
      reset       : in  std_logic;
      ws          : out std_logic;
      sd          : in  std_logic;
      sclk        : out std_logic;
      clk_divider : in  std_logic_vector(31 downto 0);
      pdata       : out std_logic_vector(31 downto 0);
      data_valid  : out std_logic);

  end component i2s_decode;

  signal clock_divider : unsigned(15 downto 0);

  constant FIFO_DEPTH   : integer := 32;
  signal i2s_data       : std_logic_vector(31 downto 0);
  signal i2s_data_valid : std_logic;

  signal write_ptr : unsigned(log2(FIFO_DEPTH)-1 downto 0);
  signal read_ptr  : unsigned(log2(FIFO_DEPTH)-1 downto 0);


  type dpram is array(FIFO_DEPTH downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal fifo : dpram := (others => (others => '0'));

  signal fifo_full    : boolean;
  signal fifo_empty   : boolean;
  signal fifo_dataout : std_logic_vector(fifo(0)'range);

  signal do_read : boolean;
  signal do_write : boolean;


  constant REGISTER_NAME_SIZE     : integer                                 := 4;
  constant VERSION_REGISTER       : unsigned(REGISTER_NAME_SIZE-1 downto 0) := x"0";
  constant CLOCK_DIVIDER_REGISTER : unsigned(REGISTER_NAME_SIZE-1 downto 0) := x"4";
  constant DATA_REGISTER          : unsigned(REGISTER_NAME_SIZE-1 downto 0) := x"8";
  signal addr                     : unsigned(REGISTER_NAME_SIZE-1 downto 0);
  signal clk_div_32 : std_logic_vector(31 downto 0);
begin  -- architecture rtl

  clk_div_32 <= std_logic_vector(resize(clock_divider,32));
  dec : i2s_decode
    port map (
      clk   => wb_clk_i,
      reset => wb_rst_i,
      ws    => i2s_ws_o,
      sd    => i2s_sd_i,
      sclk  => i2s_sck_o,

      clk_divider => clk_div_32,
      pdata       => i2s_data,
      data_valid  => i2s_data_valid);

  --write pointer increment after write
  --read pointer increment after read
  fifo_empty <= write_ptr = read_ptr;
  fifo_full  <= write_ptr + 1 = read_ptr;

  --write pointer control
  process(clk)
  begin
    if rising_edge(clk) then

      if i2s_data_valid = '1' then
        write_ptr <= write_ptr +1;
      end if;
      if wb_rst_i = '1' then
        write_ptr <= to_unsigned(0, write_ptr'length);
      end if;
    end if;
  end process;

  --fifo read and write
  process(clk)
  begin
    if rising_edge(clk) then
      if i2s_data_valid = '1' and not fifo_full then
        fifo(to_integer(write_ptr)) <= i2s_data;
      end if;
      fifo_dataout <= fifo(to_integer(read_ptr));
      if read_ptr = write_ptr then      --read_during write
        fifo_dataout <= i2s_data;
      end if;
    end if;
  end process;

  do_read    <= (wb_cyc_i and wb_stb_i and not wb_we_i) = '1';
  do_write   <= (wb_cyc_i and wb_stb_i and wb_we_i) = '1';
  wb_stall_o <= '1' when fifo_empty and do_read and unsigned(wb_adr_i) = DATA_REGISTER else '0';
  addr       <= unsigned(wb_adr_i(addr'range));
  process(clk)
  begin
    if rising_edge(clk) then
      wb_ack_o <= '0';
      wb_dat_o <= (others => '-');
      if do_read then
        case addr is
          when VERSION_REGISTER =>
            wb_dat_o <= x"00010000";
            wb_ack_o <= '1';
          when CLOCK_DIVIDER_REGISTER =>
            wb_dat_o <= std_logic_vector(resize(clock_divider, 32));
            wb_ack_o <= '1';
          when DATA_REGISTER =>
            wb_dat_o <= fifo_dataout;
            if not fifo_empty then
              wb_ack_o <= '1';
              read_ptr <= read_ptr +1;
            end if;
          when others => null;
        end case;
      end if;
      if do_write then
        if addr = CLOCK_DIVIDER_REGISTER then
          clock_divider <= resize(unsigned(wb_dat_i),16);
          wb_ack_o <= '1';
        end if;
      end if;
      if i2s_data_valid = '1' and fifo_full then
        read_ptr <= read_ptr +1;
      end if;
      if wb_rst_i = '1' then
        read_ptr      <= to_unsigned(0, read_ptr'length);
        clock_divider <= (others => '1');
      end if;
    end if;
  end process;

end architecture rtl;
