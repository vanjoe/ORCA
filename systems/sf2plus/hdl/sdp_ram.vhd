-- sdp_ram.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- Simple Dual-Port RAM with separate read-only and write-only ports.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity sdp_ram is
  generic (
    AW : integer :=  5;
    DW : integer := 32
    );
  port (
    clk   : in std_logic;
    we    : in std_logic;
    raddr : in std_logic_vector(AW-1 downto 0);
    waddr : in std_logic_vector(AW-1 downto 0);
    di    : in std_logic_vector(DW-1 downto 0);
    do    : out std_logic_vector(DW-1 downto 0)
    );
end entity sdp_ram;

architecture rtl of sdp_ram is
  type ram_type is array ((2**AW)-1 downto 0) of
    std_logic_vector(DW-1 downto 0);

  -- To infer a true DP RAM with Vivado Synthesis, must use separate processes
  -- for each port, and thus a shared variable.
  -- signal ram : ram_type;
  shared variable ram : ram_type;

begin

  -- Single process for both ports (works with XST, but not Vivado Synthesis):
  --
  --process (clk)
  --begin
  --  if clk'event and clk = '1' then
  --    if we = '1' then
  --      ram(conv_integer(waddr)) <= di;
  --    end if;
  --    do <= ram(conv_integer(raddr));
  --  end if;
  --end process;

  -- Write port
  process (clk)
  begin
    if clk'event and clk = '1' then
      if we = '1' then
        ram(conv_integer(waddr)) := di;
      end if;
    end if;
  end process;

  -- Read port
  process (clk)
  begin
    if clk'event and clk = '1' then
      do <= ram(conv_integer(raddr));
    end if;
  end process;

end rtl;
