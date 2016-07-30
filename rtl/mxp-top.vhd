library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;


entity mxp_top is
  generic(
    REGISTER_SIZE    : natural;
    INSTRUCTION_SIZE : natural;
    SLAVE_DATA_WIDTH : natural := 32);
  port(
    clk            : in std_logic;
    scratchpad_clk : in std_logic;

    reset         : in     std_logic;
    instruction   : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_instr   : in     std_logic;
    rs1_data      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_running : buffer std_logic;

    slave_address  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    slave_read_en  : in  std_logic;
    slave_write_en : in  std_logic;
    slave_byte_en  : in  std_logic_vector(SLAVE_DATA_WIDTH/8 -1 downto 0);
    slave_data_in  : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_data_out : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_wait     : out std_logic;

    mxp_data1  : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    mxp_data2  : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    mxp_enable : buffer std_logic;
    mxp_result : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    alu_stall  : in     std_logic
    );
end entity;

architecture rtl of mxp_top is

  component ram_4port is
    generic(
      MEM_DEPTH : natural;
      MEM_WIDTH : natural);
    port(
      clk            : in  std_logic;
      scratchpad_clk : in  std_logic;
      reset          : in  std_logic;
      stall_012      : out std_logic;
      stall_3        : out std_logic;
      --read source A
      raddr0         : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      ren0           : in  std_logic;
      data_out0      : out std_logic_vector(MEM_WIDTH-1 downto 0);
      --read source B
      raddr1         : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      ren1           : in  std_logic;
      data_out1      : out std_logic_vector(MEM_WIDTH-1 downto 0);
      --write dest
      waddr2         : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      byte_en2       : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      wen2           : in  std_logic;
      data_in2       : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      --external slave port
      rwaddr3        : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      wen3           : in  std_logic;
      ren3           : in  std_logic;   --cannot be asserted same cycle as wen3
      byte_en3       : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      data_in3       : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      data_out3      : out std_logic_vector(MEM_WIDTH-1 downto 0));
  end component;

  constant POINTER_INCREMENT : natural                      := 4;
  constant SP_SIZE           : natural                      := 1024;
  constant CUSTOM0           : std_logic_vector(6 downto 0) := "0101011";

  alias is_prefix : std_logic is instruction(27);
  alias major_op  : std_logic_vector(6 downto 0) is instruction(6 downto 0);
  --prefix bit fields
  alias dsz       : std_logic_vector(1 downto 0) is instruction(14 downto 13);
  alias asz       : std_logic_vector(1 downto 0) is instruction(12 downto 11);
  alias bsz       : std_logic_vector(1 downto 0) is instruction(10 downto 9);
  alias sync      : std_logic is instruction(8);

  --vinstr bit fields
  alias sign_a    : std_logic is instruction(31);
  alias func_bit4 : std_logic is instruction(30);
  alias sign_b    : std_logic is instruction(29);
  alias mxp_instr : std_logic is instruction(28);
  alias acc       : std_logic is instruction(26);
  alias func_bit3 : std_logic is instruction(25);
  alias func      : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias srca_v    : std_logic is instruction(11);
  alias srcb_v    : std_logic is instruction(10);
  alias dim       : std_logic_vector(1 downto 0) is instruction(9 downto 8);
  alias sign_d    : std_logic is instruction(7);


  signal srca_ptr     : unsigned(REGISTER_SIZE-1 downto 0);
  signal srcb_ptr     : unsigned(REGISTER_SIZE-1 downto 0);
  signal dest_ptr     : unsigned(REGISTER_SIZE-1 downto 0);
  signal waddr        : unsigned(REGISTER_SIZE-1 downto 0);
  signal vlen         : unsigned(REGISTER_SIZE-1 downto 0);
  signal srca_ptr_reg : unsigned(REGISTER_SIZE-1 downto 0);
  signal srcb_ptr_reg : unsigned(REGISTER_SIZE-1 downto 0);
  signal dest_ptr_reg : unsigned(REGISTER_SIZE-1 downto 0);
  signal vlen_reg     : unsigned(REGISTER_SIZE-1 downto 0);

  signal scalar_value : unsigned(REGISTER_SIZE-1 downto 0);

  signal srca_data      : unsigned(REGISTER_SIZE-1 downto 0);
  signal srcb_data      : unsigned(REGISTER_SIZE-1 downto 0);
  signal srca_data_read : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal srcb_data_read : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal dest_data      : unsigned(REGISTER_SIZE-1 downto 0);
  signal enum_count     : unsigned(REGISTER_SIZE-1 downto 0);
  signal alu_result     : unsigned(REGISTER_SIZE-1 downto 0);
  signal src_data_ready : std_logic;
  signal rd_stall       : std_logic;
  signal data_valid     : std_logic;
  signal rd_en          : std_logic;
  signal done           : std_logic;
  signal first_cycle    : std_logic;
  signal write_enable   : std_logic;

  signal valid_mxp_isntr : std_logic;

  signal func5          : std_logic_vector(4 downto 0);
  constant FUNC_VADD    : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VSUB    : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VSLL    : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VSLT    : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VSLTU   : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VSXOR   : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VSRA    : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VSRL    : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VOR     : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VAND    : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VMUL    : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VMULH   : std_logic_vector(4 downto 0) := "00000";
  constant FUNC_VCMV_NZ : std_logic_vector(4 downto 0) := "00000";

begin
  func5 <= func_bit4 & func_bit3 & func;

  valid_mxp_isntr <= '1' when valid_instr = '1' and major_op = CUSTOM0 else '0';
  --instruction parsing process
  address_gen : process(clk)
  begin
    if rising_edge(clk) then

      srca_ptr_reg <= srca_ptr + POINTER_INCREMENT;
      srcb_ptr_reg <= srcb_ptr + POINTER_INCREMENT;
      dest_ptr_reg <= dest_ptr + POINTER_INCREMENT;


      if valid_mxp_isntr = '1' then
        if is_prefix = '1' then
          first_cycle  <= '1';
          scalar_value <= unsigned(rs1_data);
          enum_count   <= to_unsigned(0, enum_count'length);
        else
          first_cycle <= '0';
          enum_count  <= enum_count +1;
          if vlen /= 0 then
            vlen_reg <= vlen - 1;
          end if;
        end if;
      end if;
      if reset = '1' then
        first_cycle <= '0';
        vlen_reg    <= (others => '0');
      end if;
    end if;

  end process;
  instr_running <= '1'                when vlen /= 0         else '0';
  srca_ptr      <= unsigned(rs1_data) when is_prefix = '1'   else srca_ptr_reg;
  srcb_ptr      <= unsigned(rs2_data) when is_prefix = '1'   else srcb_ptr_reg;
  dest_ptr      <= unsigned(rs1_data) when first_cycle = '1' else dest_ptr_reg;
  vlen          <= unsigned(rs2_data) when first_cycle = '1' else vlen_reg;

  srca_data <= unsigned(srca_data_read) when srca_v = '1' else scalar_value;
  srcb_data <= unsigned(srcb_data_read) when srcb_v = '1' else enum_count;

  rd_en      <= '1' when (is_prefix and valid_mxp_isntr) = '1' or vlen > 1 else '0';
  mxp_data1  <= std_logic_vector(srca_data);
  mxp_data2  <= std_logic_vector(srcb_data);
  mxp_enable <= data_valid;
  alu_result <= unsigned(mxp_result);

  alu_proc : process(clk)
  begin
    if rising_edge(clk) then
      data_valid   <= rd_en;
      waddr        <= dest_ptr;
      write_enable <= data_valid;
    end if;
  end process;


  scratchpad_memory : component ram_4port
    generic map (
      MEM_WIDTH => 32,
      MEM_DEPTH => SP_SIZE)
    port map (
      clk            => clk,
      scratchpad_clk => scratchpad_clk,
      reset          => reset,
      stall_012      => rd_stall,
      stall_3        => slave_wait,
      raddr0         => std_logic_vector(srca_ptr(log2(SP_SIZE)-1+2 downto 2)),
      ren0           => rd_en,
      data_out0      => srca_data_read,
      raddr1         => std_logic_vector(srcb_ptr(log2(SP_SIZE)-1+2 downto 2)),
      ren1           => rd_en,
      data_out1      => srcb_data_read,

      waddr2    => std_logic_vector(waddr(log2(SP_SIZE)-1+2 downto 2)),
      byte_en2  => (others => '1'),
      wen2      => write_enable,
      data_in2  => std_logic_vector(alu_result),
      rwaddr3   => slave_address(log2(SP_SIZE)-1+2 downto 2),
      ren3      => slave_read_en,
      wen3      => slave_write_en,
      byte_en3  => slave_byte_en,
      data_out3 => slave_data_out,
      data_in3  => slave_data_in);



end architecture;
