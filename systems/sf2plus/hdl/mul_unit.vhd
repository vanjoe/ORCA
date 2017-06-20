-- mul_unit.vhd
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

entity mul_unit is
  generic (
    VECTOR_LANES : integer := 1;

    MULFXP_WORD_FRACTION_BITS : integer range 1 to 31 := 25;
    MULFXP_HALF_FRACTION_BITS : integer range 1 to 15 := 15;
    MULFXP_BYTE_FRACTION_BITS : integer range 1 to 7  := 4;

    CFG_FAM         : config_family_type;

    PIPELINE_STAGES : integer := 1;
    STAGE_MUL_START : integer := 1;
    STAGE_MUL_END   : integer := 1
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    instruction_pipeline : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);

    data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

    multiplier_out : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
    );
end entity mul_unit;

architecture byte of mul_unit is
  constant MULTIPLIER_DELAY : positive := CFG_SEL(CFG_FAM).MULTIPLIER_DELAY;

  signal word0_a : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_a : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_b : half17_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte1_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte1_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte3_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte3_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_word0_in_a : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_word0_in_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_half1_in_a : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_half1_in_b : half17_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_byte3_in_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_byte3_in_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_byte1_in_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_byte1_in_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_byte1_in_b_posneg : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_byte3_in_b_posneg : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_word0_result : dubl67_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_half1_result : word35_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_byte3_result : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_byte1_result : half18_scratchpad_data(VECTOR_LANES-1 downto 0);

  type shamt5_scratchpad_data is array (natural range <>) of std_logic_vector(4 downto 0);
  type shamt4_scratchpad_data is array (natural range <>) of std_logic_vector(3 downto 0);
  type shamt3_scratchpad_data is array (natural range <>) of std_logic_vector(2 downto 0);

  signal word0_shamt                   : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_shamt_of_h              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word0_shamt_of_b              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word0_shamt_of                : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word0_shamt_trunc             : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shamt                   : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shamt_of_h              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal half1_shamt_of_b              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal half1_shamt_of                : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal half1_shamt_trunc             : shamt4_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shiftl_int              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte1_shamt                   : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte1_shamt_of                : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte1_shamt_trunc             : shamt3_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte1_shiftl_int              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte3_shamt                   : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte3_shamt_of                : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal byte3_shamt_trunc             : shamt3_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte3_shiftl_int              : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal word0_shift_in      : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_shamt_rom_out : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shift_in      : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shamt_rom_out : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte1_shift_in      : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte1_shamt_rom_out : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte3_shift_in      : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte3_shamt_rom_out : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_shift_word0_in_a : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_word0_in_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_half1_in_a : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_half1_in_b : half17_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_byte1_in_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_byte1_in_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_byte3_in_a : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_byte3_in_b : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal start_rot                   : std_logic;
  signal start_shift                 : std_logic;
  signal start_shiftl                : std_logic;
  signal start_signed                : std_logic;
  signal start_size                  : opsize;
  signal end_signed                  : std_logic;
  signal end_size                    : opsize;
  signal start_byte                  : std_logic;
  signal start_word                  : std_logic;
  attribute dont_merge of start_word : signal is true;
  signal start_half                  : std_logic;
  attribute dont_merge of start_half : signal is true;
  signal start_mulhi                 : std_logic;

  type   mul_flag_shifter_type is array ((VECTOR_LANES*4)-1 downto 0) of std_logic_vector(MULTIPLIER_DELAY downto 0);
  signal rot_flag_shifter : mul_flag_shifter_type;

  signal mul_word0_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half0_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half1_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte0_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte1_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte2_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte3_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal mul_word0_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half0_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half1_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte0_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte1_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte2_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte3_round : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal fxp_word0_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half0_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half1_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte0_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte1_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte2_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte3_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_word0_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half0_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half1_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte0_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte1_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte2_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte3_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_word0_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half0_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half1_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte0_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte1_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte2_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte3_of     : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal mul_out_low  : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_high : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_fxp  : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal mul_out      : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal mul_out_fxp_word0 : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_half0 : half16_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_half1 : half16_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_byte0 : byte8_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_byte1 : byte8_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_byte2 : byte8_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_byte3 : byte8_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_out_low_flag      : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_low_flag_reg  : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_high_flag     : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_high_flag_reg : std_logic_vector((VECTOR_LANES*4)-1 downto 0);

  signal fxp_mul_flag          : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal fxp_mul_flag_reg      : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal end_fxp_dn1           : std_logic;
  type   mul_type is (MULHI_SHIFTR, MULLO_SHIFTL, MULFXP, ROTLR);
  signal end_mul_type_dn1      : mul_type;
  signal end_mul_type          : mul_type;
  signal end_mul_type_reg      : mul_type;
  signal end_rot_not_mul_dn1   : std_logic;
  signal end_mulhi_shiftr_dn1  : std_logic;
  signal end_rot_mulhi_fxp_dn1 : std_logic_vector(2 downto 0);
begin
  -- Check that parameters are valid
  assert MULTIPLIER_INPUT_REG >= 0
    and MULTIPLIER_INPUT_REG <= 1
    report "MULTIPLIER_INPUT_REG ("
    & integer'image(MULTIPLIER_INPUT_REG) &
    ") must be either 0 or 1"
    severity failure;

  -- purpose: register separately from instruction pipeline, for timing
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      start_shiftl <= not instruction_pipeline(STAGE_MUL_START-1).op(0);
      start_word   <= instruction_pipeline(STAGE_MUL_START-1).size(1);
      start_half   <= instruction_pipeline(STAGE_MUL_START-1).size(0);
      start_shift  <= op_is_shift(instruction_pipeline(STAGE_MUL_START-1).op);
      start_rot    <= instruction_pipeline(STAGE_MUL_START-1).op(1);
      if op_is_shift(instruction_pipeline(STAGE_MUL_START-1).op) = '0' then
        start_signed <= instruction_pipeline(STAGE_MUL_START-1).signedness;
      else
        start_signed <= (instruction_pipeline(STAGE_MUL_START-1).signedness and
                         (not instruction_pipeline(STAGE_MUL_START-1).op(1)));
      end if;
      start_size  <= instruction_pipeline(STAGE_MUL_START-1).size;
      start_mulhi <= instruction_pipeline(STAGE_MUL_START-1).op(0);
      start_byte  <= (not instruction_pipeline(STAGE_MUL_START-1).size(1)) and
                     (not instruction_pipeline(STAGE_MUL_START-1).size(0));

      end_mul_type <= end_mul_type_dn1;
      if op_is_shift(instruction_pipeline(STAGE_MUL_END-1).op) = '0' then
        end_signed <= instruction_pipeline(STAGE_MUL_END-1).signedness;
      else
        end_signed <= (instruction_pipeline(STAGE_MUL_END-1).signedness and
                       (not instruction_pipeline(STAGE_MUL_END-1).op(1)));
      end if;
      end_size <= instruction_pipeline(STAGE_MUL_END-1).size;
    end if;
  end process;
  end_fxp_dn1 <= (not op_is_shift(instruction_pipeline(STAGE_MUL_END-1).op)) and
                 instruction_pipeline(STAGE_MUL_END-1).op(1);
  end_rot_not_mul_dn1 <= op_is_shift(instruction_pipeline(STAGE_MUL_END-1).op) and
                         instruction_pipeline(STAGE_MUL_END-1).op(1);
  end_mulhi_shiftr_dn1  <= instruction_pipeline(STAGE_MUL_END-1).op(0);
  end_rot_mulhi_fxp_dn1 <= end_rot_not_mul_dn1 & end_mulhi_shiftr_dn1 & end_fxp_dn1;
  with end_rot_mulhi_fxp_dn1 select
    end_mul_type_dn1 <=
    MULLO_SHIFTL when "000",
    MULHI_SHIFTR when "010",
    MULFXP       when "001",
    MULFXP       when "011",
    ROTLR        when others;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      end_mul_type_reg <= end_mul_type;
    end if;
  end process;

  mult_word_gen : for gword in VECTOR_LANES-1 downto 0 generate
    word0_a(gword) <= "00" & scratchpad_data_to_word32_scratchpad_data(data_a)(gword);
    with start_size select
      mul_word0_in_a(gword) <=
      s_z_extend(31, start_signed, word0_a(gword)) when OPSIZE_WORD,
      s_z_extend(15, start_signed, word0_a(gword)) when OPSIZE_HALF,
      s_z_extend(7, start_signed, word0_a(gword))  when others;
    word0_b(gword) <= '0' & scratchpad_data_to_word32_scratchpad_data(data_b)(gword);
    with start_size select
      mul_word0_in_b(gword) <=
      s_z_extend(31, start_signed, word0_b(gword)) when OPSIZE_WORD,
      s_z_extend(15, start_signed, word0_b(gword)) when OPSIZE_HALF,
      s_z_extend(7, start_signed, word0_b(gword))  when others;

    half1_a(gword) <= "00" & scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(31 downto 16);
    with start_size select
      mul_half1_in_a(gword) <=
      s_z_extend(7, start_signed, half1_a(gword))  when OPSIZE_BYTE,
      s_z_extend(15, start_signed, half1_a(gword)) when others;
    half1_b(gword) <= '0' & scratchpad_data_to_word32_scratchpad_data(data_b)(gword)(31 downto 16);
    with start_size select
      mul_half1_in_b(gword) <=
      s_z_extend(7, start_signed, half1_b(gword))  when OPSIZE_BYTE,
      s_z_extend(15, start_signed, half1_b(gword)) when others;

    byte1_a(gword) <= '0' & scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(15 downto 8);
    byte1_b(gword) <= '0' & scratchpad_data_to_word32_scratchpad_data(data_b)(gword)(15 downto 8);
    byte3_a(gword) <= '0' & scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(31 downto 24);
    byte3_b(gword) <= '0' & scratchpad_data_to_word32_scratchpad_data(data_b)(gword)(31 downto 24);

    mul_byte1_in_a(gword) <= s_z_extend(7, start_signed, byte1_a(gword));
    mul_byte1_in_b(gword) <= s_z_extend(7, start_signed, byte1_b(gword));
    mul_byte3_in_a(gword) <= s_z_extend(7, start_signed, byte3_a(gword));
    mul_byte3_in_b(gword) <= s_z_extend(7, start_signed, byte3_b(gword));

    word0_shamt(gword)      <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(4 downto 0);
    word0_shamt_of_h(gword) <= (not start_rot) and word0_shamt(gword)(4) and
                               start_half;
    word0_shamt_of_b(gword) <= (not start_rot) and (word0_shamt(gword)(4) or word0_shamt(gword)(3)) and
                               start_byte;
    word0_shamt_of(gword)       <= word0_shamt_of_h(gword) or word0_shamt_of_b(gword);
    word0_shamt_trunc(gword)(4) <= word0_shamt(gword)(4) when start_word = '1' else
                                   (not start_shiftl) or word0_shamt_of_h(gword);
    word0_shamt_trunc(gword)(3) <= word0_shamt(gword)(3) and (not word0_shamt_of_h(gword)) when start_byte = '0' else
                                   (not start_shiftl) or word0_shamt_of_b(gword);
    word0_shamt_trunc(gword)(2 downto 0) <= word0_shamt(gword)(2 downto 0) when word0_shamt_of(gword) = '0' else
                                            "000";

    half1_shamt(gword)      <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(20 downto 16);
    half1_shamt_of_h(gword) <= (not start_rot) and half1_shamt(gword)(4) and (not start_byte);
    half1_shamt_of_b(gword) <= (not start_rot) and (half1_shamt(gword)(4) or half1_shamt(gword)(3)) and
                               start_byte;
    half1_shamt_of(gword)       <= half1_shamt_of_h(gword) or half1_shamt_of_b(gword);
    half1_shamt_trunc(gword)(3) <= half1_shamt(gword)(3) and (not half1_shamt_of_h(gword)) when start_byte = '0' else
                                   (not start_shiftl) or half1_shamt_of_b(gword);
    half1_shamt_trunc(gword)(2 downto 0) <= half1_shamt(gword)(2 downto 0) when half1_shamt_of(gword) = '0' else
                                            "000";
    half1_shiftl_int(gword) <= start_shiftl when start_byte = '1' else
                               start_shiftl and (not half1_shamt_of(gword));

    byte1_shamt(gword)                   <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(12 downto 8);
    byte1_shamt_of(gword)                <= (not start_rot) and (byte1_shamt(gword)(4) or byte1_shamt(gword)(3));
    byte1_shamt_trunc(gword)(2 downto 0) <= byte1_shamt(gword)(2 downto 0) when byte1_shamt_of(gword) = '0' else
                                            "000";
    byte1_shiftl_int(gword) <= start_shiftl and (not byte1_shamt_of(gword));

    byte3_shamt(gword)                   <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(28 downto 24);
    byte3_shamt_of(gword)                <= (not start_rot) and (byte3_shamt(gword)(4) or byte3_shamt(gword)(3));
    byte3_shamt_trunc(gword)(2 downto 0) <= byte3_shamt(gword)(2 downto 0) when byte3_shamt_of(gword) = '0' else
                                            "000";
    byte3_shiftl_int(gword) <= start_shiftl and (not byte3_shamt_of(gword));

    word0_shift_in(gword)(33) <= word0_shamt_rom_out(gword)(33);
    word0_shift_in(gword)(32) <= '0' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                 word0_shamt_rom_out(gword)(32);
    word0_shift_in(gword)(31 downto 17) <= word0_shamt_rom_out(gword)(31 downto 17);
    word0_shift_in(gword)(16)           <= '0' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                           word0_shamt_rom_out(gword)(16);
    word0_shift_in(gword)(15 downto 9) <= word0_shamt_rom_out(gword)(15 downto 9);
    word0_shift_in(gword)(8)           <= '0' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                          word0_shamt_rom_out(gword)(8);
    word0_shift_in(gword)(7 downto 1) <= word0_shamt_rom_out(gword)(7 downto 1);
    word0_shift_in(gword)(0)          <= '1' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                         word0_shamt_rom_out(gword)(0);

    half1_shift_in(gword)(17) <= half1_shamt_rom_out(gword)(17);
    half1_shift_in(gword)(16) <= '0' when half1_shamt_of(gword) = '1' and start_shiftl = '0' else
                                 half1_shamt_rom_out(gword)(16);
    half1_shift_in(gword)(15 downto 9) <= half1_shamt_rom_out(gword)(15 downto 9);
    half1_shift_in(gword)(8)           <= '0' when half1_shamt_of(gword) = '1' and start_shiftl = '0' else
                                          half1_shamt_rom_out(gword)(8);
    half1_shift_in(gword)(7 downto 1) <= half1_shamt_rom_out(gword)(7 downto 1);
    half1_shift_in(gword)(0)          <= '1' when half1_shamt_of(gword) = '1' and start_shiftl = '0' else
                                         half1_shamt_rom_out(gword)(0);

    byte1_shift_in(gword)(8) <= '0' when byte1_shamt_of(gword) = '1' and start_shiftl = '0' else
                                byte1_shamt_rom_out(gword)(8);
    byte1_shift_in(gword)(7 downto 1) <= byte1_shamt_rom_out(gword)(7 downto 1);
    byte1_shift_in(gword)(0)          <= '1' when byte1_shamt_of(gword) = '1' and start_shiftl = '0' else
                                         byte1_shamt_rom_out(gword)(0);

    byte3_shift_in(gword)(8) <= '0' when byte3_shamt_of(gword) = '1' and start_shiftl = '0' else
                                byte3_shamt_rom_out(gword)(8);
    byte3_shift_in(gword)(7 downto 1) <= byte3_shamt_rom_out(gword)(7 downto 1);
    byte3_shift_in(gword)(0)          <= '1' when byte3_shamt_of(gword) = '1' and start_shiftl = '0' else
                                         byte3_shamt_rom_out(gword)(0);

    word0_shamt_rom : word_shamt_rom
      port map (
        shamt_trunc        => word0_shamt_trunc(gword),
        shiftl             => start_shiftl,
        word_shamt_rom_out => word0_shamt_rom_out(gword)
        );

    half1_shamt_rom : half_shamt_rom
      port map (
        shamt_trunc        => half1_shamt_trunc(gword),
        shiftl             => half1_shiftl_int(gword),
        half_shamt_rom_out => half1_shamt_rom_out(gword)
        );

    byte1_shamt_rom : byte_shamt_rom
      port map (
        shamt_trunc        => byte1_shamt_trunc(gword),
        shiftl             => byte1_shiftl_int(gword),
        byte_shamt_rom_out => byte1_shamt_rom_out(gword)
        );

    byte3_shamt_rom : byte_shamt_rom
      port map (
        shamt_trunc        => byte3_shamt_trunc(gword),
        shiftl             => byte3_shiftl_int(gword),
        byte_shamt_rom_out => byte3_shamt_rom_out(gword)
        );

    --Negate b inputs if shifting by greatest amount (negative bit).
    --Half/word multipliers use an extra bit to avoid this, but this would make
    --byte multipliers > 9 bits and so use logic outside the DSP block.
    mul_byte1_in_b_posneg(gword) <= mul_byte1_in_b(gword) when start_shift = '0' or byte1_shift_in(gword)(8) = '0' else
                                    std_logic_vector(to_unsigned(0, mul_byte1_in_b(gword)'length) -
                                                     unsigned(mul_byte1_in_b(gword)));
    mul_byte3_in_b_posneg(gword) <= mul_byte3_in_b(gword) when start_shift = '0' or byte3_shift_in(gword)(8) = '0' else
                                    std_logic_vector(to_unsigned(0, mul_byte3_in_b(gword)'length) -
                                                     unsigned(mul_byte3_in_b(gword)));

    mul_in_reg_gen : if MULTIPLIER_INPUT_REG = 1 generate
      mul_in_reg : process (clk)
      begin  -- process mul_in_reg
        if clk'event and clk = '1' then  -- rising clock edge
          if start_shift = '1' then
            mul_shift_word0_in_a(gword) <= word0_shift_in(gword);
            mul_shift_half1_in_a(gword) <= half1_shift_in(gword);
            mul_shift_byte1_in_a(gword) <= byte1_shift_in(gword);
            mul_shift_byte3_in_a(gword) <= byte3_shift_in(gword);
          else
            mul_shift_word0_in_a(gword) <= mul_word0_in_a(gword);
            mul_shift_half1_in_a(gword) <= mul_half1_in_a(gword);
            mul_shift_byte1_in_a(gword) <= mul_byte1_in_a(gword);
            mul_shift_byte3_in_a(gword) <= mul_byte3_in_a(gword);
          end if;
          mul_shift_word0_in_b(gword) <= mul_word0_in_b(gword);
          mul_shift_half1_in_b(gword) <= mul_half1_in_b(gword);
          mul_shift_byte1_in_b(gword) <= mul_byte1_in_b_posneg(gword);
          mul_shift_byte3_in_b(gword) <= mul_byte3_in_b_posneg(gword);
        end if;
      end process mul_in_reg;
    end generate mul_in_reg_gen;
    mul_in_no_reg_gen : if MULTIPLIER_INPUT_REG = 0 generate
      mul_shift_word0_in_a(gword) <= word0_shift_in(gword) when start_shift = '1' else mul_word0_in_a(gword);
      mul_shift_half1_in_a(gword) <= half1_shift_in(gword) when start_shift = '1' else mul_half1_in_a(gword);
      mul_shift_byte1_in_a(gword) <= byte1_shift_in(gword) when start_shift = '1' else mul_byte1_in_a(gword);
      mul_shift_byte3_in_a(gword) <= byte3_shift_in(gword) when start_shift = '1' else mul_byte3_in_a(gword);
      mul_shift_word0_in_b(gword) <= mul_word0_in_b(gword);
      mul_shift_half1_in_b(gword) <= mul_half1_in_b(gword);
      mul_shift_byte1_in_b(gword) <= mul_byte1_in_b_posneg(gword);
      mul_shift_byte3_in_b(gword) <= mul_byte3_in_b_posneg(gword);
    end generate mul_in_no_reg_gen;

    use_high_low_reg : process (clk)
    begin  -- process use_high_low_reg
      if clk'event and clk = '1' then   -- rising clock edge
        rot_flag_shifter(gword*4+0)(0) <= data_b(gword*4+0).flag;
        rot_flag_shifter(gword*4+1)(0) <= data_b(gword*4+1).flag;
        rot_flag_shifter(gword*4+2)(0) <= data_b(gword*4+2).flag;
        rot_flag_shifter(gword*4+3)(0) <= data_b(gword*4+3).flag;

        rot_flag_shifter(gword*4+0)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+0)(MULTIPLIER_DELAY-1 downto 0);
        rot_flag_shifter(gword*4+1)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+1)(MULTIPLIER_DELAY-1 downto 0);
        rot_flag_shifter(gword*4+2)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+2)(MULTIPLIER_DELAY-1 downto 0);
        rot_flag_shifter(gword*4+3)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+3)(MULTIPLIER_DELAY-1 downto 0);
      end if;
    end process use_high_low_reg;

    word0_multiplier : hardware_mult
      generic map (
        WIDTH_A   => 34,
        WIDTH_B   => 33,
        WIDTH_OUT => 67,
        DELAY     => MULTIPLIER_DELAY-MULTIPLIER_INPUT_REG
        )
      port map (
        clk    => clk,
        dataa  => mul_shift_word0_in_a(gword),
        datab  => mul_shift_word0_in_b(gword),
        result => mul_word0_result(gword)
        );

    half1_multiplier : hardware_mult
      generic map (
        WIDTH_A   => 18,
        WIDTH_B   => 17,
        WIDTH_OUT => 35,
        DELAY     => MULTIPLIER_DELAY-MULTIPLIER_INPUT_REG
        )
      port map (
        clk    => clk,
        dataa  => mul_shift_half1_in_a(gword),
        datab  => mul_shift_half1_in_b(gword),
        result => mul_half1_result(gword)
        );

    byte1_multiplier : hardware_mult
      generic map (
        WIDTH_A   => 9,
        WIDTH_B   => 9,
        WIDTH_OUT => 18,
        DELAY     => MULTIPLIER_DELAY-MULTIPLIER_INPUT_REG
        )
      port map (
        clk    => clk,
        dataa  => mul_shift_byte1_in_a(gword),
        datab  => mul_shift_byte1_in_b(gword),
        result => mul_byte1_result(gword)
        );

    byte3_multiplier : hardware_mult
      generic map (
        WIDTH_A   => 9,
        WIDTH_B   => 9,
        WIDTH_OUT => 18,
        DELAY     => MULTIPLIER_DELAY-MULTIPLIER_INPUT_REG
        )
      port map (
        clk    => clk,
        dataa  => mul_shift_byte3_in_a(gword),
        datab  => mul_shift_byte3_in_b(gword),
        result => mul_byte3_result(gword)
        );


    mul_out_low(gword*4+0) <= mul_word0_result(gword)(7 downto 0);
    with end_size select
      mul_out_low(gword*4+1) <=
      mul_byte1_result(gword)(7 downto 0)  when OPSIZE_BYTE,
      mul_word0_result(gword)(15 downto 8) when others;
    with end_size select
      mul_out_low(gword*4+2) <=
      mul_word0_result(gword)(23 downto 16) when OPSIZE_WORD,
      mul_half1_result(gword)(7 downto 0)   when others;
    with end_size select
      mul_out_low(gword*4+3) <=
      mul_byte3_result(gword)(7 downto 0)   when OPSIZE_BYTE,
      mul_half1_result(gword)(15 downto 8)  when OPSIZE_HALF,
      mul_word0_result(gword)(31 downto 24) when others;

    mul_word0_oflow(gword) <= '1' when (mul_word0_result(gword)(63 downto 32) /= std_logic_vector(to_signed(0, 32)) and
                                        mul_word0_result(gword)(63 downto 32) /= std_logic_vector(to_signed(-1, 32)))
                              else '0';
    mul_half0_oflow(gword) <= '1' when (mul_word0_result(gword)(31 downto 16) /= std_logic_vector(to_signed(0, 16)) and
                                        mul_word0_result(gword)(31 downto 16) /= std_logic_vector(to_signed(-1, 16)))
                              else '0';
    mul_half1_oflow(gword) <= '1' when (mul_half1_result(gword)(31 downto 16) /= std_logic_vector(to_signed(0, 16)) and
                                        mul_half1_result(gword)(31 downto 16) /= std_logic_vector(to_signed(-1, 16)))
                              else '0';
    mul_byte0_oflow(gword) <= '1' when (mul_word0_result(gword)(15 downto 8) /= std_logic_vector(to_signed(0, 8)) and
                                        mul_word0_result(gword)(15 downto 8) /= std_logic_vector(to_signed(-1, 8)))
                              else '0';
    mul_byte1_oflow(gword) <= '1' when (mul_byte1_result(gword)(15 downto 8) /= std_logic_vector(to_signed(0, 8)) and
                                        mul_byte1_result(gword)(15 downto 8) /= std_logic_vector(to_signed(-1, 8)))
                              else '0';
    mul_byte2_oflow(gword) <= '1' when (mul_half1_result(gword)(15 downto 8) /= std_logic_vector(to_signed(0, 8)) and
                                        mul_half1_result(gword)(15 downto 8) /= std_logic_vector(to_signed(-1, 8)))
                              else '0';
    mul_byte3_oflow(gword) <= '1' when (mul_byte3_result(gword)(15 downto 8) /= std_logic_vector(to_signed(0, 8)) and
                                        mul_byte3_result(gword)(15 downto 8) /= std_logic_vector(to_signed(-1, 8)))
                              else '0';

    with end_size select
      mul_out_high(gword*4+0) <=
      mul_word0_result(gword)(15 downto 8)  when OPSIZE_BYTE,
      mul_word0_result(gword)(23 downto 16) when OPSIZE_HALF,
      mul_word0_result(gword)(39 downto 32) when others;
    with end_size select
      mul_out_high(gword*4+1) <=
      mul_byte1_result(gword)(15 downto 8)  when OPSIZE_BYTE,
      mul_word0_result(gword)(31 downto 24) when OPSIZE_HALF,
      mul_word0_result(gword)(47 downto 40) when others;
    with end_size select
      mul_out_high(gword*4+2) <=
      mul_half1_result(gword)(15 downto 8)  when OPSIZE_BYTE,
      mul_half1_result(gword)(23 downto 16) when OPSIZE_HALF,
      mul_word0_result(gword)(55 downto 48) when others;
    with end_size select
      mul_out_high(gword*4+3) <=
      mul_byte3_result(gword)(15 downto 8)  when OPSIZE_BYTE,
      mul_half1_result(gword)(31 downto 24) when OPSIZE_HALF,
      mul_word0_result(gword)(63 downto 56) when others;

    mul_word0_round(gword) <= mul_word0_result(gword)(31);
    mul_half0_round(gword) <= mul_word0_result(gword)(15);
    mul_half1_round(gword) <= mul_half1_result(gword)(15);
    mul_byte0_round(gword) <= mul_word0_result(gword)(7);
    mul_byte1_round(gword) <= mul_byte1_result(gword)(7);
    mul_byte2_round(gword) <= mul_half1_result(gword)(7);
    mul_byte3_round(gword) <= mul_byte3_result(gword)(7);

    with end_size select
      mul_out_low_flag(gword*4+0) <=
      mul_word0_oflow(gword) when OPSIZE_WORD,
      mul_half0_oflow(gword) when OPSIZE_HALF,
      mul_byte0_oflow(gword) when others;
    with end_size select
      mul_out_low_flag(gword*4+1) <=
      mul_word0_oflow(gword) when OPSIZE_WORD,
      mul_half0_oflow(gword) when OPSIZE_HALF,
      mul_byte1_oflow(gword) when others;
    with end_size select
      mul_out_low_flag(gword*4+2) <=
      mul_word0_oflow(gword) when OPSIZE_WORD,
      mul_half1_oflow(gword) when OPSIZE_HALF,
      mul_byte2_oflow(gword) when others;
    with end_size select
      mul_out_low_flag(gword*4+3) <=
      mul_word0_oflow(gword) when OPSIZE_WORD,
      mul_half1_oflow(gword) when OPSIZE_HALF,
      mul_byte3_oflow(gword) when others;
    
    with end_size select
      mul_out_high_flag(gword*4+0) <=
      mul_word0_round(gword) when OPSIZE_WORD,
      mul_half0_round(gword) when OPSIZE_HALF,
      mul_byte0_round(gword) when others;
    with end_size select
      mul_out_high_flag(gword*4+1) <=
      mul_word0_round(gword) when OPSIZE_WORD,
      mul_half0_round(gword) when OPSIZE_HALF,
      mul_byte1_round(gword) when others;
    with end_size select
      mul_out_high_flag(gword*4+2) <=
      mul_word0_round(gword) when OPSIZE_WORD,
      mul_half1_round(gword) when OPSIZE_HALF,
      mul_byte2_round(gword) when others;
    with end_size select
      mul_out_high_flag(gword*4+3) <=
      mul_word0_round(gword) when OPSIZE_WORD,
      mul_half1_round(gword) when OPSIZE_HALF,
      mul_byte3_round(gword) when others;

    mul_out_fxp_word0(gword)(31) <= mul_word0_result(gword)(mul_word0_result(gword)'left) when end_signed = '1' else
                                    mul_word0_result(gword)(MULFXP_WORD_FRACTION_BITS+31);
    mul_out_fxp_word0(gword)(30 downto 0) <=
      mul_word0_result(gword)(MULFXP_WORD_FRACTION_BITS+30 downto MULFXP_WORD_FRACTION_BITS);

    mul_out_fxp_half0(gword)(15) <= mul_word0_result(gword)(mul_word0_result(gword)'left) when end_signed = '1' else
                                    mul_word0_result(gword)(MULFXP_HALF_FRACTION_BITS+15);
    mul_out_fxp_half0(gword)(14 downto 0) <=
      mul_word0_result(gword)(MULFXP_HALF_FRACTION_BITS+14 downto MULFXP_HALF_FRACTION_BITS);

    mul_out_fxp_byte0(gword)(7) <= mul_word0_result(gword)(mul_word0_result(gword)'left) when end_signed = '1' else
                                   mul_word0_result(gword)(MULFXP_BYTE_FRACTION_BITS+7);
    mul_out_fxp_byte0(gword)(6 downto 0) <=
      mul_word0_result(gword)(MULFXP_BYTE_FRACTION_BITS+6 downto MULFXP_BYTE_FRACTION_BITS);

    mul_out_fxp_half1(gword)(15) <= mul_half1_result(gword)(mul_half1_result(gword)'left) when end_signed = '1' else
                                    mul_half1_result(gword)(MULFXP_HALF_FRACTION_BITS+15);
    mul_out_fxp_half1(gword)(14 downto 0) <=
      mul_half1_result(gword)(MULFXP_HALF_FRACTION_BITS+14 downto MULFXP_HALF_FRACTION_BITS);

    mul_out_fxp_byte2(gword)(7) <= mul_half1_result(gword)(mul_half1_result(gword)'left) when end_signed = '1' else
                                   mul_half1_result(gword)(MULFXP_BYTE_FRACTION_BITS+7);
    mul_out_fxp_byte2(gword)(6 downto 0) <=
      mul_half1_result(gword)(MULFXP_BYTE_FRACTION_BITS+6 downto MULFXP_BYTE_FRACTION_BITS);

    mul_out_fxp_byte1(gword)(7) <= mul_byte1_result(gword)(mul_byte1_result(gword)'left) when end_signed = '1' else
                                   mul_byte1_result(gword)(MULFXP_BYTE_FRACTION_BITS+7);
    mul_out_fxp_byte1(gword)(6 downto 0) <=
      mul_byte1_result(gword)(MULFXP_BYTE_FRACTION_BITS+6 downto MULFXP_BYTE_FRACTION_BITS);

    mul_out_fxp_byte3(gword)(7) <= mul_byte3_result(gword)(mul_byte3_result(gword)'left) when end_signed = '1' else
                                   mul_byte3_result(gword)(MULFXP_BYTE_FRACTION_BITS+7);
    mul_out_fxp_byte3(gword)(6 downto 0) <=
      mul_byte3_result(gword)(MULFXP_BYTE_FRACTION_BITS+6 downto MULFXP_BYTE_FRACTION_BITS);

    fxp_word0_pos_of(gword) <=
      '1' when (mul_word0_result(gword)(64 downto MULFXP_WORD_FRACTION_BITS+32) /=
                replicate_bit('0', 65-(MULFXP_WORD_FRACTION_BITS+32)))
      else '0';
    fxp_word0_neg_of(gword) <=
      '1' when (mul_word0_result(gword)(64 downto MULFXP_WORD_FRACTION_BITS+32) /=
                replicate_bit('1', 65-(MULFXP_WORD_FRACTION_BITS+32)))
      else '0';
    fxp_word0_of(gword) <=
      fxp_word0_neg_of(gword) when end_signed = '1' and mul_word0_result(gword)(MULFXP_WORD_FRACTION_BITS+31) = '1'
      else fxp_word0_pos_of(gword);
    fxp_half0_pos_of(gword) <=
      '1' when (mul_word0_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('0', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half0_neg_of(gword) <=
      '1' when (mul_word0_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('1', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half0_of(gword) <=
      fxp_half0_neg_of(gword) when end_signed = '1' and mul_word0_result(gword)(MULFXP_HALF_FRACTION_BITS+15) = '1'
      else fxp_half0_pos_of(gword);
    fxp_byte0_pos_of(gword) <=
      '1' when (mul_word0_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('0', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte0_neg_of(gword) <=
      '1' when (mul_word0_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('1', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte0_of(gword) <=
      fxp_byte0_neg_of(gword) when end_signed = '1' and mul_word0_result(gword)(MULFXP_BYTE_FRACTION_BITS+7) = '1'
      else fxp_byte0_pos_of(gword);
    fxp_half1_pos_of(gword) <=
      '1' when (mul_half1_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('0', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half1_neg_of(gword) <=
      '1' when (mul_half1_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('1', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half1_of(gword) <=
      fxp_half1_neg_of(gword) when end_signed = '1' and mul_half1_result(gword)(MULFXP_HALF_FRACTION_BITS+15) = '1'
      else fxp_half1_pos_of(gword);
    fxp_byte2_pos_of(gword) <=
      '1' when (mul_half1_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('0', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte2_neg_of(gword) <=
      '1' when (mul_half1_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('1', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte2_of(gword) <=
      fxp_byte2_neg_of(gword) when end_signed = '1' and mul_half1_result(gword)(MULFXP_BYTE_FRACTION_BITS+7) = '1'
      else fxp_byte2_pos_of(gword);
    fxp_byte1_pos_of(gword) <=
      '1' when (mul_byte1_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('0', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte1_neg_of(gword) <=
      '1' when (mul_byte1_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('1', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte1_of(gword) <=
      fxp_byte1_neg_of(gword) when end_signed = '1' and mul_byte1_result(gword)(MULFXP_BYTE_FRACTION_BITS+7) = '1'
      else fxp_byte1_pos_of(gword);
    fxp_byte3_pos_of(gword) <=
      '1' when (mul_byte3_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('0', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte3_neg_of(gword) <=
      '1' when (mul_byte3_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('1', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte3_of(gword) <=
      fxp_byte3_neg_of(gword) when end_signed = '1' and mul_byte3_result(gword)(MULFXP_BYTE_FRACTION_BITS+7) = '1'
      else fxp_byte3_pos_of(gword);
    
    with end_size select
      mul_out_fxp(gword*4+0) <=
      mul_out_fxp_byte0(gword)(7 downto 0) when OPSIZE_BYTE,
      mul_out_fxp_half0(gword)(7 downto 0) when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(7 downto 0) when others;
    with end_size select
      mul_out_fxp(gword*4+1) <=
      mul_out_fxp_byte1(gword)(7 downto 0)  when OPSIZE_BYTE,
      mul_out_fxp_half0(gword)(15 downto 8) when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(15 downto 8) when others;
    with end_size select
      mul_out_fxp(gword*4+2) <=
      mul_out_fxp_byte2(gword)(7 downto 0)   when OPSIZE_BYTE,
      mul_out_fxp_half1(gword)(7 downto 0)   when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(23 downto 16) when others;
    with end_size select
      mul_out_fxp(gword*4+3) <=
      mul_out_fxp_byte3(gword)(7 downto 0)   when OPSIZE_BYTE,
      mul_out_fxp_half1(gword)(15 downto 8)  when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(31 downto 24) when others;

    with end_size select
      fxp_mul_flag(gword*4+0) <=
      fxp_word0_of(gword) when OPSIZE_WORD,
      fxp_half0_of(gword) when OPSIZE_HALF,
      fxp_byte0_of(gword) when others;
    with end_size select
      fxp_mul_flag(gword*4+1) <=
      fxp_word0_of(gword) when OPSIZE_WORD,
      fxp_half0_of(gword) when OPSIZE_HALF,
      fxp_byte1_of(gword) when others;
    with end_size select
      fxp_mul_flag(gword*4+2) <=
      fxp_word0_of(gword) when OPSIZE_WORD,
      fxp_half1_of(gword) when OPSIZE_HALF,
      fxp_byte2_of(gword) when others;
    with end_size select
      fxp_mul_flag(gword*4+3) <=
      fxp_word0_of(gword) when OPSIZE_WORD,
      fxp_half1_of(gword) when OPSIZE_HALF,
      fxp_byte3_of(gword) when others;

    mul_flag_reg : process (clk)
    begin  -- process mul_flag_reg
      if clk'event and clk = '1' then   -- rising clock edge
        mul_out_low_flag_reg(gword*4+3 downto gword*4)  <= mul_out_low_flag(gword*4+3 downto gword*4);
        mul_out_high_flag_reg(gword*4+3 downto gword*4) <= mul_out_high_flag(gword*4+3 downto gword*4);
        fxp_mul_flag_reg(gword*4+3 downto gword*4)      <= fxp_mul_flag(gword*4+3 downto gword*4);
      end if;
    end process mul_flag_reg;

    with end_mul_type select
      mul_out(gword*4+0) <=
      mul_out_high(gword*4+0)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+0)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+0)                            when MULFXP,
      mul_out_high(gword*4+0) or mul_out_low(gword*4+0) when others;
    with end_mul_type select
      mul_out(gword*4+1) <=
      mul_out_high(gword*4+1)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+1)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+1)                            when MULFXP,
      mul_out_high(gword*4+1) or mul_out_low(gword*4+1) when others;
    with end_mul_type select
      mul_out(gword*4+2) <=
      mul_out_high(gword*4+2)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+2)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+2)                            when MULFXP,
      mul_out_high(gword*4+2) or mul_out_low(gword*4+2) when others;
    with end_mul_type select
      mul_out(gword*4+3) <=
      mul_out_high(gword*4+3)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+3)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+3)                            when MULFXP,
      mul_out_high(gword*4+3) or mul_out_low(gword*4+3) when others;
    mul_data_reg : process (clk)
    begin  -- process mul_data_reg
      if clk'event and clk = '1' then   -- rising clock edge
        multiplier_out(gword*4+0).data <= mul_out(gword*4+0);
        multiplier_out(gword*4+1).data <= mul_out(gword*4+1);
        multiplier_out(gword*4+2).data <= mul_out(gword*4+2);
        multiplier_out(gword*4+3).data <= mul_out(gword*4+3);
      end if;
    end process mul_data_reg;

    with end_mul_type_reg select
      multiplier_out(gword*4+0).flag <=
      mul_out_high_flag_reg(gword*4+0)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+0)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+0)                   when MULFXP,
      rot_flag_shifter(gword*4+0)(MULTIPLIER_DELAY) when others;
    with end_mul_type_reg select
      multiplier_out(gword*4+1).flag <=
      mul_out_high_flag_reg(gword*4+1)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+1)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+1)                   when MULFXP,
      rot_flag_shifter(gword*4+1)(MULTIPLIER_DELAY) when others;
    with end_mul_type_reg select
      multiplier_out(gword*4+2).flag <=
      mul_out_high_flag_reg(gword*4+2)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+2)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+2)                   when MULFXP,
      rot_flag_shifter(gword*4+2)(MULTIPLIER_DELAY) when others;
    with end_mul_type_reg select
      multiplier_out(gword*4+3).flag <=
      mul_out_high_flag_reg(gword*4+3)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+3)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+3)                   when MULFXP,
      rot_flag_shifter(gword*4+3)(MULTIPLIER_DELAY) when others;
  end generate mult_word_gen;

end architecture byte;


architecture half of mul_unit is
  constant MULTIPLIER_DELAY : positive := CFG_SEL(CFG_FAM).MULTIPLIER_DELAY;

  signal word0_a : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_a : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_b : half17_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_word0_in_a : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_word0_in_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_half1_in_a : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_half1_in_b : half17_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_word0_result : dubl67_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_half1_result : word35_scratchpad_data(VECTOR_LANES-1 downto 0);

  type shamt5_scratchpad_data is array (natural range <>) of std_logic_vector(4 downto 0);
  type shamt4_scratchpad_data is array (natural range <>) of std_logic_vector(3 downto 0);

  signal word0_shamt                   : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_shamt_of_h              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word0_shamt_of_b              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word0_shamt_of                : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word0_shamt_trunc             : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shamt                   : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shamt_of_h              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal half1_shamt_of_b              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal half1_shamt_of                : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal half1_shamt_trunc             : shamt4_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shiftl_int              : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal word0_shift_in      : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_shamt_rom_out : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shift_in      : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half1_shamt_rom_out : half18_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_shift_word0_in_a : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_word0_in_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_half1_in_a : half18_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_half1_in_b : half17_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal start_rot                   : std_logic;
  signal start_shift                 : std_logic;
  signal start_shiftl                : std_logic;
  signal start_signed                : std_logic;
  signal start_m1_max_size           : opsize;
  signal start_size                  : opsize;
  signal end_signed                  : std_logic;
  signal end_size                    : opsize;
  signal end_size_word               : std_logic;
  signal start_byte                  : std_logic;
  signal start_word                  : std_logic;
  attribute dont_merge of start_word : signal is true;
  signal start_half                  : std_logic;
  attribute dont_merge of start_half : signal is true;
  signal start_mulhi                 : std_logic;

  type   mul_flag_shifter_type is array ((VECTOR_LANES*4)-1 downto 0) of std_logic_vector(MULTIPLIER_DELAY downto 0);
  signal rot_flag_shifter : mul_flag_shifter_type;

  signal mul_word0_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half0_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half1_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte0_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte2_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal mul_word0_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half0_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half1_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte0_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte2_round : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal fxp_word0_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half0_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half1_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte0_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte2_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_word0_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half0_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half1_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte0_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte2_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_word0_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half0_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half1_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte0_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte2_of     : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal mul_out_low  : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_high : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_fxp  : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal mul_out      : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal mul_out_fxp_word0 : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_half0 : half16_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_half1 : half16_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_byte0 : byte8_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_byte2 : byte8_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_out_low_flag      : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_low_flag_reg  : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_high_flag     : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_high_flag_reg : std_logic_vector((VECTOR_LANES*4)-1 downto 0);

  signal fxp_mul_flag          : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal fxp_mul_flag_reg      : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal end_fxp_dn1           : std_logic;
  type   mul_type is (MULHI_SHIFTR, MULLO_SHIFTL, MULFXP, ROTLR);
  signal end_mul_type_dn1      : mul_type;
  signal end_mul_type          : mul_type;
  signal end_mul_type_reg      : mul_type;
  signal end_rot_not_mul_dn1   : std_logic;
  signal end_mulhi_shiftr_dn1  : std_logic;
  signal end_rot_mulhi_fxp_dn1 : std_logic_vector(2 downto 0);
begin
  -- Check that parameters are valid
  assert MULTIPLIER_INPUT_REG >= 0
    and MULTIPLIER_INPUT_REG <= 1
    report "MULTIPLIER_INPUT_REG ("
    & integer'image(MULTIPLIER_INPUT_REG) &
    ") must be either 0 or 1"
    severity failure;

  start_m1_max_size <= instruction_pipeline(STAGE_MUL_START-1).in_size when
                       (unsigned(instruction_pipeline(STAGE_MUL_START-1).in_size) >
                        unsigned(instruction_pipeline(STAGE_MUL_START-1).out_size)) else
                       instruction_pipeline(STAGE_MUL_START-1).out_size;
  -- purpose: register separately from instruction pipeline, for timing
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      start_shiftl <= not instruction_pipeline(STAGE_MUL_START-1).op(0);
      start_word   <= start_m1_max_size(1);
      start_half   <= start_m1_max_size(0);
      start_shift  <= op_is_shift(instruction_pipeline(STAGE_MUL_START-1).op);
      start_rot    <= instruction_pipeline(STAGE_MUL_START-1).op(1);
      if op_is_shift(instruction_pipeline(STAGE_MUL_START-1).op) = '0' then
        start_signed <= instruction_pipeline(STAGE_MUL_START-1).signedness;
      else
        start_signed <= (instruction_pipeline(STAGE_MUL_START-1).signedness and
                         (not instruction_pipeline(STAGE_MUL_START-1).op(1)));
      end if;
      start_size  <= start_m1_max_size;
      start_mulhi <= instruction_pipeline(STAGE_MUL_START-1).op(0);
      start_byte  <= (not start_m1_max_size(1)) and (not start_m1_max_size(0));

      end_mul_type <= end_mul_type_dn1;
      if op_is_shift(instruction_pipeline(STAGE_MUL_END-1).op) = '0' then
        end_signed <= instruction_pipeline(STAGE_MUL_END-1).signedness;
      else
        end_signed <= (instruction_pipeline(STAGE_MUL_END-1).signedness and
                       (not instruction_pipeline(STAGE_MUL_END-1).op(1)));
      end if;
      if (unsigned(instruction_pipeline(STAGE_MUL_END-1).in_size) >
          unsigned(instruction_pipeline(STAGE_MUL_END-1).out_size)) then
        end_size <= instruction_pipeline(STAGE_MUL_END-1).in_size;
      else
        end_size <= instruction_pipeline(STAGE_MUL_END-1).out_size;
      end if;
    end if;
  end process;
  end_fxp_dn1 <= (not op_is_shift(instruction_pipeline(STAGE_MUL_END-1).op)) and
                 instruction_pipeline(STAGE_MUL_END-1).op(1);
  end_rot_not_mul_dn1 <= op_is_shift(instruction_pipeline(STAGE_MUL_END-1).op) and
                         instruction_pipeline(STAGE_MUL_END-1).op(1);
  end_mulhi_shiftr_dn1  <= instruction_pipeline(STAGE_MUL_END-1).op(0);
  end_rot_mulhi_fxp_dn1 <= end_rot_not_mul_dn1 & end_mulhi_shiftr_dn1 & end_fxp_dn1;
  with end_rot_mulhi_fxp_dn1 select
    end_mul_type_dn1 <=
    MULLO_SHIFTL when "000",
    MULHI_SHIFTR when "010",
    MULFXP       when "001",
    MULFXP       when "011",
    ROTLR        when others;

  end_size_word <= end_size(1);

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      end_mul_type_reg <= end_mul_type;
    end if;
  end process;

  mult_word_gen : for gword in VECTOR_LANES-1 downto 0 generate
    word0_a(gword) <= "00" & scratchpad_data_to_word32_scratchpad_data(data_a)(gword);
    with start_size select
      mul_word0_in_a(gword) <=
      s_z_extend(31, start_signed, word0_a(gword)) when OPSIZE_WORD,
      s_z_extend(15, start_signed, word0_a(gword)) when OPSIZE_HALF,
      s_z_extend(7, start_signed, word0_a(gword))  when others;
    word0_b(gword) <= '0' & scratchpad_data_to_word32_scratchpad_data(data_b)(gword);
    with start_size select
      mul_word0_in_b(gword) <=
      s_z_extend(31, start_signed, word0_b(gword)) when OPSIZE_WORD,
      s_z_extend(15, start_signed, word0_b(gword)) when OPSIZE_HALF,
      s_z_extend(7, start_signed, word0_b(gword))  when others;

    half1_a(gword) <= "00" & scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(31 downto 16);
    with start_size select
      mul_half1_in_a(gword) <=
      s_z_extend(7, start_signed, half1_a(gword))  when OPSIZE_BYTE,
      s_z_extend(15, start_signed, half1_a(gword)) when others;
    half1_b(gword) <= '0' & scratchpad_data_to_word32_scratchpad_data(data_b)(gword)(31 downto 16);
    with start_size select
      mul_half1_in_b(gword) <=
      s_z_extend(7, start_signed, half1_b(gword))  when OPSIZE_BYTE,
      s_z_extend(15, start_signed, half1_b(gword)) when others;

    word0_shamt(gword)      <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(4 downto 0);
    word0_shamt_of_h(gword) <= (not start_rot) and word0_shamt(gword)(4) and
                               start_half;
    word0_shamt_of_b(gword) <= (not start_rot) and (word0_shamt(gword)(4) or word0_shamt(gword)(3)) and
                               start_byte;
    word0_shamt_of(gword)       <= word0_shamt_of_h(gword) or word0_shamt_of_b(gword);
    word0_shamt_trunc(gword)(4) <= word0_shamt(gword)(4) when start_word = '1' else
                                   (not start_shiftl) or word0_shamt_of_h(gword);
    word0_shamt_trunc(gword)(3) <= word0_shamt(gword)(3) and (not word0_shamt_of_h(gword)) when start_byte = '0' else
                                   (not start_shiftl) or word0_shamt_of_b(gword);
    word0_shamt_trunc(gword)(2 downto 0) <= word0_shamt(gword)(2 downto 0) when word0_shamt_of(gword) = '0' else
                                            "000";

    half1_shamt(gword)      <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(20 downto 16);
    half1_shamt_of_h(gword) <= (not start_rot) and half1_shamt(gword)(4) and (not start_byte);
    half1_shamt_of_b(gword) <= (not start_rot) and (half1_shamt(gword)(4) or half1_shamt(gword)(3)) and
                               start_byte;
    half1_shamt_of(gword)       <= half1_shamt_of_h(gword) or half1_shamt_of_b(gword);
    half1_shamt_trunc(gword)(3) <= half1_shamt(gword)(3) and (not half1_shamt_of_h(gword)) when start_byte = '0' else
                                   (not start_shiftl) or half1_shamt_of_b(gword);
    half1_shamt_trunc(gword)(2 downto 0) <= half1_shamt(gword)(2 downto 0) when half1_shamt_of(gword) = '0' else
                                            "000";
    half1_shiftl_int(gword) <= start_shiftl when start_byte = '1' else
                               start_shiftl and (not half1_shamt_of(gword));

    word0_shift_in(gword)(33) <= word0_shamt_rom_out(gword)(33);
    word0_shift_in(gword)(32) <= '0' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                 word0_shamt_rom_out(gword)(32);
    word0_shift_in(gword)(31 downto 17) <= word0_shamt_rom_out(gword)(31 downto 17);
    word0_shift_in(gword)(16)           <= '0' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                           word0_shamt_rom_out(gword)(16);
    word0_shift_in(gword)(15 downto 9) <= word0_shamt_rom_out(gword)(15 downto 9);
    word0_shift_in(gword)(8)           <= '0' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                          word0_shamt_rom_out(gword)(8);
    word0_shift_in(gword)(7 downto 1) <= word0_shamt_rom_out(gword)(7 downto 1);
    word0_shift_in(gword)(0)          <= '1' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                         word0_shamt_rom_out(gword)(0);

    half1_shift_in(gword)(17) <= half1_shamt_rom_out(gword)(17);
    half1_shift_in(gword)(16) <= '0' when half1_shamt_of(gword) = '1' and start_shiftl = '0' else
                                 half1_shamt_rom_out(gword)(16);
    half1_shift_in(gword)(15 downto 9) <= half1_shamt_rom_out(gword)(15 downto 9);
    half1_shift_in(gword)(8)           <= '0' when half1_shamt_of(gword) = '1' and start_shiftl = '0' else
                                          half1_shamt_rom_out(gword)(8);
    half1_shift_in(gword)(7 downto 1) <= half1_shamt_rom_out(gword)(7 downto 1);
    half1_shift_in(gword)(0)          <= '1' when half1_shamt_of(gword) = '1' and start_shiftl = '0' else
                                         half1_shamt_rom_out(gword)(0);

    word0_shamt_rom : word_shamt_rom
      port map (
        shamt_trunc        => word0_shamt_trunc(gword),
        shiftl             => start_shiftl,
        word_shamt_rom_out => word0_shamt_rom_out(gword)
        );

    half1_shamt_rom : half_shamt_rom
      port map (
        shamt_trunc        => half1_shamt_trunc(gword),
        shiftl             => half1_shiftl_int(gword),
        half_shamt_rom_out => half1_shamt_rom_out(gword)
        );

    mul_in_reg_gen : if MULTIPLIER_INPUT_REG = 1 generate
      mul_in_reg : process (clk)
      begin  -- process mul_in_reg
        if clk'event and clk = '1' then  -- rising clock edge
          if start_shift = '1' then
            mul_shift_word0_in_a(gword) <= word0_shift_in(gword);
            mul_shift_half1_in_a(gword) <= half1_shift_in(gword);
          else
            mul_shift_word0_in_a(gword) <= mul_word0_in_a(gword);
            mul_shift_half1_in_a(gword) <= mul_half1_in_a(gword);
          end if;
          mul_shift_word0_in_b(gword) <= mul_word0_in_b(gword);
          mul_shift_half1_in_b(gword) <= mul_half1_in_b(gword);
        end if;
      end process mul_in_reg;
    end generate mul_in_reg_gen;
    mul_in_no_reg_gen : if MULTIPLIER_INPUT_REG = 0 generate
      mul_shift_word0_in_a(gword) <= word0_shift_in(gword) when start_shift = '1' else mul_word0_in_a(gword);
      mul_shift_half1_in_a(gword) <= half1_shift_in(gword) when start_shift = '1' else mul_half1_in_a(gword);
      mul_shift_word0_in_b(gword) <= mul_word0_in_b(gword);
      mul_shift_half1_in_b(gword) <= mul_half1_in_b(gword);
    end generate mul_in_no_reg_gen;

    use_high_low_reg : process (clk)
    begin  -- process use_high_low_reg
      if clk'event and clk = '1' then   -- rising clock edge
        rot_flag_shifter(gword*4+0)(0) <= data_b(gword*4+0).flag;
        rot_flag_shifter(gword*4+1)(0) <= data_b(gword*4+1).flag;
        rot_flag_shifter(gword*4+2)(0) <= data_b(gword*4+2).flag;
        rot_flag_shifter(gword*4+3)(0) <= data_b(gword*4+3).flag;

        rot_flag_shifter(gword*4+0)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+0)(MULTIPLIER_DELAY-1 downto 0);
        rot_flag_shifter(gword*4+1)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+1)(MULTIPLIER_DELAY-1 downto 0);
        rot_flag_shifter(gword*4+2)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+2)(MULTIPLIER_DELAY-1 downto 0);
        rot_flag_shifter(gword*4+3)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+3)(MULTIPLIER_DELAY-1 downto 0);
      end if;
    end process use_high_low_reg;

    word0_multiplier : hardware_mult
      generic map (
        WIDTH_A   => 34,
        WIDTH_B   => 33,
        WIDTH_OUT => 67,
        DELAY     => MULTIPLIER_DELAY-MULTIPLIER_INPUT_REG
        )
      port map (
        clk    => clk,
        dataa  => mul_shift_word0_in_a(gword),
        datab  => mul_shift_word0_in_b(gword),
        result => mul_word0_result(gword)
        );

    half1_multiplier : hardware_mult
      generic map (
        WIDTH_A   => 18,
        WIDTH_B   => 17,
        WIDTH_OUT => 35,
        DELAY     => MULTIPLIER_DELAY-MULTIPLIER_INPUT_REG
        )
      port map (
        clk    => clk,
        dataa  => mul_shift_half1_in_a(gword),
        datab  => mul_shift_half1_in_b(gword),
        result => mul_half1_result(gword)
        );

    mul_out_low(gword*4+0) <= mul_word0_result(gword)(7 downto 0);
    mul_out_low(gword*4+1) <= mul_word0_result(gword)(15 downto 8);
    with end_size_word select
      mul_out_low(gword*4+2) <=
      mul_word0_result(gword)(23 downto 16) when '1',
      mul_half1_result(gword)(7 downto 0)   when others;
    with end_size_word select
      mul_out_low(gword*4+3) <=
      mul_half1_result(gword)(15 downto 8)  when '0',
      mul_word0_result(gword)(31 downto 24) when others;

    mul_word0_oflow(gword) <= '1' when (mul_word0_result(gword)(63 downto 32) /= std_logic_vector(to_signed(0, 32)) and
                                        mul_word0_result(gword)(63 downto 32) /= std_logic_vector(to_signed(-1, 32)))
                              else '0';
    mul_half0_oflow(gword) <= '1' when (mul_word0_result(gword)(31 downto 16) /= std_logic_vector(to_signed(0, 16)) and
                                        mul_word0_result(gword)(31 downto 16) /= std_logic_vector(to_signed(-1, 16)))
                              else '0';
    mul_half1_oflow(gword) <= '1' when (mul_half1_result(gword)(31 downto 16) /= std_logic_vector(to_signed(0, 16)) and
                                        mul_half1_result(gword)(31 downto 16) /= std_logic_vector(to_signed(-1, 16)))
                              else '0';
    mul_byte0_oflow(gword) <= '1' when (mul_word0_result(gword)(15 downto 8) /= std_logic_vector(to_signed(0, 8)) and
                                        mul_word0_result(gword)(15 downto 8) /= std_logic_vector(to_signed(-1, 8)))
                              else '0';
    mul_byte2_oflow(gword) <= '1' when (mul_half1_result(gword)(15 downto 8) /= std_logic_vector(to_signed(0, 8)) and
                                        mul_half1_result(gword)(15 downto 8) /= std_logic_vector(to_signed(-1, 8)))
                              else '0';

    with end_size select
      mul_out_high(gword*4+0) <=
      mul_word0_result(gword)(15 downto 8)  when OPSIZE_BYTE,
      mul_word0_result(gword)(23 downto 16) when OPSIZE_HALF,
      mul_word0_result(gword)(39 downto 32) when others;
    with end_size_word select
      mul_out_high(gword*4+1) <=
      mul_word0_result(gword)(31 downto 24) when '0',
      mul_word0_result(gword)(47 downto 40) when others;
    with end_size select
      mul_out_high(gword*4+2) <=
      mul_half1_result(gword)(15 downto 8)  when OPSIZE_BYTE,
      mul_half1_result(gword)(23 downto 16) when OPSIZE_HALF,
      mul_word0_result(gword)(55 downto 48) when others;
    with end_size_word select
      mul_out_high(gword*4+3) <=
      mul_half1_result(gword)(31 downto 24) when '0',
      mul_word0_result(gword)(63 downto 56) when others;

    mul_word0_round(gword) <= mul_word0_result(gword)(31);
    mul_half0_round(gword) <= mul_word0_result(gword)(15);
    mul_half1_round(gword) <= mul_half1_result(gword)(15);
    mul_byte0_round(gword) <= mul_word0_result(gword)(7);
    mul_byte2_round(gword) <= mul_half1_result(gword)(7);

    with end_size select
      mul_out_low_flag(gword*4+0) <=
      mul_word0_oflow(gword) when OPSIZE_WORD,
      mul_half0_oflow(gword) when OPSIZE_HALF,
      mul_byte0_oflow(gword) when others;
    mul_out_low_flag(gword*4+1) <= mul_out_low_flag(gword*4+0);
    with end_size select
      mul_out_low_flag(gword*4+2) <=
      mul_word0_oflow(gword) when OPSIZE_WORD,
      mul_half1_oflow(gword) when OPSIZE_HALF,
      mul_byte2_oflow(gword) when others;
    mul_out_low_flag(gword*4+3) <= mul_out_low_flag(gword*4+2);

    with end_size select
      mul_out_high_flag(gword*4+0) <=
      mul_word0_round(gword) when OPSIZE_WORD,
      mul_half0_round(gword) when OPSIZE_HALF,
      mul_byte0_round(gword) when others;
    mul_out_high_flag(gword*4+1) <= mul_out_high_flag(gword*4+0);
    with end_size select
      mul_out_high_flag(gword*4+2) <=
      mul_word0_round(gword) when OPSIZE_WORD,
      mul_half1_round(gword) when OPSIZE_HALF,
      mul_byte2_round(gword) when others;
    mul_out_high_flag(gword*4+3) <= mul_out_high_flag(gword*4+2);

    mul_out_fxp_word0(gword)(31) <= mul_word0_result(gword)(mul_word0_result(gword)'left) when end_signed = '1' else
                                    mul_word0_result(gword)(MULFXP_WORD_FRACTION_BITS+31);
    mul_out_fxp_word0(gword)(30 downto 0) <=
      mul_word0_result(gword)(MULFXP_WORD_FRACTION_BITS+30 downto MULFXP_WORD_FRACTION_BITS);

    mul_out_fxp_half0(gword)(15) <= mul_word0_result(gword)(mul_word0_result(gword)'left) when end_signed = '1' else
                                    mul_word0_result(gword)(MULFXP_HALF_FRACTION_BITS+15);
    mul_out_fxp_half0(gword)(14 downto 0) <=
      mul_word0_result(gword)(MULFXP_HALF_FRACTION_BITS+14 downto MULFXP_HALF_FRACTION_BITS);

    mul_out_fxp_byte0(gword)(7) <= mul_word0_result(gword)(mul_word0_result(gword)'left) when end_signed = '1' else
                                   mul_word0_result(gword)(MULFXP_BYTE_FRACTION_BITS+7);
    mul_out_fxp_byte0(gword)(6 downto 0) <=
      mul_word0_result(gword)(MULFXP_BYTE_FRACTION_BITS+6 downto MULFXP_BYTE_FRACTION_BITS);

    mul_out_fxp_half1(gword)(15) <= mul_half1_result(gword)(mul_half1_result(gword)'left) when end_signed = '1' else
                                    mul_half1_result(gword)(MULFXP_HALF_FRACTION_BITS+15);
    mul_out_fxp_half1(gword)(14 downto 0) <=
      mul_half1_result(gword)(MULFXP_HALF_FRACTION_BITS+14 downto MULFXP_HALF_FRACTION_BITS);

    mul_out_fxp_byte2(gword)(7) <= mul_half1_result(gword)(mul_half1_result(gword)'left) when end_signed = '1' else
                                   mul_half1_result(gword)(MULFXP_BYTE_FRACTION_BITS+7);
    mul_out_fxp_byte2(gword)(6 downto 0) <=
      mul_half1_result(gword)(MULFXP_BYTE_FRACTION_BITS+6 downto MULFXP_BYTE_FRACTION_BITS);

    fxp_word0_pos_of(gword) <=
      '1' when (mul_word0_result(gword)(64 downto MULFXP_WORD_FRACTION_BITS+32) /=
                replicate_bit('0', 65-(MULFXP_WORD_FRACTION_BITS+32)))
      else '0';
    fxp_word0_neg_of(gword) <=
      '1' when (mul_word0_result(gword)(64 downto MULFXP_WORD_FRACTION_BITS+32) /=
                replicate_bit('1', 65-(MULFXP_WORD_FRACTION_BITS+32)))
      else '0';
    fxp_word0_of(gword) <=
      fxp_word0_neg_of(gword) when end_signed = '1' and mul_word0_result(gword)(MULFXP_WORD_FRACTION_BITS+31) = '1'
      else fxp_word0_pos_of(gword);
    fxp_half0_pos_of(gword) <=
      '1' when (mul_word0_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('0', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half0_neg_of(gword) <=
      '1' when (mul_word0_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('1', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half0_of(gword) <=
      fxp_half0_neg_of(gword) when end_signed = '1' and mul_word0_result(gword)(MULFXP_HALF_FRACTION_BITS+15) = '1'
      else fxp_half0_pos_of(gword);
    fxp_byte0_pos_of(gword) <=
      '1' when (mul_word0_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('0', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte0_neg_of(gword) <=
      '1' when (mul_word0_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('1', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte0_of(gword) <=
      fxp_byte0_neg_of(gword) when end_signed = '1' and mul_word0_result(gword)(MULFXP_BYTE_FRACTION_BITS+7) = '1'
      else fxp_byte0_pos_of(gword);
    fxp_half1_pos_of(gword) <=
      '1' when (mul_half1_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('0', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half1_neg_of(gword) <=
      '1' when (mul_half1_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('1', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half1_of(gword) <=
      fxp_half1_neg_of(gword) when end_signed = '1' and mul_half1_result(gword)(MULFXP_HALF_FRACTION_BITS+15) = '1'
      else fxp_half1_pos_of(gword);
    fxp_byte2_pos_of(gword) <=
      '1' when (mul_half1_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('0', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte2_neg_of(gword) <=
      '1' when (mul_half1_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('1', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte2_of(gword) <=
      fxp_byte2_neg_of(gword) when end_signed = '1' and mul_half1_result(gword)(MULFXP_BYTE_FRACTION_BITS+7) = '1'
      else fxp_byte2_pos_of(gword);
    
    with end_size select
      mul_out_fxp(gword*4+0) <=
      mul_out_fxp_byte0(gword)(7 downto 0) when OPSIZE_BYTE,
      mul_out_fxp_half0(gword)(7 downto 0) when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(7 downto 0) when others;
    with end_size select
      mul_out_fxp(gword*4+1) <=
      mul_out_fxp_half0(gword)(15 downto 8) when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(15 downto 8) when others;
    with end_size select
      mul_out_fxp(gword*4+2) <=
      mul_out_fxp_byte2(gword)(7 downto 0)   when OPSIZE_BYTE,
      mul_out_fxp_half1(gword)(7 downto 0)   when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(23 downto 16) when others;
    with end_size select
      mul_out_fxp(gword*4+3) <=
      mul_out_fxp_half1(gword)(15 downto 8)  when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(31 downto 24) when others;

    with end_size select
      fxp_mul_flag(gword*4+0) <=
      fxp_word0_of(gword) when OPSIZE_WORD,
      fxp_half0_of(gword) when OPSIZE_HALF,
      fxp_byte0_of(gword) when others;
    fxp_mul_flag(gword*4+1) <= fxp_mul_flag(gword*4+0);
    with end_size select
      fxp_mul_flag(gword*4+2) <=
      fxp_word0_of(gword) when OPSIZE_WORD,
      fxp_half1_of(gword) when OPSIZE_HALF,
      fxp_byte2_of(gword) when others;
    fxp_mul_flag(gword*4+3) <= fxp_mul_flag(gword*4+2);

    mul_flag_reg : process (clk)
    begin  -- process mul_flag_reg
      if clk'event and clk = '1' then   -- rising clock edge
        mul_out_low_flag_reg(gword*4+3 downto gword*4)  <= mul_out_low_flag(gword*4+3 downto gword*4);
        mul_out_high_flag_reg(gword*4+3 downto gword*4) <= mul_out_high_flag(gword*4+3 downto gword*4);
        fxp_mul_flag_reg(gword*4+3 downto gword*4)      <= fxp_mul_flag(gword*4+3 downto gword*4);
      end if;
    end process mul_flag_reg;

    with end_mul_type select
      mul_out(gword*4+0) <=
      mul_out_high(gword*4+0)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+0)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+0)                            when MULFXP,
      mul_out_high(gword*4+0) or mul_out_low(gword*4+0) when others;
    with end_mul_type select
      mul_out(gword*4+1) <=
      mul_out_high(gword*4+1)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+1)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+1)                            when MULFXP,
      mul_out_high(gword*4+1) or mul_out_low(gword*4+1) when others;
    with end_mul_type select
      mul_out(gword*4+2) <=
      mul_out_high(gword*4+2)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+2)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+2)                            when MULFXP,
      mul_out_high(gword*4+2) or mul_out_low(gword*4+2) when others;
    with end_mul_type select
      mul_out(gword*4+3) <=
      mul_out_high(gword*4+3)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+3)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+3)                            when MULFXP,
      mul_out_high(gword*4+3) or mul_out_low(gword*4+3) when others;
    mul_data_reg : process (clk)
    begin  -- process mul_data_reg
      if clk'event and clk = '1' then   -- rising clock edge
        multiplier_out(gword*4+0).data <= mul_out(gword*4+0);
        multiplier_out(gword*4+1).data <= mul_out(gword*4+1);
        multiplier_out(gword*4+2).data <= mul_out(gword*4+2);
        multiplier_out(gword*4+3).data <= mul_out(gword*4+3);
      end if;
    end process mul_data_reg;

    with end_mul_type_reg select
      multiplier_out(gword*4+0).flag <=
      mul_out_high_flag_reg(gword*4+0)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+0)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+0)                   when MULFXP,
      rot_flag_shifter(gword*4+0)(MULTIPLIER_DELAY) when others;
    with end_mul_type_reg select
      multiplier_out(gword*4+1).flag <=
      mul_out_high_flag_reg(gword*4+1)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+1)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+1)                   when MULFXP,
      rot_flag_shifter(gword*4+1)(MULTIPLIER_DELAY) when others;
    with end_mul_type_reg select
      multiplier_out(gword*4+2).flag <=
      mul_out_high_flag_reg(gword*4+2)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+2)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+2)                   when MULFXP,
      rot_flag_shifter(gword*4+2)(MULTIPLIER_DELAY) when others;
    with end_mul_type_reg select
      multiplier_out(gword*4+3).flag <=
      mul_out_high_flag_reg(gword*4+3)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+3)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+3)                   when MULFXP,
      rot_flag_shifter(gword*4+3)(MULTIPLIER_DELAY) when others;
  end generate mult_word_gen;

end architecture half;


architecture word of mul_unit is
  constant MULTIPLIER_DELAY : positive := CFG_SEL(CFG_FAM).MULTIPLIER_DELAY;

  signal word0_a : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_word0_in_a : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_word0_in_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_word0_result : dubl67_scratchpad_data(VECTOR_LANES-1 downto 0);

  type shamt5_scratchpad_data is array (natural range <>) of std_logic_vector(4 downto 0);

  signal word0_shamt                   : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_shamt_of_h              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word0_shamt_of_b              : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word0_shamt_of                : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal word0_shamt_trunc             : shamt5_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal word0_shift_in      : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word0_shamt_rom_out : word34_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_shift_word0_in_a : word34_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_shift_word0_in_b : word33_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal start_rot                   : std_logic;
  signal start_shift                 : std_logic;
  signal start_shiftl                : std_logic;
  signal start_signed                : std_logic;
  signal start_m1_max_size           : opsize;
  signal start_size                  : opsize;
  signal end_signed                  : std_logic;
  signal end_size                    : opsize;
  signal end_size_word               : std_logic;
  signal start_byte                  : std_logic;
  signal start_word                  : std_logic;
  attribute dont_merge of start_word : signal is true;
  signal start_half                  : std_logic;
  attribute dont_merge of start_half : signal is true;
  signal start_mulhi                 : std_logic;

  type   mul_flag_shifter_type is array ((VECTOR_LANES*4)-1 downto 0) of std_logic_vector(MULTIPLIER_DELAY downto 0);
  signal rot_flag_shifter : mul_flag_shifter_type;

  signal mul_word0_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half0_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte0_oflow : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal mul_word0_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_half0_round : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal mul_byte0_round : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal fxp_word0_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half0_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte0_pos_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_word0_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half0_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte0_neg_of : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_word0_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_half0_of     : std_logic_vector(VECTOR_LANES-1 downto 0);
  signal fxp_byte0_of     : std_logic_vector(VECTOR_LANES-1 downto 0);

  signal mul_out_low  : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_high : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_fxp  : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal mul_out      : byte8_scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal mul_out_fxp_word0 : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_half0 : half16_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal mul_out_fxp_byte0 : byte8_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal mul_out_low_flag      : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_low_flag_reg  : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_high_flag     : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal mul_out_high_flag_reg : std_logic_vector((VECTOR_LANES*4)-1 downto 0);

  signal fxp_mul_flag          : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal fxp_mul_flag_reg      : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal end_fxp_dn1           : std_logic;
  type   mul_type is (MULHI_SHIFTR, MULLO_SHIFTL, MULFXP, ROTLR);
  signal end_mul_type_dn1      : mul_type;
  signal end_mul_type          : mul_type;
  signal end_mul_type_reg      : mul_type;
  signal end_rot_not_mul_dn1   : std_logic;
  signal end_mulhi_shiftr_dn1  : std_logic;
  signal end_rot_mulhi_fxp_dn1 : std_logic_vector(2 downto 0);
begin
  -- Check that parameters are valid
  assert MULTIPLIER_INPUT_REG >= 0
    and MULTIPLIER_INPUT_REG <= 1
    report "MULTIPLIER_INPUT_REG ("
    & integer'image(MULTIPLIER_INPUT_REG) &
    ") must be either 0 or 1"
    severity failure;

  start_m1_max_size <= instruction_pipeline(STAGE_MUL_START-1).in_size when
                       (unsigned(instruction_pipeline(STAGE_MUL_START-1).in_size) >
                        unsigned(instruction_pipeline(STAGE_MUL_START-1).out_size)) else
                       instruction_pipeline(STAGE_MUL_START-1).out_size;
  -- purpose: register separately from instruction pipeline, for timing
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      start_shiftl <= not instruction_pipeline(STAGE_MUL_START-1).op(0);
      start_word   <= start_m1_max_size(1);
      start_half   <= start_m1_max_size(0);
      start_shift  <= op_is_shift(instruction_pipeline(STAGE_MUL_START-1).op);
      start_rot    <= instruction_pipeline(STAGE_MUL_START-1).op(1);
      if op_is_shift(instruction_pipeline(STAGE_MUL_START-1).op) = '0' then
        start_signed <= instruction_pipeline(STAGE_MUL_START-1).signedness;
      else
        start_signed <= (instruction_pipeline(STAGE_MUL_START-1).signedness and
                         (not instruction_pipeline(STAGE_MUL_START-1).op(1)));
      end if;
      start_size  <= start_m1_max_size;
      start_mulhi <= instruction_pipeline(STAGE_MUL_START-1).op(0);
      start_byte  <= (not start_m1_max_size(1)) and (not start_m1_max_size(0));

      end_mul_type <= end_mul_type_dn1;
      if op_is_shift(instruction_pipeline(STAGE_MUL_END-1).op) = '0' then
        end_signed <= instruction_pipeline(STAGE_MUL_END-1).signedness;
      else
        end_signed <= (instruction_pipeline(STAGE_MUL_END-1).signedness and
                       (not instruction_pipeline(STAGE_MUL_END-1).op(1)));
      end if;
      if (unsigned(instruction_pipeline(STAGE_MUL_END-1).in_size) >
          unsigned(instruction_pipeline(STAGE_MUL_END-1).out_size)) then
        end_size <= instruction_pipeline(STAGE_MUL_END-1).in_size;
      else
        end_size <= instruction_pipeline(STAGE_MUL_END-1).out_size;
      end if;
    end if;
  end process;
  end_fxp_dn1 <= (not op_is_shift(instruction_pipeline(STAGE_MUL_END-1).op)) and
                 instruction_pipeline(STAGE_MUL_END-1).op(1);
  end_rot_not_mul_dn1 <= op_is_shift(instruction_pipeline(STAGE_MUL_END-1).op) and
                         instruction_pipeline(STAGE_MUL_END-1).op(1);
  end_mulhi_shiftr_dn1  <= instruction_pipeline(STAGE_MUL_END-1).op(0);
  end_rot_mulhi_fxp_dn1 <= end_rot_not_mul_dn1 & end_mulhi_shiftr_dn1 & end_fxp_dn1;
  with end_rot_mulhi_fxp_dn1 select
    end_mul_type_dn1 <=
    MULLO_SHIFTL when "000",
    MULHI_SHIFTR when "010",
    MULFXP       when "001",
    MULFXP       when "011",
    ROTLR        when others;

  end_size_word <= end_size(1);

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      end_mul_type_reg <= end_mul_type;
    end if;
  end process;

  mult_word_gen : for gword in VECTOR_LANES-1 downto 0 generate
    word0_a(gword) <= "00" & scratchpad_data_to_word32_scratchpad_data(data_a)(gword);
    with start_size select
      mul_word0_in_a(gword) <=
      s_z_extend(31, start_signed, word0_a(gword)) when OPSIZE_WORD,
      s_z_extend(15, start_signed, word0_a(gword)) when OPSIZE_HALF,
      s_z_extend(7, start_signed, word0_a(gword))  when others;
    word0_b(gword) <= '0' & scratchpad_data_to_word32_scratchpad_data(data_b)(gword);
    with start_size select
      mul_word0_in_b(gword) <=
      s_z_extend(31, start_signed, word0_b(gword)) when OPSIZE_WORD,
      s_z_extend(15, start_signed, word0_b(gword)) when OPSIZE_HALF,
      s_z_extend(7, start_signed, word0_b(gword))  when others;

    word0_shamt(gword)      <= scratchpad_data_to_word32_scratchpad_data(data_a)(gword)(4 downto 0);
    word0_shamt_of_h(gword) <= (not start_rot) and word0_shamt(gword)(4) and
                               start_half;
    word0_shamt_of_b(gword) <= (not start_rot) and (word0_shamt(gword)(4) or word0_shamt(gword)(3)) and
                               start_byte;
    word0_shamt_of(gword)       <= word0_shamt_of_h(gword) or word0_shamt_of_b(gword);
    word0_shamt_trunc(gword)(4) <= word0_shamt(gword)(4) when start_word = '1' else
                                   (not start_shiftl) or word0_shamt_of_h(gword);
    word0_shamt_trunc(gword)(3) <= word0_shamt(gword)(3) and (not word0_shamt_of_h(gword)) when start_byte = '0' else
                                   (not start_shiftl) or word0_shamt_of_b(gword);
    word0_shamt_trunc(gword)(2 downto 0) <= word0_shamt(gword)(2 downto 0) when word0_shamt_of(gword) = '0' else
                                            "000";

    word0_shift_in(gword)(33) <= word0_shamt_rom_out(gword)(33);
    word0_shift_in(gword)(32) <= '0' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                 word0_shamt_rom_out(gword)(32);
    word0_shift_in(gword)(31 downto 17) <= word0_shamt_rom_out(gword)(31 downto 17);
    word0_shift_in(gword)(16)           <= '0' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                           word0_shamt_rom_out(gword)(16);
    word0_shift_in(gword)(15 downto 9) <= word0_shamt_rom_out(gword)(15 downto 9);
    word0_shift_in(gword)(8)           <= '0' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                          word0_shamt_rom_out(gword)(8);
    word0_shift_in(gword)(7 downto 1) <= word0_shamt_rom_out(gword)(7 downto 1);
    word0_shift_in(gword)(0)          <= '1' when word0_shamt_of(gword) = '1' and start_shiftl = '0' else
                                         word0_shamt_rom_out(gword)(0);

    word0_shamt_rom : word_shamt_rom
      port map (
        shamt_trunc        => word0_shamt_trunc(gword),
        shiftl             => start_shiftl,
        word_shamt_rom_out => word0_shamt_rom_out(gword)
        );

    mul_in_reg_gen : if MULTIPLIER_INPUT_REG = 1 generate
      mul_in_reg : process (clk)
      begin  -- process mul_in_reg
        if clk'event and clk = '1' then  -- rising clock edge
          if start_shift = '1' then
            mul_shift_word0_in_a(gword) <= word0_shift_in(gword);
          else
            mul_shift_word0_in_a(gword) <= mul_word0_in_a(gword);
          end if;
          mul_shift_word0_in_b(gword) <= mul_word0_in_b(gword);
        end if;
      end process mul_in_reg;
    end generate mul_in_reg_gen;
    mul_in_no_reg_gen : if MULTIPLIER_INPUT_REG = 0 generate
      mul_shift_word0_in_a(gword) <= word0_shift_in(gword) when start_shift = '1' else mul_word0_in_a(gword);
      mul_shift_word0_in_b(gword) <= mul_word0_in_b(gword);
    end generate mul_in_no_reg_gen;

    use_high_low_reg : process (clk)
    begin  -- process use_high_low_reg
      if clk'event and clk = '1' then   -- rising clock edge
        rot_flag_shifter(gword*4+0)(0) <= data_b(gword*4+0).flag;
        rot_flag_shifter(gword*4+1)(0) <= data_b(gword*4+1).flag;
        rot_flag_shifter(gword*4+2)(0) <= data_b(gword*4+2).flag;
        rot_flag_shifter(gword*4+3)(0) <= data_b(gword*4+3).flag;

        rot_flag_shifter(gword*4+0)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+0)(MULTIPLIER_DELAY-1 downto 0);
        rot_flag_shifter(gword*4+1)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+1)(MULTIPLIER_DELAY-1 downto 0);
        rot_flag_shifter(gword*4+2)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+2)(MULTIPLIER_DELAY-1 downto 0);
        rot_flag_shifter(gword*4+3)(MULTIPLIER_DELAY downto 1) <=
          rot_flag_shifter(gword*4+3)(MULTIPLIER_DELAY-1 downto 0);
      end if;
    end process use_high_low_reg;

    word0_multiplier : hardware_mult
      generic map (
        WIDTH_A   => 34,
        WIDTH_B   => 33,
        WIDTH_OUT => 67,
        DELAY     => MULTIPLIER_DELAY-MULTIPLIER_INPUT_REG
        )
      port map (
        clk    => clk,
        dataa  => mul_shift_word0_in_a(gword),
        datab  => mul_shift_word0_in_b(gword),
        result => mul_word0_result(gword)
        );

    mul_out_low(gword*4+0) <= mul_word0_result(gword)(7 downto 0);
    mul_out_low(gword*4+1) <= mul_word0_result(gword)(15 downto 8);
    mul_out_low(gword*4+2) <= mul_word0_result(gword)(23 downto 16);
    mul_out_low(gword*4+3) <= mul_word0_result(gword)(31 downto 24);
    mul_word0_oflow(gword) <= '1' when (mul_word0_result(gword)(63 downto 32) /= std_logic_vector(to_signed(0, 32)) and
                                        mul_word0_result(gword)(63 downto 32) /= std_logic_vector(to_signed(-1, 32)))
                              else '0';
    mul_half0_oflow(gword) <= '1' when (mul_word0_result(gword)(31 downto 16) /= std_logic_vector(to_signed(0, 16)) and
                                        mul_word0_result(gword)(31 downto 16) /= std_logic_vector(to_signed(-1, 16)))
                              else '0';
    mul_byte0_oflow(gword) <= '1' when (mul_word0_result(gword)(15 downto 8) /= std_logic_vector(to_signed(0, 8)) and
                                        mul_word0_result(gword)(15 downto 8) /= std_logic_vector(to_signed(-1, 8)))
                              else '0';

    with end_size select
      mul_out_high(gword*4+0) <=
      mul_word0_result(gword)(15 downto 8)  when OPSIZE_BYTE,
      mul_word0_result(gword)(23 downto 16) when OPSIZE_HALF,
      mul_word0_result(gword)(39 downto 32) when others;
    with end_size_word select
      mul_out_high(gword*4+1) <=
      mul_word0_result(gword)(31 downto 24) when '0',
      mul_word0_result(gword)(47 downto 40) when others;
    mul_out_high(gword*4+2) <= mul_word0_result(gword)(55 downto 48);
    mul_out_high(gword*4+3) <= mul_word0_result(gword)(63 downto 56);

    mul_word0_round(gword) <= mul_word0_result(gword)(31);
    mul_half0_round(gword) <= mul_word0_result(gword)(15);
    mul_byte0_round(gword) <= mul_word0_result(gword)(7);

    with end_size select
      mul_out_low_flag(gword*4+0) <=
      mul_word0_oflow(gword) when OPSIZE_WORD,
      mul_half0_oflow(gword) when OPSIZE_HALF,
      mul_byte0_oflow(gword) when others;
    mul_out_low_flag(gword*4+1) <= mul_out_low_flag(gword*4+0);
    mul_out_low_flag(gword*4+2) <= mul_out_low_flag(gword*4+0);
    mul_out_low_flag(gword*4+3) <= mul_out_low_flag(gword*4+0);
    with end_size select
      mul_out_high_flag(gword*4+0) <=
      mul_word0_round(gword) when OPSIZE_WORD,
      mul_half0_round(gword) when OPSIZE_HALF,
      mul_byte0_round(gword) when others;
    mul_out_high_flag(gword*4+1) <= mul_out_high_flag(gword*4+0);
    mul_out_high_flag(gword*4+2) <= mul_out_high_flag(gword*4+0);
    mul_out_high_flag(gword*4+3) <= mul_out_high_flag(gword*4+0);

    mul_out_fxp_word0(gword)(31) <= mul_word0_result(gword)(mul_word0_result(gword)'left) when end_signed = '1' else
                                    mul_word0_result(gword)(MULFXP_WORD_FRACTION_BITS+31);
    mul_out_fxp_word0(gword)(30 downto 0) <=
      mul_word0_result(gword)(MULFXP_WORD_FRACTION_BITS+30 downto MULFXP_WORD_FRACTION_BITS);

    mul_out_fxp_half0(gword)(15) <= mul_word0_result(gword)(mul_word0_result(gword)'left) when end_signed = '1' else
                                    mul_word0_result(gword)(MULFXP_HALF_FRACTION_BITS+15);
    mul_out_fxp_half0(gword)(14 downto 0) <=
      mul_word0_result(gword)(MULFXP_HALF_FRACTION_BITS+14 downto MULFXP_HALF_FRACTION_BITS);

    mul_out_fxp_byte0(gword)(7) <= mul_word0_result(gword)(mul_word0_result(gword)'left) when end_signed = '1' else
                                   mul_word0_result(gword)(MULFXP_BYTE_FRACTION_BITS+7);
    mul_out_fxp_byte0(gword)(6 downto 0) <=
      mul_word0_result(gword)(MULFXP_BYTE_FRACTION_BITS+6 downto MULFXP_BYTE_FRACTION_BITS);

    fxp_word0_pos_of(gword) <=
      '1' when (mul_word0_result(gword)(64 downto MULFXP_WORD_FRACTION_BITS+32) /=
                replicate_bit('0', 65-(MULFXP_WORD_FRACTION_BITS+32)))
      else '0';
    fxp_word0_neg_of(gword) <=
      '1' when (mul_word0_result(gword)(64 downto MULFXP_WORD_FRACTION_BITS+32) /=
                replicate_bit('1', 65-(MULFXP_WORD_FRACTION_BITS+32)))
      else '0';
    fxp_word0_of(gword) <=
      fxp_word0_neg_of(gword) when end_signed = '1' and mul_word0_result(gword)(MULFXP_WORD_FRACTION_BITS+31) = '1'
      else fxp_word0_pos_of(gword);
    fxp_half0_pos_of(gword) <=
      '1' when (mul_word0_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('0', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half0_neg_of(gword) <=
      '1' when (mul_word0_result(gword)(32 downto MULFXP_HALF_FRACTION_BITS+16) /=
                replicate_bit('1', 33-(MULFXP_HALF_FRACTION_BITS+16)))
      else '0';
    fxp_half0_of(gword) <=
      fxp_half0_neg_of(gword) when end_signed = '1' and mul_word0_result(gword)(MULFXP_HALF_FRACTION_BITS+15) = '1'
      else fxp_half0_pos_of(gword);
    fxp_byte0_pos_of(gword) <=
      '1' when (mul_word0_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('0', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte0_neg_of(gword) <=
      '1' when (mul_word0_result(gword)(16 downto MULFXP_BYTE_FRACTION_BITS+8) /=
                replicate_bit('1', 17-(MULFXP_BYTE_FRACTION_BITS+8)))
      else '0';
    fxp_byte0_of(gword) <=
      fxp_byte0_neg_of(gword) when end_signed = '1' and mul_word0_result(gword)(MULFXP_BYTE_FRACTION_BITS+7) = '1'
      else fxp_byte0_pos_of(gword);
    
    with end_size select
      mul_out_fxp(gword*4+0) <=
      mul_out_fxp_byte0(gword)(7 downto 0) when OPSIZE_BYTE,
      mul_out_fxp_half0(gword)(7 downto 0) when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(7 downto 0) when others;
    with end_size select
      mul_out_fxp(gword*4+1) <=
      mul_out_fxp_half0(gword)(15 downto 8) when OPSIZE_HALF,
      mul_out_fxp_word0(gword)(15 downto 8) when others;
    mul_out_fxp(gword*4+2) <= mul_out_fxp_word0(gword)(23 downto 16);
    mul_out_fxp(gword*4+3) <= mul_out_fxp_word0(gword)(31 downto 24);

    with end_size select
      fxp_mul_flag(gword*4+0) <=
      fxp_word0_of(gword) when OPSIZE_WORD,
      fxp_half0_of(gword) when OPSIZE_HALF,
      fxp_byte0_of(gword) when others;
    fxp_mul_flag(gword*4+1) <= fxp_mul_flag(gword*4+0);
    fxp_mul_flag(gword*4+2) <= fxp_mul_flag(gword*4+0);
    fxp_mul_flag(gword*4+3) <= fxp_mul_flag(gword*4+0);

    mul_flag_reg : process (clk)
    begin  -- process mul_flag_reg
      if clk'event and clk = '1' then   -- rising clock edge
        mul_out_low_flag_reg(gword*4+3 downto gword*4)  <= mul_out_low_flag(gword*4+3 downto gword*4);
        mul_out_high_flag_reg(gword*4+3 downto gword*4) <= mul_out_high_flag(gword*4+3 downto gword*4);
        fxp_mul_flag_reg(gword*4+3 downto gword*4)      <= fxp_mul_flag(gword*4+3 downto gword*4);
      end if;
    end process mul_flag_reg;

    with end_mul_type select
      mul_out(gword*4+0) <=
      mul_out_high(gword*4+0)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+0)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+0)                            when MULFXP,
      mul_out_high(gword*4+0) or mul_out_low(gword*4+0) when others;
    with end_mul_type select
      mul_out(gword*4+1) <=
      mul_out_high(gword*4+1)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+1)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+1)                            when MULFXP,
      mul_out_high(gword*4+1) or mul_out_low(gword*4+1) when others;
    with end_mul_type select
      mul_out(gword*4+2) <=
      mul_out_high(gword*4+2)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+2)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+2)                            when MULFXP,
      mul_out_high(gword*4+2) or mul_out_low(gword*4+2) when others;
    with end_mul_type select
      mul_out(gword*4+3) <=
      mul_out_high(gword*4+3)                           when MULHI_SHIFTR,
      mul_out_low(gword*4+3)                            when MULLO_SHIFTL,
      mul_out_fxp(gword*4+3)                            when MULFXP,
      mul_out_high(gword*4+3) or mul_out_low(gword*4+3) when others;
    mul_data_reg : process (clk)
    begin  -- process mul_data_reg
      if clk'event and clk = '1' then   -- rising clock edge
        multiplier_out(gword*4+0).data <= mul_out(gword*4+0);
        multiplier_out(gword*4+1).data <= mul_out(gword*4+1);
        multiplier_out(gword*4+2).data <= mul_out(gword*4+2);
        multiplier_out(gword*4+3).data <= mul_out(gword*4+3);
      end if;
    end process mul_data_reg;

    with end_mul_type_reg select
      multiplier_out(gword*4+0).flag <=
      mul_out_high_flag_reg(gword*4+0)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+0)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+0)                   when MULFXP,
      rot_flag_shifter(gword*4+0)(MULTIPLIER_DELAY) when others;
    with end_mul_type_reg select
      multiplier_out(gword*4+1).flag <=
      mul_out_high_flag_reg(gword*4+1)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+1)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+1)                   when MULFXP,
      rot_flag_shifter(gword*4+1)(MULTIPLIER_DELAY) when others;
    with end_mul_type_reg select
      multiplier_out(gword*4+2).flag <=
      mul_out_high_flag_reg(gword*4+2)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+2)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+2)                   when MULFXP,
      rot_flag_shifter(gword*4+2)(MULTIPLIER_DELAY) when others;
    with end_mul_type_reg select
      multiplier_out(gword*4+3).flag <=
      mul_out_high_flag_reg(gword*4+3)              when MULHI_SHIFTR,
      mul_out_low_flag_reg(gword*4+3)               when MULLO_SHIFTL,
      fxp_mul_flag_reg(gword*4+3)                   when MULFXP,
      rot_flag_shifter(gword*4+3)(MULTIPLIER_DELAY) when others;
  end generate mult_word_gen;

end architecture word;
