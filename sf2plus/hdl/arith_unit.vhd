-- arith_unit.vhd
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

entity arith_unit is
  generic (
    VECTOR_LANES : integer := 1
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    next_instruction : in instruction_type;
    instruction      : in instruction_type;

    data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

    arith_out : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
    );
end entity arith_unit;

architecture rtl of arith_unit is
  signal word0_a : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_b : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_a : half16_scratchpad_data((VECTOR_LANES*2)-1 downto 0);
  signal half1_b : half16_scratchpad_data((VECTOR_LANES*2)-1 downto 0);
  signal byte1_a : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal byte1_b : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal byte3_a : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal byte3_b : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal add_word0_in_a : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal add_word0_in_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal add_half1_in_a : half17_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal add_half1_in_b : half17_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal add_byte1_in_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal add_byte1_in_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal add_byte3_in_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal add_byte3_in_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal word0_in_a : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_in_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_in_a : half17_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_in_b : half17_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte1_in_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte1_in_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte3_in_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte3_in_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal word0_result : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_result : half17_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte1_result : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte3_result : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);

  type flag_bits_type is record
    a_msb  : std_logic;
    b_msb  : std_logic;
    r_msb  : std_logic;
    r_cout : std_logic;
  end record;
  type flag_bits_array is array (VECTOR_LANES-1 downto 0) of flag_bits_type;

  signal word0_bits : flag_bits_array;
  signal half1_bits : flag_bits_array;
  signal byte1_bits : flag_bits_array;
  signal byte3_bits : flag_bits_array;
  signal word0_flag : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal half1_flag : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte1_flag : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte3_flag : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal op_signed           : std_logic;
  signal op_sub              : std_logic;
  signal op_size             : opsize;
  signal size_byte           : std_logic;
  signal size_half           : std_logic;
  signal size_word           : std_logic;

  signal addc_or_subb              : std_logic;

  signal cin33 : unsigned(32 downto 0);
  signal cin17 : unsigned(16 downto 0);
  signal cin9  : unsigned(8 downto 0);
begin

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      op_size   <= next_instruction.size;
      op_signed <= next_instruction.signedness;
      size_word <= next_instruction.size(1);

      op_sub       <= next_instruction.op(0);
      size_byte    <= (not next_instruction.size(1)) and (not next_instruction.size(0));
      size_half    <= next_instruction.size(0);
      addc_or_subb <= op_is_addc_subb(next_instruction.op);
    end if;
  end process;

  cin33(32 downto 1) <= (others => '0');
  cin33(0)           <= op_sub;
  cin17(16 downto 1) <= (others => '0');
  cin17(0)           <= op_sub;
  cin9(8 downto 1)   <= (others => '0');
  cin9(0)            <= op_sub;

  arith_word_gen : for gword in VECTOR_LANES-1 downto 0 generate
    word0_a(gword)                      <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword);
    add_word0_in_a(gword)(7 downto 0)   <= word0_a(gword)(7 downto 0);
    add_word0_in_a(gword)(8)            <= '0'                                                      when size_byte = '1' else word0_a(gword)(8);
    add_word0_in_a(gword)(15 downto 9)  <= word0_a(gword)(15 downto 9);
    add_word0_in_a(gword)(16)           <= '0'                                                      when size_half = '1' else word0_a(gword)(16);
    add_word0_in_a(gword)(32 downto 17) <= '0' & word0_a(gword)(31 downto 17);
    word0_b(gword)                      <= scratchpad_data_to_word32_scratchpad_data(data_b)(gword) when
                                           addc_or_subb = '0' else
                                           (0 => data_b(gword*4).flag, others => '0');
    add_word0_in_b(gword)(7 downto 0)   <= word0_b(gword)(7 downto 0);
    add_word0_in_b(gword)(8)            <= '0' when size_byte = '1' else word0_b(gword)(8);
    add_word0_in_b(gword)(15 downto 9)  <= word0_b(gword)(15 downto 9);
    add_word0_in_b(gword)(16)           <= '0' when size_half = '1' else word0_b(gword)(16);
    add_word0_in_b(gword)(32 downto 17) <= '0' & word0_b(gword)(31 downto 17);

    half1_a(gword)                     <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(31 downto 16);
    add_half1_in_a(gword)(7 downto 0)  <= half1_a(gword)(7 downto 0);
    add_half1_in_a(gword)(8)           <= '0'                                                                    when size_byte = '1' else half1_a(gword)(8);
    add_half1_in_a(gword)(16 downto 9) <= '0' & half1_a(gword)(15 downto 9);
    half1_b(gword)                     <= scratchpad_data_to_word32_scratchpad_data(data_b)(gword)(31 downto 16) when
                                          addc_or_subb = '0' else
                                          (0 => data_b(gword*4+2).flag, others => '0');
    add_half1_in_b(gword)(7 downto 0)  <= half1_b(gword)(7 downto 0);
    add_half1_in_b(gword)(8)           <= '0' when size_byte = '1' else half1_b(gword)(8);
    add_half1_in_b(gword)(16 downto 9) <= '0' & half1_b(gword)(15 downto 9);

    byte1_a(gword)        <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(15 downto 8);
    add_byte1_in_a(gword) <= '0' & byte1_a(gword);
    byte1_b(gword)        <= scratchpad_data_to_word32_scratchpad_data(data_b)(gword)(15 downto 8) when
                             addc_or_subb = '0' else
                             (0 => data_b(gword*4+1).flag, others => '0');
    add_byte1_in_b(gword) <= '0' & byte1_b(gword);

    byte3_a(gword)        <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(31 downto 24);
    add_byte3_in_a(gword) <= '0' & byte3_a(gword);
    byte3_b(gword)        <= scratchpad_data_to_word32_scratchpad_data(data_b)(gword)(31 downto 24) when
                             addc_or_subb = '0' else
                             (0 => data_b(gword*4+3).flag, others => '0');
    add_byte3_in_b(gword) <= '0' & byte3_b(gword);

    word0_in_a(gword) <= add_word0_in_a(gword);
    word0_in_b(gword) <= not add_word0_in_b(gword) when op_sub = '1' else add_word0_in_b(gword);
    half1_in_a(gword) <= add_half1_in_a(gword);
    half1_in_b(gword) <= not add_half1_in_b(gword) when op_sub = '1' else add_half1_in_b(gword);
    byte1_in_a(gword) <= add_byte1_in_a(gword);
    byte1_in_b(gword) <= not add_byte1_in_b(gword) when op_sub = '1' else add_byte1_in_b(gword);
    byte3_in_a(gword) <= add_byte3_in_a(gword);
    byte3_in_b(gword) <= not add_byte3_in_b(gword) when op_sub = '1' else add_byte3_in_b(gword);

    word0_result(gword) <= std_logic_vector(unsigned(word0_in_a(gword)) + unsigned(word0_in_b(gword)) + cin33);
    half1_result(gword) <= std_logic_vector(unsigned(half1_in_a(gword)) + unsigned(half1_in_b(gword)) + cin17);
    byte1_result(gword) <= std_logic_vector(unsigned(byte1_in_a(gword)) + unsigned(byte1_in_b(gword)) + cin9);
    byte3_result(gword) <= std_logic_vector(unsigned(byte3_in_a(gword)) + unsigned(byte3_in_b(gword)) + cin9);

    arith_out(gword*4+0).data <= word0_result(gword)(7 downto 0);
    with size_byte select
      arith_out(gword*4+1).data <=
      byte1_result(gword)(7 downto 0)  when '1',
      word0_result(gword)(15 downto 8) when others;
    with size_word select
      arith_out(gword*4+2).data <=
      word0_result(gword)(23 downto 16) when '1',
      half1_result(gword)(7 downto 0)   when others;
    with op_size select
      arith_out(gword*4+3).data <=
      byte3_result(gword)(7 downto 0)   when OPSIZE_BYTE,
      half1_result(gword)(15 downto 8)  when OPSIZE_HALF,
      word0_result(gword)(31 downto 24) when others;


    with op_size select
      word0_bits(gword) <=
      (a_msb => word0_in_a(gword)(7), b_msb => word0_in_b(gword)(7),
       r_msb => word0_result(gword)(7), r_cout => word0_result(gword)(8)) when OPSIZE_BYTE,
      (a_msb => word0_in_a(gword)(15), b_msb => word0_in_b(gword)(15),
       r_msb => word0_result(gword)(15), r_cout => word0_result(gword)(16)) when OPSIZE_HALF,
      (a_msb => word0_in_a(gword)(31), b_msb => word0_in_b(gword)(31),
       r_msb => word0_result(gword)(31), r_cout => word0_result(gword)(32)) when others;
    word0_flag(gword) <= ((not (word0_bits(gword).a_msb xor word0_bits(gword).b_msb)) and
                          (word0_bits(gword).a_msb xor word0_bits(gword).r_msb))
                         when op_signed = '1' else word0_bits(gword).r_cout;

    with size_byte select
      half1_bits(gword) <=
      (a_msb => half1_in_a(gword)(7), b_msb => half1_in_b(gword)(7),
       r_msb => half1_result(gword)(7), r_cout => half1_result(gword)(8)) when '1',
      (a_msb => half1_in_a(gword)(15), b_msb => half1_in_b(gword)(15),
       r_msb => half1_result(gword)(15), r_cout => half1_result(gword)(16)) when others;
    half1_flag(gword) <= ((not (half1_bits(gword).a_msb xor half1_bits(gword).b_msb)) and
                          (half1_bits(gword).a_msb xor half1_bits(gword).r_msb))
                         when op_signed = '1' else half1_bits(gword).r_cout;

    byte1_bits(gword) <=
      (a_msb => byte1_in_a(gword)(7), b_msb => byte1_in_b(gword)(7),
       r_msb => byte1_result(gword)(7), r_cout => byte1_result(gword)(8));
    byte1_flag(gword) <= ((not (byte1_bits(gword).a_msb xor byte1_bits(gword).b_msb)) and
                          (byte1_bits(gword).a_msb xor byte1_bits(gword).r_msb))
                         when op_signed = '1' else byte1_bits(gword).r_cout;

    byte3_bits(gword) <=
      (a_msb => byte3_in_a(gword)(7), b_msb => byte3_in_b(gword)(7),
       r_msb => byte3_result(gword)(7), r_cout => byte3_result(gword)(8));
    byte3_flag(gword) <= ((not (byte3_bits(gword).a_msb xor byte3_bits(gword).b_msb)) and
                          (byte3_bits(gword).a_msb xor byte3_bits(gword).r_msb))
                         when op_signed = '1' else byte3_bits(gword).r_cout;
    
    arith_out(gword*4+0).flag <= word0_flag(gword);
    with size_byte select
      arith_out(gword*4+1).flag <=
      byte1_flag(gword) when '1',
      word0_flag(gword) when others;
    with size_word select
      arith_out(gword*4+2).flag <=
      word0_flag(gword) when '1',
      half1_flag(gword) when others;
    with op_size select
      arith_out(gword*4+3).flag <=
      byte3_flag(gword) when OPSIZE_BYTE,
      half1_flag(gword) when OPSIZE_HALF,
      word0_flag(gword) when others;
  end generate arith_word_gen;

end architecture rtl;
