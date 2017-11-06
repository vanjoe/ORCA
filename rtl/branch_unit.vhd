library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
use work.constants_pkg.all;
--use IEEE.std_logic_arith.all;

entity branch_unit is
  generic (
    REGISTER_SIZE       : integer;
    SIGN_EXTENSION_SIZE : integer
    );
  port (
    clk                      : in     std_logic;
    stall                    : in     std_logic;
    valid                    : in     std_logic;
    reset                    : in     std_logic;
    rs1_data                 : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data                 : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_current               : in     unsigned(REGISTER_SIZE-1 downto 0);
    instr                    : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension           : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    less_than                : in     std_logic;
    --unconditional jumps store return address in rd, output return address
    -- on data_out lines
    data_out                 : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_enable              : out    std_logic;
    to_pc_correction_data    : out    unsigned(REGISTER_SIZE-1 downto 0);
    to_pc_correction_valid   : buffer std_logic;
    from_pc_correction_ready : in     std_logic
    );
end entity branch_unit;


architecture rtl of branch_unit is
  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

  --these are one bit larget than a register
  signal op1      : signed(REGISTER_SIZE downto 0);
  signal op2      : signed(REGISTER_SIZE downto 0);
  signal sub      : signed(REGISTER_SIZE downto 0);
  signal msb_mask : std_logic;

  signal jal_imm        : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_imm       : unsigned(REGISTER_SIZE-1 downto 0);
  signal b_imm          : unsigned(REGISTER_SIZE-1 downto 0);
  signal branch_target  : unsigned(REGISTER_SIZE-1 downto 0);
  signal nbranch_target : unsigned(REGISTER_SIZE-1 downto 0);
  signal jalr_target    : unsigned(REGISTER_SIZE-1 downto 0);
  signal jal_target     : unsigned(REGISTER_SIZE-1 downto 0);
  signal target_pc      : unsigned(REGISTER_SIZE-1 downto 0);

  signal leq_flg : std_logic;
  signal eq_flg  : std_logic;

  signal take_if_branch : std_logic;

  alias func3  : std_logic_vector(2 downto 0) is instr(INSTR_FUNC3'range);
  alias opcode : std_logic_vector(6 downto 0) is instr(6 downto 0);

  signal is_jal_op  : std_logic;
  signal is_jalr_op : std_logic;
  signal is_br_op   : std_logic;
begin  -- architecture
  with func3 select
    msb_mask <=
    '0' when BLTU_OP,
    '0' when BGEU_OP,
    '1' when others;

  op1 <= signed((msb_mask and rs1_data(rs1_data'left)) & rs1_data);
  op2 <= signed((msb_mask and rs2_data(rs2_data'left)) & rs2_data);
  sub <= op1 - op2;

  eq_flg  <= '1' when op1 = op2 else '0';
  leq_flg <= sub(sub'left);

  with func3 select
    take_if_branch <=
    eq_flg                 when beq_OP,
    not eq_flg             when bne_OP,
    leq_flg and not eq_flg when blt_OP,
    not leq_flg or eq_flg  when bge_OP,
    leq_flg and not eq_flg when bltu_OP,
    not leq_flg or eq_flg  when bgeu_OP,
    '0'                    when others;

  b_imm <= unsigned(sign_extension(REGISTER_SIZE-13 downto 0) &
                    instr(7) & instr(30 downto 25) &instr(11 downto 8) & "0");

  jalr_imm <= unsigned(sign_extension(REGISTER_SIZE-12-1 downto 0) &
                       instr(31 downto 21) & "0");
  jal_imm <= unsigned(RESIZE(signed(instr(31) & instr(19 downto 12) & instr(20) &
                                    instr(30 downto 21)&"0"), REGISTER_SIZE));

  --With a real branch predictor we'll need to calculate the branch target
  --depending on whether or not the branch is taken
  branch_target <= b_imm + pc_current;

  nbranch_target <= to_unsigned(4, REGISTER_SIZE) + pc_current;
  jalr_target    <= jalr_imm + unsigned(rs1_data);
  jal_target     <= jal_imm + pc_current;

  with opcode select
    target_pc <=
    jalr_target    when JALR_OP,
    jal_target     when JAL_OP,
    branch_target  when BRANCH_OP,
    nbranch_target when others;


  is_jal_op  <= '1' when opcode = JAL_OP    else '0';
  is_jalr_op <= '1' when opcode = JALR_OP   else '0';
  is_br_op   <= '1' when opcode = BRANCH_OP else '0';

  process(clk)
  begin
    if rising_edge(clk) then
      data_enable <= '0';
      if from_pc_correction_ready = '1' then
        to_pc_correction_valid <= '0';
      end if;

      if stall = '0' then
        data_out    <= std_logic_vector(nbranch_target);
        data_enable <= valid and (is_jal_op or is_jalr_op);

        if valid = '1' then
          to_pc_correction_data <= target_pc;

          --With a real branch predictor we'll need to check the fetched next PC vs. the
          --correct next PC (this uses the fact that any taken branch or jump will be a
          --mispredict with no predictor).
          if (take_if_branch = '1' and is_br_op = '1') or is_jal_op = '1' or is_jalr_op = '1' then
            to_pc_correction_valid <= '1';
          end if;
        end if;
      end if;

      if reset = '1' then
        data_enable            <= '0';
        to_pc_correction_valid <= '0';
      end if;
    end if;
  end process;

end architecture;
