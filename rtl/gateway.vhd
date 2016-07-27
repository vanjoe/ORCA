library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gateway is
  port (
    clk                   : in std_logic;
    reset                 : in std_logic;
    -- The direct external interrupt lines.
    global_interrupts     : in std_logic_vector(31 downto 0);
    -- The vector denoting which external interrupt lines are edge sensitive.
    edge_sensitive_vector : in std_logic_vector(31 downto 0);
    -- The lines signaling that an interrupt has been claimed.
    interrupt_claimed     : in std_logic_vector(31 downto 0);
    -- The lines signaling that an interrupt has been serviced.
    interrupt_complete    : in std_logic_vector(31 downto 0);
    -- The pending interrupt lines to output to the PLIC.
    pending_interrupts    : out std_logic_vector(31 downto 0));
end entity gateway;

architecture rtl of gateway is
  type counter_t is array(31 downto 0) of unsigned(31 downto 0);
  
  signal counter : counter_t;
  -- Stores the latch of the previous global interrupt inputs.
  signal global_interrupts_prev_reg : std_logic_vector(31 downto 0);
  -- Signals whether the PLIC is ready to receive another interrupt request
  -- on the 'i'th line.
  signal interrupt_ready_reg        : std_logic_vector(31 downto 0);

begin

  process (clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        counter <= (others => (others => '0'));
        global_interrupts_prev_reg <= (others => '0');
        interrupt_ready_reg <= (others => '1');
        pending_interrupts <= (others => '0');
      else
        global_interrupts_prev_reg <= global_interrupts;
        for i in 0 to 31 loop

          -- Level sensitive interrupt handler.
          if edge_sensitive_vector(i) = '0' then
            if (global_interrupts(i) = '1') and (interrupt_ready_reg(i) = '1')  then
              pending_interrupts(i) <= '1';
              interrupt_ready_reg(i) <= '0';
            end if;
            if (interrupt_claimed(i) = '1') then
              pending_interrupts(i) <= '0';
            end if;
            if (interrupt_complete(i) = '1') then
              interrupt_ready_reg(i) <= '1';
            end if;
          
          else
            -- Edge sensitive interrupt handler.
            if (global_interrupts(i) = '1') and 
              (global_interrupts(i) /= global_interrupts_prev_reg(i)) then
              if interrupt_ready_reg(i) = '1' then
                pending_interrupts(i) <= '1';
                interrupt_ready_reg(i) <= '0';
              else
                counter(i) <= counter(i) + 1;
              end if;
            end if;
            if (interrupt_claimed(i) = '1') then
              pending_interrupts(i) <= '0';
            end if;
            if (interrupt_complete(i) = '1') then
              interrupt_ready_reg(i) <= '1';
              if counter(i) > 0 then
                counter(i) <= counter(i) - 1;
                pending_interrupts(i) <= '1';
                interrupt_ready_reg(i) <= '0';
              end if;
            end if;
          end if; 
        end loop;
      end if;
    end if;
  end process;
end architecture rtl;
