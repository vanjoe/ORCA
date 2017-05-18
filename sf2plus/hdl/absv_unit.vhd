-- absv_unit.vhd
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

entity absv_unit is
  generic (
    VECTOR_LANES : integer := 1
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    next_instruction : in instruction_type;
    instruction      : in instruction_type;

    alu_result : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

    absv_out : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
    );
end entity absv_unit;

architecture rtl of absv_unit is
  signal word0_in : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_in : half16_scratchpad_data((VECTOR_LANES*2)-1 downto 0);
  signal byte1_in : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal byte3_in : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal word0_neg : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal half1_neg : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte1_neg : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte3_neg : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal word0_result : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_result : half16_scratchpad_data((VECTOR_LANES*2)-1 downto 0);
  signal byte1_result : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal byte3_result : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal next_op_size : opsize;

  signal op_signed : std_logic_vector(((VECTOR_LANES+3)/4)-1 downto 0);
  signal op_size   : opsize;
  signal op_absv   : std_logic;
  signal size_byte : std_logic;
  signal size_half : std_logic;
  signal size_word : std_logic;
begin

  next_op_size <= next_instruction.size;
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      op_absv   <= op_is_absv(next_instruction.op);
      op_signed <= (others => next_instruction.signedness);
      op_size   <= next_op_size;
      if next_op_size = OPSIZE_BYTE then
        size_byte <= '1';
      else
        size_byte <= '0';
      end if;

      size_half <= next_op_size(0);
      size_word <= next_op_size(1);
      if reset = '1' then
        for i4lane in op_signed'left downto 0 loop
          op_signed(i4lane) <= op_signed((i4lane+1) mod op_signed'length);
        end loop;  -- i4lane
        size_half <= '0';
        size_word <= '0';
      end if;
    end if;
  end process;

  absv_word_gen : for gword in VECTOR_LANES-1 downto 0 generate
    word0_in(gword) <= scratchpad_data_to_word32_scratchpad_data(alu_result)(gword);
    word0_neg(gword) <= (op_absv and
                         ((size_word and ((op_signed(gword/4) and (word0_in(gword)(31) xor alu_result(gword*4).flag)) or
                                          ((not op_signed(gword/4)) and alu_result(gword*4).flag))) or
                          (size_half and ((op_signed(gword/4) and (word0_in(gword)(15) xor alu_result(gword*4).flag)) or
                                          ((not op_signed(gword/4)) and alu_result(gword*4).flag))) or
                          ((not size_word) and (not size_half) and
                           ((op_signed(gword/4) and (word0_in(gword)(7) xor alu_result(gword*4).flag)) or
                            ((not op_signed(gword/4)) and alu_result(gword*4).flag)))));

    half1_in(gword) <= scratchpad_data_to_word32_scratchpad_data(alu_result)(gword)(31 downto 16);
    half1_neg(gword) <= (op_absv and
                         ((size_half and ((op_signed(gword/4) and (half1_in(gword)(15) xor alu_result(gword*4+2).flag)) or
                                          ((not op_signed(gword/4)) and alu_result(gword*4+2).flag))) or
                          ((not size_half) and
                           ((op_signed(gword/4) and (half1_in(gword)(7) xor alu_result(gword*4+2).flag)) or
                            ((not op_signed(gword/4)) and alu_result(gword*4+2).flag)))));

    byte1_in(gword) <= scratchpad_data_to_word32_scratchpad_data(alu_result)(gword)(15 downto 8);
    byte1_neg(gword) <= (op_absv and
                         ((op_signed(gword/4) and (byte1_in(gword)(7) xor alu_result(gword*4+1).flag)) or
                          ((not op_signed(gword/4)) and alu_result(gword*4+1).flag)));

    byte3_in(gword) <= scratchpad_data_to_word32_scratchpad_data(alu_result)(gword)(31 downto 24);
    byte3_neg(gword) <= (op_absv and
                         ((op_signed(gword/4) and (byte3_in(gword)(7) xor alu_result(gword*4+3).flag)) or
                          ((not op_signed(gword/4)) and alu_result(gword*4+3).flag)));


    word0_result(gword) <= word0_in(gword) when word0_neg(gword) = '0' else
                           std_logic_vector(to_unsigned(0, 32) - unsigned(word0_in(gword)));
    half1_result(gword) <= half1_in(gword) when half1_neg(gword) = '0' else
                           std_logic_vector(to_unsigned(0, 16) - unsigned(half1_in(gword)));
    byte1_result(gword) <= byte1_in(gword) when byte1_neg(gword) = '0' else
                           std_logic_vector(to_unsigned(0, 8) - unsigned(byte1_in(gword)));
    byte3_result(gword) <= byte3_in(gword) when byte3_neg(gword) = '0' else
                           std_logic_vector(to_unsigned(0, 8) - unsigned(byte3_in(gword)));

    absv_out(gword*4+0).data <= word0_result(gword)(7 downto 0);
    with op_size select
      absv_out(gword*4+1).data <=
      byte1_result(gword)(7 downto 0)  when OPSIZE_BYTE,
      word0_result(gword)(15 downto 8) when others;
    with op_size select
      absv_out(gword*4+2).data <=
      word0_result(gword)(23 downto 16) when OPSIZE_WORD,
      half1_result(gword)(7 downto 0)   when others;
    with op_size select
      absv_out(gword*4+3).data <=
      byte3_result(gword)(7 downto 0)   when OPSIZE_BYTE,
      half1_result(gword)(15 downto 8)  when OPSIZE_HALF,
      word0_result(gword)(31 downto 24) when others;

    --FIXME: ABSV should change flag if abs selected
    absv_out(gword*4+0).flag <= alu_result(gword*4+0).flag;
    absv_out(gword*4+1).flag <= alu_result(gword*4+1).flag;
    absv_out(gword*4+2).flag <= alu_result(gword*4+2).flag;
    absv_out(gword*4+3).flag <= alu_result(gword*4+3).flag;
  end generate absv_word_gen;

end architecture rtl;
