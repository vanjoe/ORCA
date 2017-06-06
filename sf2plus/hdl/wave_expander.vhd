-- wave_expander.vhd
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

entity wave_expander is
  generic (
    VECTOR_LANES : integer  := 1;
    PARTS        : positive := 2
    );
  port(
    enables_in : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    available  : in std_logic_vector(PARTS-1 downto 0);

    alignment      : out std_logic_vector(log2(PARTS)-1 downto 0);
    next_available : out std_logic_vector(PARTS-1 downto 0);
    last           : out std_logic;
    enables_out    : out std_logic_vector((VECTOR_LANES*4)-1 downto 0)
    );
end entity wave_expander;

architecture rtl of wave_expander is
  constant PARTIAL_ENABLE_SIZE : positive := (VECTOR_LANES*4)/PARTS;

  signal valid               : std_logic_vector(PARTS-1 downto 0);
  signal valid_and_available : std_logic_vector(PARTS-1 downto 0);

  signal alignment_s      : unsigned(log2(PARTS)-1 downto 0);
  signal next_available_s : std_logic_vector(PARTS-1 downto 0);

  type   partial_enables_2d_type is array (natural range <>) of std_logic_vector(PARTIAL_ENABLE_SIZE-1 downto 0);
  signal partial_enables_2d : partial_enables_2d_type(PARTS-1 downto 0);
  signal selected_enables   : std_logic_vector(PARTIAL_ENABLE_SIZE-1 downto 0);
begin
  parts_gen : for gpart in PARTS-1 downto 0 generate
    partial_enables_2d(gpart) <= enables_in(((gpart+1)*PARTIAL_ENABLE_SIZE)-1 downto gpart*PARTIAL_ENABLE_SIZE);
    valid(gpart)              <= or_slv(partial_enables_2d(gpart));
  end generate parts_gen;
  valid_and_available <= valid and available;
  alignment_s         <= find_first_one(valid_and_available);
  next_available_s    <= (not to_onehot(std_logic_vector(alignment_s))) and valid_and_available;
  selected_enables    <= partial_enables_2d(to_integer(alignment_s));

  alignment      <= std_logic_vector(alignment_s);
  next_available <= next_available_s;
  last           <= '1' when next_available_s = std_logic_vector(to_unsigned(0, next_available_s'length)) else '0';
  bit_replicate_gen : for genable in PARTIAL_ENABLE_SIZE-1 downto 0 generate
    enables_out(((genable+1)*PARTS)-1 downto genable*PARTS) <= replicate_bit(selected_enables(genable), PARTS);
  end generate bit_replicate_gen;
end architecture rtl;
