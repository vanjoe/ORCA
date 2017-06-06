-- size_down.vhd
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

entity size_down is
  generic (
    VECTOR_LANES : integer := 1
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    instruction      : in instruction_type;
    next_instruction : in instruction_type;

    data_in    : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    byteena_in : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);

    data_out    : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    byteena_out : out std_logic_vector((VECTOR_LANES*4)-1 downto 0)
    );
end entity size_down;

architecture rtl of size_down is
  signal half_to_byte         : scratchpad_data((VECTOR_LANES*2)-1 downto 0);
  signal word_to_byte         : scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word_to_half         : scratchpad_data((VECTOR_LANES*2)-1 downto 0);
  signal half_to_byte_byteena : std_logic_vector((VECTOR_LANES*2)-1 downto 0);
  signal word_to_byte_byteena : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word_to_half_byteena : std_logic_vector((VECTOR_LANES*2)-1 downto 0);


  signal in_size     : opsize;
  signal out_size    : opsize;
  signal in_out_size : std_logic_vector(3 downto 0);

  type   conv_down_type is (WORD_HALF, WORD_BYTE, HALF_BYTE, NONE);
  signal conversion : conv_down_type;
begin

  --Register in & out size for timing
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then
        out_size <= (others => '0');
      else
        out_size <= next_instruction.out_size;
      end if;

      if next_instruction.acc = '0' then
        in_size <= next_instruction.size;
      else
        in_size <= OPSIZE_WORD;
      end if;
    end if;
  end process;
  in_out_size <= in_size & out_size;

  with in_out_size select
    conversion <=
    WORD_HALF when "1001",
    WORD_BYTE when "1000",
    HALF_BYTE when "0100",
    NONE      when others;

  conv_q1_gen : for gq1 in VECTOR_LANES-1 downto 0 generate
    with conversion select
      data_out(gq1) <=
      word_to_half(gq1) when WORD_HALF,
      word_to_byte(gq1) when WORD_BYTE,
      half_to_byte(gq1) when HALF_BYTE,
      data_in(gq1)      when others;
    with conversion select
      byteena_out(gq1) <=
      word_to_byte_byteena(gq1) when WORD_BYTE,
      half_to_byte_byteena(gq1) when HALF_BYTE,
      word_to_half_byteena(gq1) when WORD_HALF,
      byteena_in(gq1)           when others;
  end generate conv_q1_gen;
  conv_q2_gen : for gq2 in (VECTOR_LANES*2)-1 downto VECTOR_LANES generate
    with conversion select
      data_out(gq2) <=
      word_to_half(gq2) when WORD_HALF,
      half_to_byte(gq2) when HALF_BYTE,
      data_in(gq2)      when others;
    with conversion select
      byteena_out(gq2) <=
      '0'                       when WORD_BYTE,
      half_to_byte_byteena(gq2) when HALF_BYTE,
      word_to_half_byteena(gq2) when WORD_HALF,
      byteena_in(gq2)           when others;
  end generate conv_q2_gen;
  conv_h2_gen : for gh2 in (VECTOR_LANES*4)-1 downto (VECTOR_LANES*2) generate
    data_out(gh2) <= data_in(gh2);
    with conversion select
      byteena_out(gh2) <=
      byteena_in(gh2) when NONE,
      '0'             when others;
  end generate conv_h2_gen;

  conv_half_gen : for ghalf in (VECTOR_LANES*2)-1 downto 0 generate
    half_to_byte(ghalf)         <= data_in(ghalf*2);
    half_to_byte_byteena(ghalf) <= byteena_in(ghalf*2);
  end generate conv_half_gen;

  conv_word_gen : for gword in VECTOR_LANES-1 downto 0 generate
    word_to_byte(gword)             <= data_in(gword*4);
    word_to_byte_byteena(gword)     <= byteena_in(gword*4);
    word_to_half(gword*2)           <= data_in(gword*4);
    word_to_half(gword*2+1)         <= data_in(gword*4+1);
    word_to_half_byteena(gword*2)   <= byteena_in(gword*4);
    word_to_half_byteena(gword*2+1) <= byteena_in(gword*4+1);
  end generate conv_word_gen;

end architecture rtl;
