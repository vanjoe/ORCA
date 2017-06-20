-- adder_tree_clk.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;
use work.component_pkg.all;

entity adder_tree_clk is
  generic (
    WIDTH            : integer := 32;
    LEAVES           : integer := 8;
    BRANCHES_PER_CLK : integer := 3);
  port(
    clk : in std_logic;

    data_in  : in  std_logic_vector((WIDTH*LEAVES)-1 downto 0);
    data_out : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity adder_tree_clk;

architecture rtl of adder_tree_clk is
  constant LEVELS        : integer := log2(LEAVES);
  constant PADDED_LEAVES : integer := 2**LEVELS;
  type     tree_type is array (2*PADDED_LEAVES-1 downto 1) of unsigned(WIDTH-1 downto 0);
  signal   tree          : tree_type;
begin
  full_leaves_gen : for gleaf in LEAVES-1 downto 0 generate
    tree(gleaf+PADDED_LEAVES) <= unsigned(data_in((gleaf+1)*WIDTH-1 downto gleaf*WIDTH));
  end generate full_leaves_gen;
  empty_leaves_gen : for gleaf in PADDED_LEAVES-1 downto LEAVES generate
    tree(gleaf+PADDED_LEAVES) <= (others => '0');
  end generate empty_leaves_gen;

  tree_level_gen : for glevel in LEVELS-1 downto 0 generate
    branch_gen : for gbranch in (2**glevel)-1 downto 0 generate
      no_clk_branch_gen: if ((LEVELS-glevel) mod BRANCHES_PER_CLK) /= 0 generate
        tree((2**glevel)+gbranch) <= tree((2**(glevel+1))+(2*gbranch)) + tree((2**(glevel+1))+(2*gbranch+1));
      end generate no_clk_branch_gen;
      clk_branch_gen: if ((LEVELS-glevel) mod BRANCHES_PER_CLK) = 0 generate
        branch_reg: process (clk)
        begin  -- process branch_reg
          if clk'event and clk = '1' then  -- rising clock edge
            tree((2**glevel)+gbranch) <= tree((2**(glevel+1))+(2*gbranch)) + tree((2**(glevel+1))+(2*gbranch+1));
          end if;
        end process branch_reg;
      end generate clk_branch_gen;
    end generate branch_gen;
  end generate tree_level_gen;

  data_out <= std_logic_vector(tree(1));
  
end architecture rtl;
