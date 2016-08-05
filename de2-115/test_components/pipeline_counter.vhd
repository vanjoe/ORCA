library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipeline_counter is

  generic (REGISTER_SIZE : integer := 32);

  port (clk : in std_logic;
        reset : in std_logic;
        counter_address : in std_logic_vector(7 downto 0);
        counter_byteenable : in std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
        counter_read : in std_logic;
        counter_readdata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
        counter_response : out std_logic_vector(1 downto 0);
        counter_write : in std_logic;
        counter_writedata : in std_logic_vector(REGISTER_SIZE-1 downto 0);
        counter_lock : in std_logic;
        counter_waitrequest : out std_logic;
        counter_readdatavalid : out std_logic;
        
        pipeline_count : out std_logic_vector(2 downto 0));

end entity;

architecture rtl of pipeline_counter is
  signal pipeline_count_reg : std_logic_vector(2 downto 0);
  
begin

  pipeline_count <= pipeline_count_reg;
  counter_readdata(2 downto 0) <= pipeline_count_reg;
  counter_readdata(31 downto 3) <= (others => '0');
  counter_response <= "00";
  counter_waitrequest <= '0';
  counter_readdatavalid <= '0';

  process (clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        pipeline_count_reg <= "000";
      else
        if (counter_write = '1') then
          pipeline_count_reg <= counter_writedata(2 downto 0);
        end if;  
      end if;
    end if;
  end process;
end architecture rtl;
