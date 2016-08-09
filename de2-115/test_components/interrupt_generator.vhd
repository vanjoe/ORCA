library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interrupt_generator is
  generic (NUM_EXT_INTERRUPTS : integer range 2 to 32 := 2);
  port (clk : in std_logic;
        reset : in std_logic;
        global_interrupts : out std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0));
end entity interrupt_generator;

architecture rtl of interrupt_generator is
  constant count_stop : unsigned := "00111111";
  constant count_trigger : unsigned := "00111000";

  signal count : unsigned(7 downto 0);
  -- Trigger stage allows us to test all 4 stages of the pipeline
  -- to trigger the interrupt on. Trigger stage should vary from
  -- 0 to 3. After the trigger on '3', this module should stop
  -- triggering interrupts.
  signal trigger_stage : unsigned(7 downto 0);
begin
  process (clk) 
  begin
    if rising_edge(clk) then
      if reset = '1' then
        global_interrupts <= (others => '0');
        count <= (others => '0');
        trigger_stage <= (others => '0');
      else
        if count /= (count_stop - trigger_stage) then
          count <= count + 1;
        end if;
        if count = (count_trigger - trigger_stage) then
          global_interrupts(1) <= '1';
        elsif count = (count_stop - trigger_stage) then
          global_interrupts(1) <= '0';
          if trigger_stage /= 1 then
            trigger_stage <= trigger_stage + 1;
            count <= (others => '0');
          end if;

        end if;
      end if;
    end if;
  end process;
end architecture rtl;
