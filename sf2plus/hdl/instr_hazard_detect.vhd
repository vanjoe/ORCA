-- instr_hazard_detect.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;

entity instr_hazard_detect is
  generic (
    VECTOR_LANES : integer := 1;

    PIPELINE_STAGES : integer := 1;
    HAZARD_STAGES   : integer := 1;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    addr_a       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    instr_uses_a : in std_logic;
    addr_b       : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    instr_uses_b : in std_logic;

    dest_addrs          : in addr_pipeline_type(PIPELINE_STAGES-1 downto 0);
    current_instruction : in std_logic_vector(HAZARD_STAGES-1 downto 0);
    dest_write_shifter  : in std_logic_vector(HAZARD_STAGES-1 downto 0);

    instr_hazard_pipeline : out std_logic_vector(HAZARD_STAGES-1 downto 0)
    );
end entity instr_hazard_detect;

architecture rtl of instr_hazard_detect is
  signal read_a_hazard : std_logic_vector(HAZARD_STAGES-1 downto 0);
  signal read_b_hazard : std_logic_vector(HAZARD_STAGES-1 downto 0);
  signal read_hazard   : std_logic_vector(HAZARD_STAGES-1 downto 0);

  type   scratchpad_addr_pipeline_type is array (natural range <>) of std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal diff_a : scratchpad_addr_pipeline_type(PIPELINE_STAGES-1 downto 0);
  signal diff_b : scratchpad_addr_pipeline_type(PIPELINE_STAGES-1 downto 0);
begin

  instr_hazard_detect_gen : for gstage in HAZARD_STAGES-1 downto 0 generate
    diff_a(gstage) <= std_logic_vector(unsigned(addr_a) - unsigned(dest_addrs(gstage)(ADDR_WIDTH-1 downto 0)));
    diff_b(gstage) <= std_logic_vector(unsigned(addr_b) - unsigned(dest_addrs(gstage)(ADDR_WIDTH-1 downto 0)));

    read_a_hazard(gstage) <= '1' when ((diff_a(gstage)(ADDR_WIDTH-1 downto log2((VECTOR_LANES*4))) =
                                        std_logic_vector(to_signed(0, ADDR_WIDTH-log2((VECTOR_LANES*4))))) or
                                       (diff_a(gstage)(ADDR_WIDTH-1 downto log2((VECTOR_LANES*4))) =
                                        std_logic_vector(to_signed(-1, ADDR_WIDTH-log2((VECTOR_LANES*4))))))
                             else '0';
    read_b_hazard(gstage) <= '1' when ((diff_b(gstage)(ADDR_WIDTH-1 downto log2((VECTOR_LANES*4))) =
                                        std_logic_vector(to_signed(0, ADDR_WIDTH-log2((VECTOR_LANES*4))))) or
                                       (diff_b(gstage)(ADDR_WIDTH-1 downto log2((VECTOR_LANES*4))) =
                                        std_logic_vector(to_signed(-1, ADDR_WIDTH-log2((VECTOR_LANES*4))))))
                             else '0';
    
    read_hazard(gstage) <= ((read_a_hazard(gstage) and instr_uses_a) or (read_b_hazard(gstage) and instr_uses_b)) and
                           dest_write_shifter(gstage) and
                           (not current_instruction(gstage));
  end generate instr_hazard_detect_gen;
  instr_hazard_pipeline <= read_hazard;
  
end architecture rtl;
