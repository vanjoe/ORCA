-- scratchpad_ram_microsemi.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.
--
-- Behavioural implementation of 9-bit wide synchronous true dual-port RAM
-- with output registers (aka pipeline registers).
--
-- NOTE: the interface differs from scratchpad_ram.vhd in that there aren't
-- seprate wren and byteena inputs.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.util_pkg.all;

entity scratchpad_ram_microsemi is
  generic (
    RAM_DEPTH : integer := 1024
    );
  port
    (
      address_a  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      address_b  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      clock      : in  std_logic;
      data_a     : in  std_logic_vector(8 downto 0);
      data_b     : in  std_logic_vector(8 downto 0);
      wren_a     : in  std_logic;
      wren_b     : in  std_logic;
      readdata_a : out std_logic_vector(8 downto 0);
      readdata_b : out std_logic_vector(8 downto 0)
      );
end scratchpad_ram_microsemi;


architecture rtl of scratchpad_ram_microsemi is

  type ram_type is array (RAM_DEPTH-1 downto 0) of std_logic_vector(8 downto 0);
  signal ram : ram_type;

  signal reg_address_a, reg_address_b : std_logic_vector(log2(RAM_DEPTH)-1 downto 0);

begin

  -- From the SmartFusion2 RAM Blocks Application Note 
  -- True Dual Port RAM with Pipeline Register

  process(clock)
  begin
    if rising_edge(clock) then
      if wren_a = '1' then
        ram(conv_integer(address_a)) <= data_a;
      end if;
      if wren_b = '1' then
        ram(conv_integer(address_b)) <= data_b;
      end if;
    end if;      
    reg_address_a <= address_a;
    reg_address_b <= address_b;
  end process;
  
  process(clock)
  begin
    if rising_edge(clock) then
      readdata_a <= ram(conv_integer(reg_address_a));
      readdata_b <= ram(conv_integer(reg_address_b));
    end if;
  end process;
  
end rtl;
