-- hardware_mult_behav.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.
--
-- Behavioural implementation of pipelined multiplier following XST coding
-- guidelines.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity hardware_mult is
  generic (
    WIDTH_A   : integer := 33;
    WIDTH_B   : integer := 33;
    WIDTH_OUT : integer := 66;
    DELAY     : integer := 2
    );
  port
    (
      clk    : in  std_logic;
      dataa  : in  std_logic_vector(WIDTH_A-1 downto 0);
      datab  : in  std_logic_vector(WIDTH_B-1 downto 0);
      result : out std_logic_vector(WIDTH_OUT-1 downto 0)
      );

  -- XST attributes:
  -- attribute mult_style : string;
  -- attribute mult_style of hardware_mult : entity is "pipe_block";
end hardware_mult;

---------------------------------------------------------------------------
architecture rtl of hardware_mult is

  type pipe_stage_type is array (DELAY-1 downto 0) of
    signed(WIDTH_A+WIDTH_B-1 downto 0);

  signal product : signed(WIDTH_A+WIDTH_B-1 downto 0);

begin

  product <= signed(dataa) * signed(datab);

  ----------------------------------------------------------------------
  delay_0: if DELAY = 0 generate
    result <= std_logic_vector(product);
  end generate delay_0;

  ----------------------------------------------------------------------
  delay_1: if DELAY = 1 generate
    signal stage : pipe_stage_type;
  begin

    process (clk)
    begin  -- process
      if clk'event and clk = '1' then
        stage(0) <= product;
      end if;
    end process;

    result <= std_logic_vector(stage(0));

  end generate delay_1;

  ----------------------------------------------------------------------
  delay_gt_1: if DELAY > 1 generate
    signal stage : pipe_stage_type;
  begin

    process (clk)
    begin  -- process
      if clk'event and clk = '1' then
        stage <= stage(DELAY-2 downto 0) & product;
      end if;
    end process;

    result <= std_logic_vector(stage(DELAY-1));

  end generate delay_gt_1;

  ----------------------------------------------------------------------
  assert WIDTH_OUT = WIDTH_A + WIDTH_B report "WIDTH_OUT (" &
    integer'image(WIDTH_OUT) & ") != WIDTH_A + WIDTH_B (" &
    integer'image(WIDTH_A) & "+" & integer'image(WIDTH_B) & ")."
    severity failure;

end rtl;
