-- size_up.vhd
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

entity size_up is
  generic (
    VECTOR_LANES : integer := 1
    );
  port(
    clk : in std_logic;

    next_instruction : in instruction_type;

    data_in  : in  scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    data_out : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
    );
end entity size_up;

architecture rtl of size_up is
  signal byte_to_half : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal byte_to_word : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal half_to_word : scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal next_in_size     : opsize;
  signal next_out_size    : opsize;
  signal next_in_out_size : std_logic_vector(3 downto 0);
  signal next_op_signed   : std_logic;

  type   conv_up_type is (BYTE_HALF, BYTE_WORD, HALF_WORD, NONE);
  signal next_conversion : conv_up_type;

  signal op_signed  : std_logic;
  signal conversion : conv_up_type;
begin

  next_in_size     <= next_instruction.in_size;
  next_out_size    <= next_instruction.size;
  next_in_out_size <= next_in_size & next_out_size;

  next_op_signed <= next_instruction.signedness;
  with next_in_out_size select
    next_conversion <=
    BYTE_HALF when "0001",
    BYTE_WORD when "0010",
    HALF_WORD when "0110",
    NONE      when others;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      op_signed  <= next_op_signed;
      conversion <= next_conversion;
    end if;
  end process;

  with conversion select
    data_out <=
    byte_to_half when BYTE_HALF,
    byte_to_word when BYTE_WORD,
    half_to_word when HALF_WORD,
    data_in      when others;
  
  conv_half_gen : for ghalf in (VECTOR_LANES*2)-1 downto 0 generate
    byte_to_half(ghalf*2)        <= data_in(ghalf);
    byte_to_half(ghalf*2+1).flag <= data_in(ghalf).flag;
    byte_to_half(ghalf*2+1).data <= "11111111" when data_in(ghalf).data(7) = '1' and op_signed = '1' else "00000000";
  end generate conv_half_gen;

  conv_word_gen : for gword in VECTOR_LANES-1 downto 0 generate
    half_to_word(gword*4)        <= data_in(gword*2);
    half_to_word(gword*4+1)      <= data_in(gword*2+1);
    half_to_word(gword*4+2).flag <= data_in(gword*2+1).flag;
    half_to_word(gword*4+2).data <= "11111111" when data_in(gword*2+1).data(7) = '1' and op_signed = '1' else "00000000";
    half_to_word(gword*4+3)      <= half_to_word(gword*4+2);
    byte_to_word(gword*4)        <= data_in(gword);
    byte_to_word(gword*4+1).flag <= data_in(gword).flag;
    byte_to_word(gword*4+1).data <= "11111111" when data_in(gword).data(7) = '1' and op_signed = '1'     else "00000000";
    byte_to_word(gword*4+2)      <= byte_to_word(gword*4+1);
    byte_to_word(gword*4+3)      <= byte_to_word(gword*4+1);
  end generate conv_word_gen;

end architecture rtl;
