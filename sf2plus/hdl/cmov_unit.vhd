-- cmov_unit.vhd
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

entity cmov_unit is
  generic (
    VECTOR_LANES : integer := 1
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    instruction : in instruction_type;

    data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

    cmov_byteena : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    cmov_out     : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
    );
end entity cmov_unit;

architecture rtl of cmov_unit is
  signal byte_zero : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal half_zero : std_logic_vector((VECTOR_LANES*2)-1 downto 0);
  signal word_zero : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte_neg  : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal half_neg  : std_logic_vector((VECTOR_LANES*2)-1 downto 0);
  signal word_neg  : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte_ena  : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal half_ena  : std_logic_vector((VECTOR_LANES*2)-1 downto 0);
  signal word_ena  : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal op_size   : std_logic_vector(1 downto 0);
  signal op_signed : std_logic;
  signal use_neg   : std_logic;
  signal use_zero  : std_logic;
  signal invert    : std_logic;
begin
  cmov_out  <= data_a;
  op_size   <= instruction.size;
  op_signed <= instruction.signedness;

  use_neg  <= not instruction.op(2);
  use_zero <= not instruction.op(1);
  invert   <= instruction.op(0);

  cmov_word_gen : for gword in VECTOR_LANES-1 downto 0 generate
    word_zero(gword) <= byte_zero(gword*4) and byte_zero(gword*4+1) and byte_zero(gword*4+2) and byte_zero(gword*4+3);
    word_neg(gword)  <= byte_neg(gword*4+3);
    word_ena(gword)  <= ((use_neg and word_neg(gword)) or (use_zero and word_zero(gword))) xor invert;

    with op_size select
      cmov_byteena(gword*4+3) <=
      byte_ena(gword*4+3) when OPSIZE_BYTE,
      half_ena(gword*2+1) when OPSIZE_HALF,
      word_ena(gword)     when others;
    with op_size select
      cmov_byteena(gword*4+2) <=
      byte_ena(gword*4+2) when OPSIZE_BYTE,
      half_ena(gword*2+1) when OPSIZE_HALF,
      word_ena(gword)     when others;
    with op_size select
      cmov_byteena(gword*4+1) <=
      byte_ena(gword*4+1) when OPSIZE_BYTE,
      half_ena(gword*2)   when OPSIZE_HALF,
      word_ena(gword)     when others;
    with op_size select
      cmov_byteena(gword*4) <=
      byte_ena(gword*4) when OPSIZE_BYTE,
      half_ena(gword*2) when OPSIZE_HALF,
      word_ena(gword)   when others;
    
  end generate cmov_word_gen;

  cmov_half_gen : for ghalf in (VECTOR_LANES*2)-1 downto 0 generate
    half_zero(ghalf) <= byte_zero(ghalf*2) and byte_zero(ghalf*2+1);
    half_neg(ghalf)  <= byte_neg(ghalf*2+1);
    half_ena(ghalf)  <= ((use_neg and half_neg(ghalf)) or (use_zero and half_zero(ghalf))) xor invert;
  end generate cmov_half_gen;

  cmov_byte_gen : for gbyte in (VECTOR_LANES*4)-1 downto 0 generate
    byte_zero(gbyte) <= '1'                when data_b(gbyte).data = "00000000" else '0';
    byte_neg(gbyte)  <= data_b(gbyte).flag when op_signed = '0'                 else (data_b(gbyte).flag xor data_b(gbyte).data(7));
    byte_ena(gbyte)  <= ((use_neg and byte_neg(gbyte)) or (use_zero and byte_zero(gbyte))) xor invert;
  end generate cmov_byte_gen;

  
end architecture rtl;
