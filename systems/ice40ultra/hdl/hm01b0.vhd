library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;

entity hm01b0 is

  port (
    pclk  : out std_logic;
    hsync : out std_logic;
    vsync : out std_logic;
    dat   : out std_logic_vector(7 downto 0);
    trig  : out std_logic);

end entity hm01b0;


architecture rtl of hm01b0 is
  signal pix_val      : unsigned(7 downto 0);
  signal internal_clk : std_logic;
  constant NUM_ROWS   : integer              := 320;

  constant PIXEL_PER_ROW        : integer := 320;
  constant CLOCKS_BETWEEN_FRAME : integer := 320;
  constant CLOCKS_BETWEEN_ROW   : integer := 30;

  signal pix_count        : integer;
  signal row_count        : integer;
  signal vsync_wait_count : integer := CLOCKS_BETWEEN_FRAME*82;
  signal hsync_wait_count : integer := CLOCKS_BETWEEN_ROW;
  type state_t is (INITIAL_WAIT,WAIT_FOR_VSYNC, WAIT_FOR_HSYNC, ROW_OUT);
  signal state            : state_t := WAIT_FOR_VSYNC;

  function next_pix_val (
    signal input : unsigned)
    return unsigned is
  begin  -- function next_pix_val
    return input;
  end function next_pix_val;
begin  -- architecture rtl

  process
  begin
    internal_clk <= '1';
    wait for 50 ns;
    internal_clk <= '0';
    wait for 50 ns;
  end process;
  pclk <= internal_clk ;

  dat <= std_logic_vector(pix_val);
  process(internal_clk)
  begin
    if rising_edge(internal_clk) then
      case state is
        when INITIAL_WAIT =>

        when WAIT_FOR_VSYNC =>
          vsync <= '0';
          hsync <= '0';
          vsync_wait_count <= vsync_wait_count -1;
          pix_val <= x"FF";
          if vsync_wait_count = 0 then
            state            <= WAIT_FOR_HSYNC;
            vsync_wait_count <= CLOCKS_BETWEEN_FRAME;
            row_count        <= NUM_ROWS-1;
            vsync            <= '1';
          end if;

        when WAIT_FOR_HSYNC =>
          hsync_wait_count <= hsync_wait_count -1;
          if hsync_wait_count = 0 then
            hsync_wait_count <= CLOCKS_BETWEEN_ROW;
            pix_count        <= PIXEL_PER_ROW-1;
            state            <= ROW_OUT;
            hsync            <= '1';
          end if;
        when ROW_OUT =>
          pix_val   <= next_pix_val(pix_val);
          pix_count <= pix_count - 1;
          if pix_count = 0 then
            pix_count <= PIXEL_PER_ROW;
            hsync     <= '0';
            row_count <= row_count -1;
            state     <= WAIT_FOR_HSYNC;
            if row_count = 0 then
              vsync <= '0';
              state <= WAIT_FOR_VSYNC;
            end if;
          end if;
        when others => null;
      end case;
    end if;
  end process;


end architecture rtl;
