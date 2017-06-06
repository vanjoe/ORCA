-- util_pkg.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;

package util_pkg is

  -- Constant functions for derived constant generation
  function imax (
    constant M : integer;
    constant N : integer)
    return integer;
  function imin (
    constant M : integer;
    constant N : integer)
    return integer;
  function log2(
    constant N : integer)
    return integer;
  function log2_f(
    constant N : integer)
    return integer;
  function burst_bits(
    constant BURSTLENGTH_BYTES  : integer;
    constant MEMORY_WIDTH_LANES : integer)
    return integer;

  -- Conversion functions, not constant
  function to_onehot (
    binary_encoded : std_logic_vector)
    return std_logic_vector;

  function replicate_bit (
    input_bit              : std_logic;
    constant RETURN_LENGTH : integer)
    return std_logic_vector;

  function or_slv (
    data_in : std_logic_vector)
    return std_logic;

  function and_slv (
    data_in : std_logic_vector)
    return std_logic;

  function s_z_extend (
    constant SIGN_BIT      : integer;
    signal   signed_extend : std_logic;
    signal   data_in       : std_logic_vector)
    return std_logic_vector;

  function find_first_one(
    signal data_in : std_logic_vector)
    return unsigned;

  function axlen_width(
    constant axi_protocol : integer range 0 to 1)
    return integer;

  function is_registered_stage (
    constant REGISTERS  : natural;
    constant STAGES     : natural;
    constant THIS_STAGE : natural)
    return boolean;

end package;

package body util_pkg is

  function imax(
    constant M : integer;
    constant N : integer)
    return integer is
  begin
    if M < N then
      return N;
    end if;

    return M;
  end imax;

  function imin(
    constant M : integer;
    constant N : integer)
    return integer is
  begin
    if M < N then
      return M;
    end if;

    return N;
  end imin;

  function log2_f(
    constant N : integer)
    return integer is
    variable i : integer := 0;
  begin
    while (2**i <= n) loop
      i := i + 1;
    end loop;
    return i-1;
  end log2_f;

  function log2(
    constant N : integer)
    return integer is
    variable i : integer := 0;
  begin
    while (2**i < n) loop
      i := i + 1;
    end loop;
    return i;
  end log2;

  function burst_bits(
    constant BURSTLENGTH_BYTES  : integer;
    constant MEMORY_WIDTH_LANES : integer)
    return integer is
    variable burst_bits : integer := 0;
  begin
    if memory_width_lanes*4 >= burstlength_bytes then
      return 1;
    end if;
    return log2(burstlength_bytes/(memory_width_lanes*4))+1;
  end burst_bits;

  function to_onehot (
    binary_encoded : std_logic_vector)
    return std_logic_vector is
    variable onehot : std_logic_vector((2**binary_encoded'length)-1 downto 0);
  begin
    onehot                                       := (others => '0');
    onehot(to_integer(unsigned(binary_encoded))) := '1';

    return onehot;
  end to_onehot;
  
  function replicate_bit (
    input_bit              : std_logic;
    constant RETURN_LENGTH : integer)
    return std_logic_vector is
    variable data_out : std_logic_vector(RETURN_LENGTH-1 downto 0);
  begin
    data_out := (others => input_bit);
    return data_out;
  end replicate_bit;
  
  function or_slv (
    data_in : std_logic_vector)
    return std_logic is
    variable data_in_copy : std_logic_vector(data_in'length-1 downto 0);
    variable reduced_or   : std_logic;
  begin
    data_in_copy := data_in;            --Fix alignment/ordering
    reduced_or   := '0';
    for i in data_in_copy'left downto 0 loop
      reduced_or := reduced_or or data_in_copy(i);
    end loop;  -- i

    return reduced_or;
  end or_slv;

  function and_slv (
    data_in : std_logic_vector)
    return std_logic is
    variable data_in_copy : std_logic_vector(data_in'length-1 downto 0);
    variable reduced_and  : std_logic;
  begin
    data_in_copy := data_in;            --Fix alignment/ordering
    reduced_and  := '1';
    for i in data_in_copy'left downto 0 loop
      reduced_and := reduced_and and data_in_copy(i);
    end loop;  -- i

    return reduced_and;
  end and_slv;

  function s_z_extend (
    constant SIGN_BIT      : integer;
    signal   signed_extend : std_logic;
    signal   data_in       : std_logic_vector)
    return std_logic_vector is
    variable data_out    : std_logic_vector(data_in'range);
    constant zero_extend : std_logic_vector(data_in'left downto SIGN_BIT+1) := (others => '0');
    constant one_extend  : std_logic_vector(data_in'left downto SIGN_BIT+1) := (others => '1');
  begin
    data_out(SIGN_BIT downto 0) := data_in(SIGN_BIT downto 0);
    if signed_extend = '1' and data_in(SIGN_BIT) = '1' then
      data_out(data_in'left downto SIGN_BIT+1) := one_extend;
    else
      data_out(data_in'left downto SIGN_BIT+1) := zero_extend;
    end if;
    return data_out;
  end s_z_extend;
  
  function find_first_one(
    signal data_in : std_logic_vector)
    return unsigned is
    variable data_in_copy       : std_logic_vector(data_in'length-1 downto 0);
    variable first_one_location : unsigned(log2(data_in'length)-1 downto 0);
  begin
    data_in_copy       := data_in;      --Fix alignment/ordering
    first_one_location := to_unsigned(0, first_one_location'length);
    for ibit in data_in_copy'length-1 downto 0 loop
      if data_in_copy(ibit) = '1' then
        first_one_location := to_unsigned(ibit, first_one_location'length);
      end if;
    end loop;  -- ibit

    return first_one_location;
  end find_first_one;
  
  -- axi_protocol: 0=AXI4, 1=AXI3
  function axlen_width(
    constant axi_protocol : integer range 0 to 1)
    return integer is
  begin
    if axi_protocol = 0 then
      return 8;
    else
      return 4;
    end if;
  end axlen_width;

  function is_registered_stage (
    constant REGISTERS  : natural;
    constant STAGES     : natural;
    constant THIS_STAGE : natural)
    return boolean is
      variable reg_stage : natural;
  begin
    for ireg in REGISTERS-1 downto 0 loop
      reg_stage := ((ireg+1)*STAGES)/(REGISTERS+1);
      if reg_stage = THIS_STAGE then
        return true;
      end if;
    end loop;  -- ireg

    return false;
  end is_registered_stage;

end util_pkg;
