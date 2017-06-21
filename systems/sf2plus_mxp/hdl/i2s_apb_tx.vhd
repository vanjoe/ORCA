library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;


library work;
use work.top_util_pkg.all;


entity i2s_apb_tx is
  generic (REGISTER_SIZE : integer                := 32;
           DATA_WIDTH    : integer range 16 to 32 := 32);
  port (
    PCLK    : in std_logic;
    PRESETN : in std_logic;

    PADDR   : in  std_logic_vector(REGISTER_SIZE -1 downto 0);
    PENABLE : in  std_logic;
    PWRITE  : in  std_logic;
    PRDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    PWDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    PREADY  : out std_logic;
    PSEL    : in  std_logic;

    i2s_sd_o  : out  std_logic;          -- I2S data input
    i2s_sck_i : in  std_logic;          -- I2S clock out
    i2s_ws_i  : in  std_logic);         -- I2S word select out

end entity i2s_apb_tx;


architecture rtl of i2s_apb_tx is
  alias clk : std_logic is PCLK;
--  component i2s_encode_slave is
--
--    port (
--      clk   : in std_logic;
--      reset : in std_logic;
--
--      ws   : in  std_logic;
--      sd   : out std_logic;
--      sclk : in  std_logic;
--
--      pdata    : in  std_logic_vector(31 downto 0);
--      data_ack : out std_logic);
--
--  end component i2s_encode_slave;

  component i2s_slave_tx is
    generic(
      width : integer := 16
    );
    port(
      --  I2S Input ports
      -- Control ports
      RESET_N     : in std_logic; --Asynchronous Reset (Active Low)
      CLK         : in std_logic; --Board Clock
      I2S_EN      : in std_logic; --I2S Enable Port, '1' = enable
      LR_CK       : in std_logic; --Left/Right indicator clock ('0' = Left)
      BIT_CK      : in std_logic; --Bit clock
      DOUT        : out std_logic; --Serial I2S Data Output
      -- Parallel Output ports
      DATA_L : in std_logic_vector(width-1 downto 0);
      DATA_R : in std_logic_vector(width-1 downto 0);
      -- Output status ports
      STROBE : out std_logic;  --Rising edge means request for next LR Data
      STROBE_LR : out std_logic --Currently not using
    );
  end component;


  signal reset : std_logic;

  constant FIFO_DEPTH : integer := 32;
  signal i2s_data     : std_logic_vector(31 downto 0);
  signal i2s_data_ack : std_logic;

  signal write_ptr       : unsigned(log2(FIFO_DEPTH)-1 downto 0);
  signal read_ptr        : unsigned(log2(FIFO_DEPTH)-1 downto 0);
  signal fifo_read_data  : std_logic_vector(31 downto 0);
  signal fifo_write_data : std_logic_vector(31 downto 0);
  signal fifo_we         : std_logic;
  signal fifo_re         : std_logic;

  type dpram is array(FIFO_DEPTH-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal fifo : dpram := (others => (others => '0'));

  signal fifo_full  : boolean;
  signal fifo_empty : boolean;

  type state_t is (IDLE,
                   WRITE_0,
                   WRITE_1
                   );
  signal state : state_t;
  signal write_done : std_logic;


  constant REGISTER_NAME_SIZE     : integer                                 := 4;
  constant VERSION_REGISTER       : unsigned(REGISTER_NAME_SIZE-1 downto 0) := x"0";
  constant CLOCK_DIVIDER_REGISTER : unsigned(REGISTER_NAME_SIZE-1 downto 0) := x"4";
  constant DATA_REGISTER          : unsigned(REGISTER_NAME_SIZE-1 downto 0) := x"8";
  signal addr                     : unsigned(REGISTER_NAME_SIZE-1 downto 0);

  signal data_l : std_logic_vector(15 downto 0);
  signal data_r : std_logic_vector(15 downto 0); 
  signal strobe : std_logic;
  signal strobe_latched : std_logic;
  
begin  -- architecture rtl

  reset <= not PRESETN;

--  dec : i2s_encode_slave
--    port map (
--      clk   => PCLK,
--      reset => reset,
--      ws    => i2s_ws_i,
--      sd    => i2s_sd_o,
--      sclk  => i2s_sck_i,
--
--      pdata       => i2s_data,
--      data_ack  => i2s_data_ack);

  enc : i2s_slave_tx
    port map (
      RESET_N => PRESETN,
      CLK => PCLK, 
      I2S_EN => PRESETN,
      LR_CK => i2s_ws_i,
      BIT_CK => i2s_sck_i,
      DOUT => i2s_sd_o,
      DATA_L => data_l,
      DATA_R => data_r,
      STROBE => strobe,
      STROBE_LR => OPEN);


  --write pointer increment after write
  --read pointer increment after read
  fifo_empty <= write_ptr = read_ptr;
  fifo_full  <= write_ptr + 1 = read_ptr;

  -- rising edge of strobe => data acknowledge
  process(clk)
  begin
    if rising_edge(clk) then
      i2s_data_ack <= '0';
      if (strobe_latched /= strobe) and (strobe = '1') then -- rising edge strobe => acknowledge
        i2s_data_ack <= '1'; 
      end if;
      strobe_latched <= strobe;
    end if;
  end process;

  --write pointer control
  process(clk)
  begin
    if rising_edge(clk) then
      if fifo_we = '1' and not fifo_full then
        write_ptr <= write_ptr +1;
      end if;
      if fifo_re = '1' and not fifo_empty then
        read_ptr <= read_ptr +1;
      end if;

      if reset = '1' then
        write_ptr <= to_unsigned(0, write_ptr'length);
        read_ptr  <= to_unsigned(0, read_ptr'length);
      end if;
    end if;
  end process;

  --fifo read and write
  process(clk)
  begin
    if rising_edge(clk) then
      if fifo_we = '1' and not fifo_full then
        fifo(to_integer(write_ptr)) <= PWDATA;
      end if;
      fifo_read_data <= fifo(to_integer(read_ptr));
    end if;
  end process;

  i2s_data     <= fifo_read_data when not fifo_empty  else (others => '0');
  data_l <= i2s_data(31 downto 16);
  data_r <= i2s_data(15 downto 0);
  fifo_re <= i2s_data_ack;

  PREADY <= (not PENABLE) or write_done;
  addr <= unsigned(PADDR(addr'range));
  PRDATA <= (others => '0');
  process(clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        state <= IDLE;
        write_done <= '0';
        fifo_we <= '0';
      else
        state <= state;
        write_done <= '0';
        fifo_we <= '0';
      
        case (state) is
          when IDLE =>
            write_done <= '0';
            fifo_we <= '0';
            if (PENABLE = '1' and PWRITE = '1') then
              state <= WRITE_0;
            end if;

          when WRITE_0 =>
            case (addr) is
              when DATA_REGISTER =>
                write_done <= '0';
                fifo_we <= '0';
                if not fifo_full then
                  write_done <= '1';
                  fifo_we <= '1';
                  state <= WRITE_1;
                end if;
              when others =>
                write_done <= '1';
                state <= WRITE_1;
            end case;

          when WRITE_1 =>
            write_done <= '0';
            fifo_we <= '0';
            state <= IDLE;

          when others =>
              
        end case;  
      end if;
    end if;
  end process;
end architecture rtl;
