library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package utils is

  function imax (
    constant M : integer;
    constant N : integer
    )
    return integer;

  function imin (
    constant M : integer;
    constant N : integer
    )
    return integer;

  function log2(
    N : integer
    )
    return integer;

  function log2_f(
    N : integer
    )
    return integer;

  function conditional (
    a        :    boolean;
    if_true  : in integer;
    if_false : in integer
    )
    return integer;

  function conditional (
    a        :    boolean;
    if_true  : in std_logic_vector;
    if_false : in std_logic_vector
    )
    return std_logic_vector;

  function conditional (
    a        :    boolean;
    if_true  : in signed;
    if_false : in signed
    )
    return signed;

  function bool_to_int (
    signal a : std_logic
    )
    return integer;

  function bool_to_sl (
    a : boolean
    )
    return std_logic;

  function or_slv (
    data_in : std_logic_vector
    )
    return std_logic;

  function and_slv (
    data_in : std_logic_vector
    )
    return std_logic;

end utils;


package body utils is

  function imax(
    constant M : integer;
    constant N : integer
    )
    return integer is
  begin
    if M < N then
      return N;
    end if;

    return M;
  end imax;

  function imin(
    constant M : integer;
    constant N : integer
    )
    return integer is
  begin
    if M < N then
      return M;
    end if;

    return N;
  end imin;

  function log2(
    N : integer
    )
    return integer is
    variable i : integer := 0;
  begin
    while (2**i < n) loop
      i := i + 1;
    end loop;
    return i;
  end log2;

  function log2_f(
    N : integer
    )
    return integer is
    variable i : integer := 0;
  begin
    while (2**i <= n) loop
      i := i + 1;
    end loop;
    return i-1;
  end log2_f;

  function conditional (
    a        :    boolean;
    if_true  : in std_logic_vector;
    if_false : in std_logic_vector
    )
    return std_logic_vector is
  begin
    if a then
      return if_true;
    else
      return if_false;
    end if;
  end conditional;

  function conditional (
    a        :    boolean;
    if_true  : in integer;
    if_false : in integer
    )
    return integer is
  begin
    if a then
      return if_true;
    else
      return if_false;
    end if;
  end conditional;

  function conditional (
    a        :    boolean;
    if_true  : in signed;
    if_false : in signed
    )
    return signed is
  begin
    if a then
      return if_true;
    else
      return if_false;
    end if;
  end conditional;

  function bool_to_int (
    signal a : std_logic
    )
    return integer is
  begin
    if a = '1' then
      return 1;
    end if;
    return 0;
  end function bool_to_int;

  function bool_to_sl (
    a : boolean
    )
    return std_logic is
  begin
    if a then
      return '1';
    end if;
    return '0';
  end function bool_to_sl;

  function or_slv (
    data_in : std_logic_vector
    )
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
    data_in : std_logic_vector
    )
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

end utils;
