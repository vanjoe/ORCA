-- bram_tdp_behav.vhd
-- Copyright (C) 2017 VectorBlox Computing, Inc.
--
-- Behavioural implementation of true dual port RAM.  No enables/write enables
-- for maximum compatibility across FPGA families.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.utils.all;

entity bram_tdp_behav is
  generic (
    RAM_DEPTH : integer := 1024;
    RAM_WIDTH : integer := 8
    );
  port
    (
      address_a  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      address_b  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
      clk        : in  std_logic;
      data_a     : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      data_b     : in  std_logic_vector(RAM_WIDTH-1 downto 0);
      wren_a     : in  std_logic;
      wren_b     : in  std_logic;
      readdata_a : out std_logic_vector(RAM_WIDTH-1 downto 0);
      readdata_b : out std_logic_vector(RAM_WIDTH-1 downto 0)
      );
end bram_tdp_behav;

architecture rtl of bram_tdp_behav is
  type ram_type is array (RAM_DEPTH-1 downto 0) of std_logic_vector(RAM_WIDTH-1 downto 0);
  shared variable ram : ram_type;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      readdata_a <= ram(to_integer(unsigned(address_a)));
      if wren_a = '1' then
        ram(to_integer(unsigned(address_a))) := data_a;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      readdata_b <= ram(to_integer(unsigned(address_b)));
      if wren_b = '1' then
        ram(to_integer(unsigned(address_b))) := data_b;
      end if;
    end if;
  end process;
end rtl;
