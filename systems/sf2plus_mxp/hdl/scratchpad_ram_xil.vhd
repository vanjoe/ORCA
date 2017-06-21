-- scratchpad_ram_xil.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.
--
-- Behavioural implementation of 9-bit wide synchronous true dual-port RAM
-- with output registers (aka pipeline registers).
--
-- NOTE: the interface differs from scratchpad_ram.vhd in that there aren't
-- seprate wren and byteena inputs.
--
-- Created for Xilinx BRAMs, which have en{ab} inputs (controls reads and
-- writes)and per-byte we{ab}[] inputs, compared to the wren_{ab} and
-- byteena_{ab}[] inputs of Altera BRAMs.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
-- XST guide says conv_integer from std_logic_unsigned must be used.
use IEEE.std_logic_unsigned.all;

library work;
use work.util_pkg.all;

entity scratchpad_ram_xil is
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
end scratchpad_ram_xil;


architecture rtl of scratchpad_ram_xil is

  type ram_type is array (RAM_DEPTH-1 downto 0) of std_logic_vector(8 downto 0);
  -- To infer a true DP RAM with Vivado Synthesis, must use separate processes
  -- for each port, and thus a shared variable.
  -- signal ram : ram_type;
  shared variable ram : ram_type;

  signal out_a, out_b : std_logic_vector(8 downto 0);

begin

  -- Spartan-6 User Guide: "By default, block RAM memory is initialized with
  -- all zeros during the device configuration sequence."
  -- But see also http://www.xilinx.com/support/answers/39999.htm.
  -- Design Advisory for Spartan-6 FPGA - 9K Block RAM Initialization Support

  -- The following works with XST, but Vivado 2013.x Synthesis will not infer
  -- a true DP RAM if both ports are specified in the same process.
  -- http://www.xilinx.com/support/answers/51088.html
  --
  --process (clock)
  --begin
  --  if clock'event and clock = '1' then
  --    if wren_a = '1' then
  --      ram(conv_integer(address_a)) <= data_a;
  --    end if;
  --    if wren_b = '1' then
  --      ram(conv_integer(address_b)) <= data_b;
  --    end if;
  --    out_a <= ram(conv_integer(address_a));
  --    out_b <= ram(conv_integer(address_b));
  --    -- output registers
  --    readdata_a <= out_a;
  --    readdata_b <= out_b;
  --  end if;
  --end process;

  -- Separate processes for each port.
  -- (See rams_16b example in XST and Vivado Synthesis User Guides.)

  process (clock)
  begin
    if clock'event and clock = '1' then
      -- NOTE: read assignment must come before write assignment to correctly
      -- model read-first synchronization.
      out_a <= ram(conv_integer(address_a));
      if wren_a = '1' then
        ram(conv_integer(address_a)) := data_a;
      end if;
      -- output register
      readdata_a <= out_a;
    end if;
  end process;

  process (clock)
  begin
    if clock'event and clock = '1' then
      out_b <= ram(conv_integer(address_b));
      if wren_b = '1' then
        ram(conv_integer(address_b)) := data_b;
      end if;
      -- output register
      readdata_b <= out_b;
    end if;
  end process;

end rtl;
