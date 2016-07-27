library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interrupt_generator is
  port (clk : in std_logic;
        reset : in std_logic;
        global_interrupts : out std_logic_vector(31 downto 0));
end entity interrupt_generator;

architecture rtl of interrupt_generator is
  signal count : unsigned(3 downto 0);
begin
  process (clk) 
  begin
    if rising_edge(clk) then
      if reset = '1' then
        global_interrupts <= (others => '0');
        count <= (others => '0');
      else
        if count /= "1111" then
          count <= count + 1;
        end if;
        if count = "1011" then
          global_interrupts(14) <= '1';
        elsif count = "1111" then
          global_interrupts(14) <= '0';
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
