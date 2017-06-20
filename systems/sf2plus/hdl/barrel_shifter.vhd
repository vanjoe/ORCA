-- barrel_shifter.vhd
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

entity barrel_shifter is
  generic (
    WORD_WIDTH : integer := 1;
    WORDS      : integer := 1;
    LEFT_SHIFT : boolean := false
    );
  port (
    data_in      : in std_logic_vector(WORD_WIDTH*WORDS-1 downto 0);
    shift_amount : in std_logic_vector(log2(WORDS)-1 downto 0);

    data_out : out std_logic_vector(WORD_WIDTH*WORDS-1 downto 0)
    );
end entity barrel_shifter;

architecture rtl of barrel_shifter is
  type data_2d_type is array (WORD_WIDTH-1 downto 0) of std_logic_vector(WORDS-1 downto 0);
  signal data_in_2d : data_2d_type;
  signal data_out_2d : data_2d_type;
begin

  bs_gen: for gbit in WORD_WIDTH-1 downto 0 generate
    bsw_gen: for gword in WORDS-1 downto 0 generate
      data_in_2d(gbit)(gword) <= data_in(gword*WORD_WIDTH+gbit);
      data_out(gword*WORD_WIDTH+gbit) <= data_out_2d(gbit)(gword);
    end generate bsw_gen;

    bs_ls_gen: if LEFT_SHIFT generate
      data_out_2d(gbit) <= std_logic_vector(unsigned(data_in_2d(gbit)) rol to_integer(unsigned(shift_amount)));
    end generate bs_ls_gen;
    bs_rs_gen: if not LEFT_SHIFT generate
      data_out_2d(gbit) <= std_logic_vector(unsigned(data_in_2d(gbit)) ror to_integer(unsigned(shift_amount)));
    end generate bs_rs_gen;
  end generate bs_gen;
  
end architecture rtl;
