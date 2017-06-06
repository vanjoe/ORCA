-- isa_pkg.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;

package isa_pkg is
  constant N_BITS          : natural := 2;
  constant N_INSTR_A_B     : integer := 0;
  constant N_INSTR_OP_DEST : integer := 1;
  constant N_SYNC          : integer := 2;
  constant N_GET_SET       : integer := 3;


  constant GET_BITS : integer                               := 4;
  constant GET_VL   : std_logic_vector(GET_BITS-1 downto 0) := "0000";
  constant GET_VL2D : std_logic_vector(GET_BITS-1 downto 0) := "0001";
  constant GET_ID   : std_logic_vector(GET_BITS-1 downto 0) := "0010";
  constant GET_IA   : std_logic_vector(GET_BITS-1 downto 0) := "0011";
  constant GET_IB   : std_logic_vector(GET_BITS-1 downto 0) := "0100";
  constant GET_VL3D : std_logic_vector(GET_BITS-1 downto 0) := "0101";
  constant GET_ID3D : std_logic_vector(GET_BITS-1 downto 0) := "0110";
  constant GET_IA3D : std_logic_vector(GET_BITS-1 downto 0) := "0111";
  constant GET_IB3D : std_logic_vector(GET_BITS-1 downto 0) := "1000";

  constant OPCODE_BITS       : natural := 6;
  subtype  opcode is std_logic_vector(OPCODE_BITS-1 downto 0);
  subtype  opsize is std_logic_vector(1 downto 0);

  constant OPSIZE_DUBL : opsize := "11";
  constant OPSIZE_WORD : opsize := "10";
  constant OPSIZE_HALF : opsize := "01";
  constant OPSIZE_BYTE : opsize := "00";

  type instruction_type is record
    op         : opcode;
    signedness : std_logic;
    in_size    : opsize;
    size       : opsize;
    out_size   : opsize;
    masked     : std_logic;
    sv         : std_logic;
    ve         : std_logic;
    acc        : std_logic;
    two_d      : std_logic;
    three_d    : std_logic;
    a          : std_logic_vector(31 downto 0);
    b          : std_logic_vector(31 downto 0);
    dest       : std_logic_vector(31 downto 0);
  end record;

  constant INSTRUCTION_NULL : instruction_type := (op => (others => '0'), signedness => '0', in_size => (others => '0'), size => (others => '0'), out_size => (others => '0'), masked => '0', sv => '0', ve => '0', acc => '0', two_d => '0', three_d => '0', a => (others => '0'), b => (others => '0'), dest => (others => '0'));

  -- Opcodes

  -- Affects op_is_dma, op_is_process
  constant OP_DMA_TO_HOST   : opcode := std_logic_vector(to_unsigned(0, OPCODE_BITS));
  -- Affects op_is_dma, op_is_process
  constant OP_DMA_TO_VECTOR : opcode := std_logic_vector(to_unsigned(1, OPCODE_BITS));
  -- Affects op_is_process
  constant OP_SET_VL        : opcode := std_logic_vector(to_unsigned(2, OPCODE_BITS));

  -- Processing opcodes

  -- Affects logic_op in alu_unit
  constant OP_VMOV : opcode := std_logic_vector(to_unsigned(4, OPCODE_BITS));
  constant OP_VAND : opcode := std_logic_vector(to_unsigned(5, OPCODE_BITS));
  constant OP_VOR  : opcode := std_logic_vector(to_unsigned(6, OPCODE_BITS));
  constant OP_VXOR : opcode := std_logic_vector(to_unsigned(7, OPCODE_BITS));

  constant OP_VADD          : opcode  := std_logic_vector(to_unsigned(8, OPCODE_BITS));
  constant OP_VSUB          : opcode  := std_logic_vector(to_unsigned(9, OPCODE_BITS));
  constant OP_VADDC         : opcode  := std_logic_vector(to_unsigned(10, OPCODE_BITS));
  constant OP_VSUBB         : opcode  := std_logic_vector(to_unsigned(11, OPCODE_BITS));
  constant OPCODE_ARITH_BIT : integer := 3;  -- Indicates add not logic op

  --Affects op_uses_mul
  constant OP_VMUL    : opcode := std_logic_vector(to_unsigned(12, OPCODE_BITS));
  constant OP_VMULHI  : opcode := std_logic_vector(to_unsigned(13, OPCODE_BITS));
  constant OP_VMULFXP : opcode := std_logic_vector(to_unsigned(14, OPCODE_BITS));


  --Affects op_is_shift
  constant OP_VSHL  : opcode := std_logic_vector(to_unsigned(16, OPCODE_BITS));
  constant OP_VSHR  : opcode := std_logic_vector(to_unsigned(17, OPCODE_BITS));
  constant OP_VROTL : opcode := std_logic_vector(to_unsigned(18, OPCODE_BITS));
  constant OP_VROTR : opcode := std_logic_vector(to_unsigned(19, OPCODE_BITS));

  --Affects op_is_cmov
  constant OP_VCMV_LTEZ : opcode := std_logic_vector(to_unsigned(24, OPCODE_BITS));
  constant OP_VCMV_GTZ  : opcode := std_logic_vector(to_unsigned(25, OPCODE_BITS));
  constant OP_VCMV_LTZ  : opcode := std_logic_vector(to_unsigned(26, OPCODE_BITS));
  constant OP_VCMV_GTEZ : opcode := std_logic_vector(to_unsigned(27, OPCODE_BITS));
  constant OP_VCMV_Z    : opcode := std_logic_vector(to_unsigned(28, OPCODE_BITS));
  constant OP_VCMV_NZ   : opcode := std_logic_vector(to_unsigned(29, OPCODE_BITS));

  --Affects op_is_addc_subb, op_is_absv
  constant OP_VABSDIFF : opcode := std_logic_vector(to_unsigned(31, OPCODE_BITS));

  --Affects op_is_custom
  constant OP_VCUSTOM0  : opcode := std_logic_vector(to_unsigned(48, OPCODE_BITS));
  constant OP_VCUSTOM1  : opcode := std_logic_vector(to_unsigned(49, OPCODE_BITS));
  constant OP_VCUSTOM2  : opcode := std_logic_vector(to_unsigned(50, OPCODE_BITS));
  constant OP_VCUSTOM3  : opcode := std_logic_vector(to_unsigned(51, OPCODE_BITS));
  constant OP_VCUSTOM4  : opcode := std_logic_vector(to_unsigned(52, OPCODE_BITS));
  constant OP_VCUSTOM5  : opcode := std_logic_vector(to_unsigned(53, OPCODE_BITS));
  constant OP_VCUSTOM6  : opcode := std_logic_vector(to_unsigned(54, OPCODE_BITS));
  constant OP_VCUSTOM7  : opcode := std_logic_vector(to_unsigned(55, OPCODE_BITS));
  constant OP_VCUSTOM8  : opcode := std_logic_vector(to_unsigned(56, OPCODE_BITS));
  constant OP_VCUSTOM9  : opcode := std_logic_vector(to_unsigned(57, OPCODE_BITS));
  constant OP_VCUSTOM10 : opcode := std_logic_vector(to_unsigned(58, OPCODE_BITS));
  constant OP_VCUSTOM11 : opcode := std_logic_vector(to_unsigned(59, OPCODE_BITS));
  constant OP_VCUSTOM12 : opcode := std_logic_vector(to_unsigned(60, OPCODE_BITS));
  constant OP_VCUSTOM13 : opcode := std_logic_vector(to_unsigned(61, OPCODE_BITS));
  constant OP_VCUSTOM14 : opcode := std_logic_vector(to_unsigned(62, OPCODE_BITS));
  constant OP_VCUSTOM15 : opcode := std_logic_vector(to_unsigned(63, OPCODE_BITS));

  type alu_function_type is (LOGIC, ARITH, CMOV);

  --Depends on OP_DMA_TO_HOST and OP_DMA_TO_VECTOR
  function op_is_dma (
    signal op : opcode)
    return std_logic;

  --Depends on OP_DMA_TO_HOST, OP_DMA_TO_VECTOR, OP_SET_VL
  function op_is_process (
    signal op : opcode)
    return std_logic;

  --Depends on OP_SFTL, OP_SFTR, OP_ROTL, OP_ROTR
  function op_is_shift (
    op : opcode)
    return std_logic;

  --Depends on OP_VCUSTOM*
  function op_is_custom (
    signal op : opcode)
    return std_logic;

  --Depends on OP_VCMV*
  function op_is_cmov (
    signal op : opcode)
    return std_logic;

  --Depends on OP_VCMV*, OP_VADD, OP_VSUB
  function op_alu_function (
    signal op : opcode)
    return alu_function_type;

  --Depends on OP_VMUL, OP_VMULHI, OP_VMULFX
  function op_uses_mul (
    op : opcode)
    return std_logic;

  --Depends on OP_VABSDIFF, OP_VADDC, OP_VSUBB
  function op_is_addc_subb (
    signal op : opcode)
    return std_logic;

  --Depends on OP_VABSDIFF
  function op_is_absv (
    signal op : opcode)
    return std_logic;

  type instruction_pipeline_type is array (natural range <>) of instruction_type;
  type addr_pipeline_type is array (natural range <>) of std_logic_vector(31 downto 0);

end package;

package body isa_pkg is

  --Depends on OP_DMA_TO_HOST and OP_DMA_TO_VECTOR
  function op_is_dma (
    signal op : opcode)
    return std_logic is
    variable is_dma : std_logic;
  begin
    is_dma := '0';
    if op(OPCODE_BITS-1 downto 1) = OP_DMA_TO_HOST(OPCODE_BITS-1 downto 1) then
      is_dma := '1';
    end if;
    return is_dma;
  end op_is_dma;

  --Depends on OP_DMA_TO_HOST, OP_DMA_TO_VECTOR, OP_SET_VL
  function op_is_process (
    signal op : opcode)
    return std_logic is
    variable is_process : std_logic;
  begin
    is_process := '1';
    if op(OPCODE_BITS-1 downto 2) = OP_DMA_TO_HOST(OPCODE_BITS-1 downto 2) then
      is_process := '0';
    end if;
    return is_process;
  end op_is_process;

  --Depends on OP_SFTL, OP_SFTR, OP_ROTL, OP_ROTR
  function op_is_shift (
    op : opcode)
    return std_logic is
    variable is_shift : std_logic;
  begin
    is_shift := '0';
    if op(OPCODE_BITS-1 downto 2) = OP_VSHL(OPCODE_BITS-1 downto 2) then
      is_shift := '1';
    end if;
    return is_shift;
  end op_is_shift;

  --Depends on OP_VCUSTOM*
  function op_is_custom (
    signal op : opcode)
    return std_logic is
    variable is_custom : std_logic;
  begin
    is_custom := '0';
    if op(OPCODE_BITS-1 downto 4) = OP_VCUSTOM0(OPCODE_BITS-1 downto 4) then
      is_custom := '1';
    end if;
    return is_custom;
  end op_is_custom;

  --Depends on OP_VCMV*
  function op_is_cmov (
    signal op : opcode)
    return std_logic is
    variable is_cmov : std_logic;
  begin
    is_cmov := '0';
    if (op(OPCODE_BITS-1 downto 2) = OP_VCMV_LTEZ(OPCODE_BITS-1 downto 2) or
        op(OPCODE_BITS-1 downto 1) = OP_VCMV_Z(OPCODE_BITS-1 downto 1)) then
      is_cmov := '1';
    end if;

    return is_cmov;
  end op_is_cmov;

--Depends on OP_VCMV*, OP_VADD, OP_VSUB, OP_ABSDIFF
  function op_alu_function (
    signal op : opcode)
    return alu_function_type is
    variable alu_function : alu_function_type;
  begin
    alu_function := LOGIC;
    if op = OP_VABSDIFF then
      alu_function := ARITH;
    elsif op(OPCODE_BITS-1 downto 3) = OP_VCMV_LTEZ(OPCODE_BITS-1 downto 3) then
      alu_function := CMOV;
    elsif op(OPCODE_ARITH_BIT) = '1' then
      alu_function := ARITH;
    end if;
    return alu_function;
  end op_alu_function;

--Depends on OP_VMUL, OP_VMULHI, OP_VMULFXP
  function op_uses_mul (
    op : opcode)
    return std_logic is
    variable uses_mul : std_logic;
  begin
    uses_mul := '0';
    if op(OPCODE_BITS-1 downto 2) = OP_VMUL(OPCODE_BITS-1 downto 2) or op_is_shift(op) = '1' then
      uses_mul := '1';
    end if;
    return uses_mul;
  end op_uses_mul;

--Depends on OP_VABSDIFF, OP_VADDC, OP_VSUBB
  function op_is_addc_subb (
    signal op : opcode)
    return std_logic is
    variable is_addc_subb : std_logic;
  begin
    is_addc_subb := '0';
    if op = OP_VABSDIFF then
      is_addc_subb := '0';
    else
      is_addc_subb := op(1);
    end if;
    return is_addc_subb;
  end op_is_addc_subb;

--Depends on OP_VABSDIFF
  function op_is_absv (
    signal op : opcode)
    return std_logic is
    variable is_absv : std_logic;
  begin
    is_absv := '0';
    if op = OP_VABSDIFF then
      is_absv := '1';
    end if;
    return is_absv;
  end op_is_absv;


end isa_pkg;
