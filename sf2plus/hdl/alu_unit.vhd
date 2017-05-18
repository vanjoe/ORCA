-- alu_unit.vhd
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

entity alu_unit is
  generic (
    VECTOR_LANES : integer := 1;

    CFG_FAM : config_family_type;

    PIPELINE_STAGES : integer := 1;
    STAGE_MUL_START : integer := 1
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    exec_byteena         : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    instruction_pipeline : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);

    data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

    mask_writedata_enables : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);

    alu_byteena : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    alu_out     : out scratchpad_data((VECTOR_LANES*4)-1 downto 0)
    );
end entity alu_unit;

architecture rtl of alu_unit is
  constant MULTIPLIER_DELAY : positive := CFG_SEL(CFG_FAM).MULTIPLIER_DELAY;

  signal flat_scratchpad_a   : std_logic_vector(VECTOR_LANES*36-1 downto 0);
  signal flat_scratchpad_b   : std_logic_vector(VECTOR_LANES*36-1 downto 0);
  signal flat_scratchpad_and : std_logic_vector(VECTOR_LANES*36-1 downto 0);
  signal flat_scratchpad_or  : std_logic_vector(VECTOR_LANES*36-1 downto 0);
  signal flat_scratchpad_xor : std_logic_vector(VECTOR_LANES*36-1 downto 0);
  signal logic_result_flat   : std_logic_vector(VECTOR_LANES*36-1 downto 0);
  signal logic_op            : std_logic_vector(1 downto 0);
  signal alu_function        : alu_function_type;
  signal arith_out           : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal cmov_out            : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal cmov_byteena        : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal absv_out            : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal byteena             : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal result_sans_arith   : scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal result_sans_arith_reg : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal arith_out_reg         : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal is_arith_reg          : std_logic;
  signal result_reg            : scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  type   result_shifter_type is array (MULTIPLIER_DELAY-1 downto 1) of scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal result_shifter  : result_shifter_type;
  type   byteena_shifter_type is array (MULTIPLIER_DELAY-1 downto 0) of std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal byteena_shifter : byteena_shifter_type;
begin
  flat_scratchpad_a <= scratchpad_data_to_byte9(data_a);
  flat_scratchpad_b <= scratchpad_data_to_byte9(data_b);

  flat_scratchpad_and <= flat_scratchpad_a and flat_scratchpad_b;
  flat_scratchpad_or  <= flat_scratchpad_a or flat_scratchpad_b;
  flat_scratchpad_xor <= flat_scratchpad_a xor flat_scratchpad_b;

  -- Selected by OP_VMOV, OP_VAND, OP_VOR, OP_VXOR in isa_pkg.vhd
  with logic_op select
    logic_result_flat <=
    flat_scratchpad_a   when "00",
    flat_scratchpad_and when "01",
    flat_scratchpad_or  when "10",
    flat_scratchpad_xor when others;

  arith_stage : arith_unit
    generic map (
      VECTOR_LANES => VECTOR_LANES
      )
    port map (
      clk   => clk,
      reset => reset,

      next_instruction => instruction_pipeline(STAGE_MUL_START-1),
      instruction      => instruction_pipeline(STAGE_MUL_START),

      data_a => data_a,
      data_b => data_b,

      arith_out => arith_out
      );

  cmov_stage : cmov_unit
    generic map (
      VECTOR_LANES => VECTOR_LANES
      )
    port map (
      clk   => clk,
      reset => reset,

      instruction => instruction_pipeline(STAGE_MUL_START),

      data_a => data_a,
      data_b => data_b,

      cmov_byteena => cmov_byteena,
      cmov_out     => cmov_out
      );

  with alu_function select
    result_sans_arith <=
    cmov_out                                    when CMOV,
    byte9_to_scratchpad_data(logic_result_flat) when others;

  with alu_function select
    byteena <=
    exec_byteena and cmov_byteena when CMOV,
    exec_byteena                  when others;

  mask_writedata_enables <= exec_byteena and cmov_byteena;

  result_reg <= arith_out_reg when is_arith_reg = '1' else result_sans_arith_reg;

  process (clk)
  begin
    if clk'event and clk = '1' then     -- rising clock edge
      if alu_function = ARITH then
        is_arith_reg <= '1';
      else
        is_arith_reg <= '0';
      end if;
    end if;
  end process;

  absv_stage : absv_unit
    generic map (
      VECTOR_LANES => VECTOR_LANES
      )
    port map (
      clk   => clk,
      reset => reset,

      next_instruction => instruction_pipeline(STAGE_MUL_START),
      instruction      => instruction_pipeline(STAGE_MUL_START+1),

      alu_result => result_reg,

      absv_out => absv_out
      );

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      logic_op     <= instruction_pipeline(STAGE_MUL_START-1).op(1 downto 0);
      alu_function <= op_alu_function(instruction_pipeline(STAGE_MUL_START-1).op);

      arith_out_reg         <= arith_out;
      result_sans_arith_reg <= result_sans_arith;

      result_shifter(1)                            <= absv_out;
      result_shifter(result_shifter'left downto 2) <= result_shifter(result_shifter'left-1 downto 1);

      byteena_shifter(0)                             <= byteena;
      byteena_shifter(byteena_shifter'left downto 1) <= byteena_shifter(byteena_shifter'left-1 downto 0);

      if reset = '1' then
        logic_op        <= (others => '0');
        result_shifter  <= (others => (others => (flag => '0', data => (others => '0'))));
        byteena_shifter <= (others => (others => '0'));
      end if;
    end if;
  end process;
  alu_out     <= result_shifter(result_shifter'left);
  alu_byteena <= byteena_shifter(byteena_shifter'left);

end architecture rtl;
