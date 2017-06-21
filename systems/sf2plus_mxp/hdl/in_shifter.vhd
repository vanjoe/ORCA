-- in_shifter.vhd
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

entity in_shifter is
  generic (
    VECTOR_LANES : integer := 1;

    PIPELINE_STAGES      : integer := 1;
    EXTRA_ALIGN_STAGES   : integer := 1;
    STAGE_IN_SHIFT_START : integer := 1;
    STAGE_IN_SHIFT_END   : integer := 1;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    instruction_pipeline : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);
    scalar_a             : in std_logic_vector(31 downto 0);
    in_shift_element     : in std_logic_vector(ADDR_WIDTH-1 downto 0);

    offset_a   : in  std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
    readdata_a : in  scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    shifted_a  : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);

    offset_b   : in  std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
    readdata_b : in  scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    shifted_b  : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
    );

  -- attribute secure_netlist     : string;  -- OFF, ENCRYPT, (PROHIBIT not allowed in Vivado)
  -- attribute secure_config      : string;  -- OFF, PROTECT
  -- attribute secure_net_editing : string;  -- OFF, PROHIBIT
  -- attribute secure_bitstream   : string;  -- OFF, PROHIBIT
  -- attribute secure_net_probing : string;  -- OFF, PROHIBIT
  -- attribute check_license      : string;

  -- attribute secure_netlist of in_shifter : entity is "OFF";
  -- attribute secure_config  of in_shifter : entity is "OFF";
  -- attribute check_license  of in_shifter : entity is "ipvblox_mxp";

end entity in_shifter;

architecture rtl of in_shifter is
  type   align_2d_scratchpad is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector(((VECTOR_LANES*4)*9)-1 downto 0);
  signal barrel_a_in  : align_2d_scratchpad;
  signal barrel_b_in  : align_2d_scratchpad;
  signal barrel_a_out : align_2d_scratchpad;
  signal barrel_b_out : align_2d_scratchpad;

  type   align_2d_offset is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
  signal offset_a_shifter              : align_2d_offset;
  signal offset_b_shifter              : align_2d_offset;
  signal offset_a_masked               : align_2d_offset;
  signal offset_b_masked               : align_2d_offset;

  type   align_2d_scalar is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector(31 downto 0);
  signal scalar_a_sized : align_2d_scalar;

  signal scalar_a_end                  : std_logic_vector(31 downto 0);
  attribute dont_merge of scalar_a_end : signal is true;
  signal scalar_a_scratchpad           : scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  type   align_2d_scratchpad_addr is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal in_element_delayed      : align_2d_scratchpad_addr;
  signal element_word            : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal element_scratchpad_data : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal end_in_element_word     : std_logic_vector(31 downto 0);
  signal end_in_element_half     : std_logic_vector(15 downto 0);
  signal end_in_element_byte     : std_logic_vector(7 downto 0);

  type   align_2d_opsize is array (EXTRA_ALIGN_STAGES downto 0) of opsize;
  signal size_delayed          : align_2d_opsize;
  signal size                  : opsize;
  attribute dont_merge of size : signal is true;
  signal end_size              : opsize;

  signal resized_a : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal resized_b : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
begin

  barrel_a_in(0)        <= scratchpad_data_to_byte9(readdata_a);
  barrel_b_in(0)        <= scratchpad_data_to_byte9(readdata_b);
  offset_a_shifter(0)   <= offset_a;
  offset_b_shifter(0)   <= offset_b;
  in_element_delayed(0) <= in_shift_element;
  size_delayed(0)       <= size;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      size <= instruction_pipeline(STAGE_IN_SHIFT_START-1).size;
    end if;
  end process;
  scalar_a_sized(0)(7 downto 0)   <= scalar_a(7 downto 0);
  scalar_a_sized(0)(15 downto 8)  <= scalar_a(7 downto 0) when size = OPSIZE_BYTE  else scalar_a(15 downto 8);
  scalar_a_sized(0)(23 downto 16) <= scalar_a(7 downto 0) when size /= OPSIZE_WORD else scalar_a(23 downto 16);
  with size select
    scalar_a_sized(0)(31 downto 24) <=
    scalar_a(7 downto 0)   when OPSIZE_BYTE,
    scalar_a(15 downto 8)  when OPSIZE_HALF,
    scalar_a(31 downto 24) when others;

  barrel_shifters_gen : for gstage in EXTRA_ALIGN_STAGES downto 0 generate
    -- purpose: Mask offsets for each stage so final shift amount is correct
    offset_mask_proc : process (offset_a_shifter(gstage), offset_b_shifter(gstage))
    begin  -- process offset_mask_proc
      offset_a_masked(gstage) <= (others => '0');
      offset_b_masked(gstage) <= (others => '0');

      offset_a_masked(gstage)(
        (((gstage+1)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))-1 downto
        (((gstage+0)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))) <=
        offset_a_shifter(gstage)(
          (((gstage+1)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))-1 downto
          (((gstage+0)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES)));
      offset_b_masked(gstage)(
        (((gstage+1)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))-1 downto
        (((gstage+0)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))) <=
        offset_b_shifter(gstage)(
          (((gstage+1)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))-1 downto
          (((gstage+0)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES)));
    end process offset_mask_proc;

    barrel_shifter_a : barrel_shifter
      generic map (
        WORD_WIDTH => 9,
        WORDS      => (VECTOR_LANES*4),
        LEFT_SHIFT => false
        )
      port map (
        data_in      => barrel_a_in(gstage),
        shift_amount => offset_a_masked(gstage),
        data_out     => barrel_a_out(gstage)
        );

    barrel_shifter_b : barrel_shifter
      generic map (
        WORD_WIDTH => 9,
        WORDS      => (VECTOR_LANES*4),
        LEFT_SHIFT => false
        )
      port map (
        data_in      => barrel_b_in(gstage),
        shift_amount => offset_b_masked(gstage),
        data_out     => barrel_b_out(gstage)
        );

    shifter_reg_gen : if gstage > 0 generate
      shifter_reg_proc : process (clk)
      begin  -- process shifter_reg
        if clk'event and clk = '1' then  -- rising clock edge
          offset_a_shifter(gstage)   <= offset_a_shifter(gstage-1);
          offset_b_shifter(gstage)   <= offset_b_shifter(gstage-1);
          scalar_a_sized(gstage)     <= scalar_a_sized(gstage-1);
          in_element_delayed(gstage) <= in_element_delayed(gstage-1);
          size_delayed(gstage)       <= size_delayed(gstage-1);
          barrel_a_in(gstage)        <= barrel_a_out(gstage-1);
          barrel_b_in(gstage)        <= barrel_b_out(gstage-1);

          if reset = '1' then  --Prevent shift register inference for timing
            offset_a_shifter(gstage) <= (others => '0');
            offset_b_shifter(gstage) <= (others => '0');
          end if;
        end if;
      end process shifter_reg_proc;
    end generate shifter_reg_gen;
  end generate barrel_shifters_gen;
  end_size <= size_delayed(EXTRA_ALIGN_STAGES);

  no_extra_copy_gen : if EXTRA_ALIGN_STAGES = 0 generate
    scalar_a_end <= scalar_a_sized(0);
  end generate no_extra_copy_gen;
  extra_copy_gen : if EXTRA_ALIGN_STAGES > 0 generate
    extra_copy_replicate_proc : process (clk)
    begin  -- process extra_copy_replicate_proc
      if clk'event and clk = '1' then   -- rising clock edge
        scalar_a_end <= scalar_a_sized(EXTRA_ALIGN_STAGES-1);
      end if;
    end process extra_copy_replicate_proc;
  end generate extra_copy_gen;

  end_in_element_word <= std_logic_vector(resize(unsigned(in_element_delayed(EXTRA_ALIGN_STAGES)), 32));
  end_in_element_half <= std_logic_vector(resize(unsigned(in_element_delayed(EXTRA_ALIGN_STAGES)), 16));
  end_in_element_byte <= std_logic_vector(resize(unsigned(in_element_delayed(EXTRA_ALIGN_STAGES)), 8));
  copy_to_scratchpad_gen : for gword in VECTOR_LANES-1 downto 0 generate
    scalar_a_scratchpad(gword*4).data   <= scalar_a_end(7 downto 0);
    scalar_a_scratchpad(gword*4).flag   <= '0';
    scalar_a_scratchpad(gword*4+1).data <= scalar_a_end(15 downto 8);
    scalar_a_scratchpad(gword*4+1).flag <= '0';
    scalar_a_scratchpad(gword*4+2).data <= scalar_a_end(23 downto 16);
    scalar_a_scratchpad(gword*4+2).flag <= '0';
    scalar_a_scratchpad(gword*4+3).data <= scalar_a_end(31 downto 24);
    scalar_a_scratchpad(gword*4+3).flag <= '0';

    with end_size select
      element_word(gword) <=
      (end_in_element_word or std_logic_vector(to_unsigned(gword, 32)))     when OPSIZE_WORD,
      (end_in_element_half or std_logic_vector(to_unsigned(gword*2+1, 16))) &
      (end_in_element_half or std_logic_vector(to_unsigned(gword*2+0, 16))) when OPSIZE_HALF,
      (end_in_element_byte or std_logic_vector(to_unsigned(gword*4+3, 8))) &
      (end_in_element_byte or std_logic_vector(to_unsigned(gword*4+2, 8))) &
      (end_in_element_byte or std_logic_vector(to_unsigned(gword*4+1, 8))) &
      (end_in_element_byte or std_logic_vector(to_unsigned(gword*4+0, 8)))  when others;
  end generate copy_to_scratchpad_gen;
  element_scratchpad_data((VECTOR_LANES*4)-1 downto 0) <= word32_scratchpad_data_to_scratchpad_data(element_word);

  size_up_a : size_up
    generic map (
      VECTOR_LANES => VECTOR_LANES
      )
    port map (
      clk => clk,

      next_instruction => instruction_pipeline(STAGE_IN_SHIFT_END-1),

      data_in  => byte9_to_scratchpad_data(barrel_a_out(EXTRA_ALIGN_STAGES)),
      data_out => resized_a
      );

  size_up_b : size_up
    generic map (
      VECTOR_LANES => VECTOR_LANES
      )
    port map (
      clk => clk,

      next_instruction => instruction_pipeline(STAGE_IN_SHIFT_END-1),

      data_in  => byte9_to_scratchpad_data(barrel_b_out(EXTRA_ALIGN_STAGES)),
      data_out => resized_b
      );

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if instruction_pipeline(STAGE_IN_SHIFT_END).sv = '1' then
        shifted_a <= scalar_a_scratchpad;
      else
        shifted_a <= resized_a;
      end if;
      if instruction_pipeline(STAGE_IN_SHIFT_END).ve = '1' then
        shifted_b <= element_scratchpad_data((VECTOR_LANES*4)-1 downto 0);
      else
        shifted_b <= resized_b;
      end if;
    end if;
  end process;

end architecture rtl;
