library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity SB_SPRAM256KA is
  port (
    ADDRESS    : in  std_logic_vector(13 downto 0);
    DATAIN     : in  std_logic_vector(15 downto 0);
    MASKWREN   : in  std_logic_vector(3 downto 0);
    WREN       : in  std_logic;
    CHIPSELECT : in  std_logic;
    CLOCK      : in  std_logic;
    STANDBY    : in  std_logic;
    SLEEP      : in  std_logic;
    POWEROFF   : in  std_logic;
    DATAOUT    : out std_logic_vector(15 downto 0)
    );
end entity SB_SPRAM256KA;

architecture behav of SB_SPRAM256KA is
  type ram_type is array (0 to (2**14)-1) of std_logic_vector(15 downto 0);
  signal ram : ram_type;
  signal Q   : std_logic_vector(15 downto 0);
begin
  process (CLOCK)
  begin
    if rising_edge(CLOCK) then
      Q <= ram(to_integer(unsigned(ADDRESS)));
      for b in 0 to 3 loop
        if WREN = '1' and MASKWREN(b) = '1' then
          ram(to_integer(unsigned(ADDRESS)))((b+1)*4 -1 downto b*4) <= DATAIN(4*(b+1)-1 downto 4*b);
        end if;
      end loop;  -- b
    end if;
  end process;

  DATAOUT <= Q;
end architecture behav;
