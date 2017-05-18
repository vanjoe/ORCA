
library IEEE;
use IEEE.STD_LOGIC_1164.all;

library work;
use work.utils.all;

entity true_dual_port_ram_single_clock is

  generic
    (
      DATA_WIDTH : natural := 8;
      ADDR_WIDTH : natural := 6
      );

  port
    (
      clk    : in  std_logic;
      addr_a : in  natural range 0 to 2**ADDR_WIDTH - 1;
      addr_b : in  natural range 0 to 2**ADDR_WIDTH - 1;
      data_a : in  std_logic_vector((DATA_WIDTH-1) downto 0);
      data_b : in  std_logic_vector((DATA_WIDTH-1) downto 0);
      we_a   : in  std_logic := '1';
      we_b   : in  std_logic := '1';
      q_a    : out std_logic_vector((DATA_WIDTH -1) downto 0);
      q_b    : out std_logic_vector((DATA_WIDTH -1) downto 0)
      );

end true_dual_port_ram_single_clock;

architecture rtl of true_dual_port_ram_single_clock is

  -- Build a 2-D array type for the RAM
  subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
  type memory_t is array(0 to 2**ADDR_WIDTH-1) of word_t;

  -- Declare the RAM
  shared variable ram : memory_t;
  signal reg_a, reg_b : std_logic_vector(DATA_WIDTH-1 downto 0);
begin


  -- Port A
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(we_a = '1') then
        ram(addr_a) := data_a;
      end if;

      reg_a <= ram(addr_a);
      q_a   <= reg_a;
    end if;
  end process;

  -- Port B
  process(clk)
  begin
    if(rising_edge(clk)) then
      if(we_b = '1') then
        ram(addr_b) := data_b;
      end if;
      reg_b <= ram(addr_b);
      q_b   <= reg_b;
    end if;
  end process;

end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;

entity ram_2port is

  generic (
    MEM_DEPTH : natural := 1024;
    MEM_WIDTH : natural := 32);

  port (
    clk       : in  std_logic;
    byte_en0  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wr_en0    : in  std_logic;
    addr0     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    data_in0  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    data_out0 : out std_logic_vector(MEM_WIDTH-1 downto 0);

    byte_en1  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wr_en1    : in  std_logic;
    addr1     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    data_in1  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    data_out1 : out std_logic_vector(MEM_WIDTH-1 downto 0)

    );

end entity ram_2port;


architecture behav of ram_2port is
  component true_dual_port_ram_single_clock is

    generic
      (
        DATA_WIDTH : natural := 8;
        ADDR_WIDTH : natural := 6
        );

    port
      (
        clk    : in  std_logic;
        addr_a : in  natural range 0 to 2**ADDR_WIDTH - 1;
        addr_b : in  natural range 0 to 2**ADDR_WIDTH - 1;
        data_a : in  std_logic_vector((DATA_WIDTH-1) downto 0);
        data_b : in  std_logic_vector((DATA_WIDTH-1) downto 0);
        we_a   : in  std_logic := '1';
        we_b   : in  std_logic := '1';
        q_a    : out std_logic_vector((DATA_WIDTH -1) downto 0);
        q_b    : out std_logic_vector((DATA_WIDTH -1) downto 0)
        );

  end component;

begin

  -----------------------------------------------------------------------------
  -- I (JDV) had a whole bunch of trouble getting a proper byte enabled
  -- doal ported ram. This solution (having a seperate entity) seems to work
  -- in both modelsim and quartus
  -----------------------------------------------------------------------------
  byte_gen : for byte in byte_en0'range generate
    signal wen0, wen1           : std_logic;
    signal byte_in0, byte_in1   : std_logic_vector(7 downto 0);
    signal byte_out0, byte_out1 : std_logic_vector(7 downto 0);

    signal addr_a, addr_b : natural range 0 to MEM_DEPTH-1;


  begin
    wen0     <= wr_en0 and byte_en0(byte);
    wen1     <= wr_en1 and byte_en0(byte);
    byte_in0 <= data_in0((byte+1)*8-1 downto byte*8);
    byte_in1 <= data_in1((byte+1)*8-1 downto byte*8);

    data_out0((byte+1)*8-1 downto byte*8) <= byte_out0;
    data_out1((byte+1)*8-1 downto byte*8) <= byte_out1;

    addr_a <= to_integer(unsigned(addr0));
    addr_b <= to_integer(unsigned(addr1));

    dpram : component true_dual_port_ram_single_clock
      generic map (
        DATA_WIDTH => 8,
        ADDR_WIDTH => addr0'length)
      port map (
        clk    => clk,
        data_a => byte_in0,
        data_b => byte_in1,
        addr_a => addr_a,
        addr_b => addr_b,
        we_a   => wen0,
        we_b   => wen1,
        q_a    => byte_out0,
        q_b    => byte_out1);
  end generate byte_gen;
end architecture behav;



library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;

entity ram_4port is
  generic(
    MEM_DEPTH : natural;
    MEM_WIDTH : natural;
    FAMILY    : string := "ALTERA");
  port(
    clk            : in  std_logic;
    scratchpad_clk : in  std_logic;
    reset          : in  std_logic;
                                        --read source A
    raddr0         : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    ren0           : in  std_logic;
    scalar_value   : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    scalar_enable  : in  std_logic;
    data_out0      : out std_logic_vector(MEM_WIDTH-1 downto 0);

                                        --read source B
    raddr1      : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    ren1        : in  std_logic;
    enum_value  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    enum_enable : in  std_logic;
    data_out1   : out std_logic_vector(MEM_WIDTH-1 downto 0);
    ack01       : out std_logic;
    --write dest
    waddr2      : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    byte_en2    : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wen2        : in  std_logic;
    data_in2    : in  std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --external slave port
    rwaddr3     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    wen3        : in  std_logic;
    ren3        : in  std_logic;        --cannot be asserted same cycle as wen3
    byte_en3    : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    data_in3    : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    ack3        : out std_logic;
    data_out3   : out std_logic_vector(MEM_WIDTH-1 downto 0));
end entity;

architecture rtl of ram_4port is

  component ram_2port is
    generic (
      MEM_DEPTH : natural := 1024;
      MEM_WIDTH : natural := 32
      );
    port (

      clk       : in  std_logic;
      byte_en0  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      wr_en0    : in  std_logic;
      addr0     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      data_in0  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      data_out0 : out std_logic_vector(MEM_WIDTH-1 downto 0);

      byte_en1  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      wr_en1    : in  std_logic;
      addr1     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      data_in1  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      data_out1 : out std_logic_vector(MEM_WIDTH-1 downto 0));
  end component;


  signal actual_byte_en0  : std_logic_vector(MEM_WIDTH/8-1 downto 0);
  signal actual_wr_en0    : std_logic;
  signal actual_addr0     : std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
  signal actual_data_in0  : std_logic_vector(MEM_WIDTH-1 downto 0);
  signal actual_data_out0 : std_logic_vector(MEM_WIDTH-1 downto 0);

  signal actual_byte_en1  : std_logic_vector(MEM_WIDTH/8-1 downto 0);
  signal actual_wr_en1    : std_logic;
  signal actual_addr1     : std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
  signal actual_data_in1  : std_logic_vector(MEM_WIDTH-1 downto 0);
  signal actual_data_out1 : std_logic_vector(MEM_WIDTH-1 downto 0);

  type cycle_count_t is (SLAVE_WRITE_CYCLE,  --External Slave and lve write
                         READ_CYCLE);        --both lve source reads

  signal cycle_count      : cycle_count_t;
  signal last_cycle_count : cycle_count_t;

  signal sp_follow : std_logic;

  signal byte_en3_latch : std_logic_vector(byte_en3'range);
  signal wen3_latch     : std_logic;
  signal rwaddr3_latch  : std_logic_vector(rwaddr3'range);
  signal data_in3_latch : std_logic_vector(data_in3'range);

  --pipeline bits
  signal read3_ack0 : std_logic;
  signal read3_ack1 : std_logic;
  signal read_ack : std_logic;
begin  -- architecture rtl

  process(clk)
  begin
    if rising_edge(clk) then
      ack3 <= '0';
      if wen3 = '1' or read3_ack1 = '1' then
        ack3 <= '1';
      end if;
      read3_ack0 <= ren3;
      read3_ack1 <= read3_ack0;
      read_ack <= ren0 ;
    end if;
  end process;

  process(scratchpad_clk)
  begin
    if rising_edge(scratchpad_clk) then

      sp_follow <= not sp_follow;
      if reset = '1' then
        sp_follow <= '0';
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      byte_en3_latch <= byte_en3;
      wen3_latch     <= wen3;
      rwaddr3_latch  <= rwaddr3;
      data_in3_latch <= data_in3;
    end if;
  end process;

  cycle_count <= SLAVE_WRITE_CYCLE when sp_follow = '0' else READ_CYCLE;

  --Double clock select.
  actual_byte_en0 <= byte_en2       when cycle_count = SLAVE_WRITE_CYCLE else (others => '-');
  actual_byte_en1 <= byte_en3_latch when cycle_count = SLAVE_WRITE_CYCLE else (others => '-');

  actual_wr_en0 <= wen2       when cycle_count = SLAVE_WRITE_CYCLE else '0';
  actual_wr_en1 <= wen3_latch when cycle_count = SLAVE_WRITE_CYCLE else '0';

  actual_addr0 <= waddr2        when cycle_count = SLAVE_WRITE_CYCLE else raddr0;
  actual_addr1 <= rwaddr3_latch when cycle_count = SLAVE_WRITE_CYCLE else raddr1;

  actual_data_in0 <= data_in2       when cycle_count = SLAVE_WRITE_CYCLE else (others => '-');
  actual_data_in1 <= data_in3_latch when cycle_count = SLAVE_WRITE_CYCLE else (others => '-');

  --save values for entire 1x clock
  process(scratchpad_clk)
  begin
    if rising_edge(scratchpad_clk) then
      if cycle_count = SLAVE_WRITE_CYCLE and read3_ack1 = '1' then
        data_out3 <= actual_data_out1;
      end if;
      if cycle_count = READ_CYCLE then
        data_out0 <= actual_data_out0;
        data_out1 <= actual_data_out1;
        if scalar_enable = '1' then
          data_out0 <= scalar_value;
        end if;
        if enum_enable = '1' then
          data_out1 <= enum_value;
        end if;

        ack01 <= read_ack;
      end if;

    end if;
  end process;

  actual_ram : component ram_2port
    generic map (
      MEM_DEPTH => MEM_DEPTH,
      MEM_WIDTH => MEM_WIDTH)
    port map(
      clk       => scratchpad_clk,
      byte_en0  => actual_byte_en0,
      wr_en0    => actual_wr_en0,
      addr0     => actual_addr0,
      data_in0  => actual_data_in0,
      data_out0 => actual_data_out0,

      byte_en1  => actual_byte_en1,
      wr_en1    => actual_wr_en1,
      addr1     => actual_addr1,
      data_in1  => actual_data_in1,
      data_out1 => actual_data_out1);


end architecture rtl;
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;
use work.constants_pkg.all;
use work.constants_pkg.all;
--use IEEE.std_logic_arith.all;

entity arithmetic_unit is
  generic (
    REGISTER_SIZE       : integer;
    SIGN_EXTENSION_SIZE : integer;
    MULTIPLY_ENABLE     : boolean;
    DIVIDE_ENABLE       : boolean;
    SHIFTER_MAX_CYCLES  : natural;
    FAMILY              : string := "ALTERA");

  port (
    clk                : in  std_logic;
    valid_instr        : in  std_logic;
    stall_to_alu       : in  std_logic;
    stall_from_execute : in  std_logic;
    rs1_data           : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data           : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction        : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension     : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    program_counter    : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_out           : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_out_valid     : out std_logic;
    less_than          : out std_logic;
    stall_from_alu     : out std_logic;

    lve_data1        : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_data2        : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_source_valid : in std_logic
    );

end entity arithmetic_unit;

architecture rtl of arithmetic_unit is

  constant SHIFTER_USE_MULTIPLIER : boolean := MULTIPLY_ENABLE;
  constant SHIFT_SC               : natural := conditional(SHIFTER_USE_MULTIPLIER, 0, SHIFTER_MAX_CYCLES);

  --op codes

  constant UP_IMM_IMMEDIATE_SIZE : integer := 20;

  alias func3  : std_logic_vector(2 downto 0) is instruction(INSTR_FUNC3'range);
  alias func7  : std_logic_vector(6 downto 0) is instruction(31 downto 25);
  alias opcode : std_logic_vector(6 downto 0) is instruction(6 downto 0);

  signal data1       : unsigned(REGISTER_SIZE-1 downto 0);
  signal data2       : unsigned(REGISTER_SIZE-1 downto 0);
  signal data_result : unsigned(REGISTER_SIZE-1 downto 0);

  signal data_in1     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_in2     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal source_valid : std_logic;

  signal shift_amt            : unsigned(log2(REGISTER_SIZE)-1 downto 0);
  signal shift_value          : signed(REGISTER_SIZE downto 0);
  signal lshifted_result      : unsigned(REGISTER_SIZE-1 downto 0);
  signal rshifted_result      : unsigned(REGISTER_SIZE-1 downto 0);
  signal shifted_result_valid : std_logic;
  signal sub                  : signed(REGISTER_SIZE downto 0);
  signal sub_valid            : std_logic;
  signal slt_result           : unsigned(REGISTER_SIZE-1 downto 0);
  signal slt_result_valid     : std_logic;

  signal upp_imm_sel      : std_logic;
  signal upper_immediate1 : signed(REGISTER_SIZE-1 downto 0);
  signal upper_immediate  : signed(REGISTER_SIZE-1 downto 0);

  signal mul_srca          : signed(REGISTER_SIZE downto 0);
  signal mul_srcb          : signed(REGISTER_SIZE downto 0);
  signal mul_src_shift_amt : unsigned(log2(REGISTER_SIZE)-1 downto 0);
  signal mul_src_valid     : std_logic;

  signal mul_dest           : signed((REGISTER_SIZE+1)*2-1 downto 0);
  signal mul_dest_shift_amt : unsigned(log2(REGISTER_SIZE)-1 downto 0);
  signal mul_dest_valid     : std_logic;

  signal mul_stall : std_logic;

  signal div_op1          : unsigned(REGISTER_SIZE-1 downto 0);
  signal div_op2          : unsigned(REGISTER_SIZE-1 downto 0);
  signal div_result       : signed(REGISTER_SIZE-1 downto 0);
  signal div_result_valid : std_logic;
  signal rem_result       : signed(REGISTER_SIZE-1 downto 0);
  signal quotient         : unsigned(REGISTER_SIZE-1 downto 0);
  signal remainder        : unsigned(REGISTER_SIZE-1 downto 0);

                                        --min signed value
  signal min_s : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal zero : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal neg1 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal div_neg     : std_logic;
  signal div_neg_op1 : std_logic;
  signal div_neg_op2 : std_logic;
  signal div_stall   : std_logic;

  signal div_enable : std_logic;

  signal sh_stall  : std_logic;
  signal sh_enable : std_logic;

  component shifter is
    generic (
      REGISTER_SIZE : natural;
      SINGLE_CYCLE  : natural
      );
    port(
      clk                  : in  std_logic;
      shift_amt            : in  unsigned(log2(REGISTER_SIZE)-1 downto 0);
      shift_value          : in  signed(REGISTER_SIZE downto 0);
      lshifted_result      : out unsigned(REGISTER_SIZE-1 downto 0);
      rshifted_result      : out unsigned(REGISTER_SIZE-1 downto 0);
      shifted_result_valid : out std_logic;
      sh_enable            : in  std_logic);
  end component shifter;

  component divider is
    generic (
      REGISTER_SIZE : natural
      );
    port(
      clk          : in std_logic;
      div_enable   : in std_logic;
      unsigned_div : in std_logic;
      rs1_data     : in unsigned(REGISTER_SIZE-1 downto 0);
      rs2_data     : in unsigned(REGISTER_SIZE-1 downto 0);

      quotient         : out unsigned(REGISTER_SIZE-1 downto 0);
      remainder        : out unsigned(REGISTER_SIZE-1 downto 0);
      div_result_valid : out std_logic
      );
  end component;

  component operand_creation is
    generic (
      REGISTER_SIZE          : natural;
      SIGN_EXTENSION_SIZE    : natural;
      INSTRUCTION_SIZE       : natural;
      SHIFTER_USE_MULTIPLIER : boolean
      );
    port(
      rs1_data          : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data          : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      source_valid      : in     std_logic;
      instruction       : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension    : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      data1             : buffer unsigned(REGISTER_SIZE-1 downto 0);
      data2             : buffer unsigned(REGISTER_SIZE-1 downto 0);
      sub               : out    signed(REGISTER_SIZE downto 0);
      sub_valid         : out    std_logic;
      shift_amt         : buffer unsigned(log2(REGISTER_SIZE)-1 downto 0);
      shift_value       : buffer signed(REGISTER_SIZE downto 0);
      mul_srca          : out    signed(REGISTER_SIZE downto 0);
      mul_srcb          : out    signed(REGISTER_SIZE downto 0);
      mul_src_shift_amt : out    unsigned(log2(REGISTER_SIZE)-1 downto 0);
      mul_src_valid     : out    std_logic
      );
  end component;
  signal func7_shift : boolean;
begin  -- architecture rtl

  oc : component operand_creation
    generic map (
      REGISTER_SIZE          => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE    => SIGN_EXTENSION_SIZE,
      SHIFTER_USE_MULTIPLIER => SHIFTER_USE_MULTIPLIER,
      INSTRUCTION_SIZE       => INSTRUCTION_SIZE)
    port map (
      rs1_data          => data_in1,
      rs2_data          => data_in2,
      source_valid      => source_valid,
      instruction       => instruction,
      sign_extension    => sign_extension,
      data1             => data1,
      data2             => data2,
      sub               => sub,
      sub_valid         => sub_valid,
      shift_amt         => shift_amt,
      shift_value       => shift_value,
      mul_srca          => mul_srca,
      mul_srcb          => mul_srcb,
      mul_src_shift_amt => mul_src_shift_amt,
      mul_src_valid     => mul_src_valid
      );

--  data_in1 <= lve_data1 when lve_source_valid = '1' else rs1_data;
--  data_in2 <= lve_data2 when lve_source_valid = '1' else rs2_data;

  data_in1 <= rs1_data;
  data_in2 <= rs2_data;

  source_valid <= lve_source_valid when opcode = LVE_OP else
                  not stall_to_alu and valid_instr;

  func7_shift <= func7 = "0000000" or func7 = "0100000";
  sh_enable   <= valid_instr and source_valid when ((opcode = ALU_OP and func7_shift) or (opcode = ALUI_OP) or (opcode = LVE_OP and lve_source_valid = '1')) and (func3 = "001" or func3 = "101") else '0';
  sh_stall    <= (not shifted_result_valid)   when sh_enable = '1'                                                                                                                                else '0';

  SH_GEN0 : if SHIFTER_USE_MULTIPLIER generate
    process(clk) is
    begin
      if rising_edge(clk) then
        lshifted_result <= unsigned(mul_dest(REGISTER_SIZE-1 downto 0));
        rshifted_result <= unsigned(mul_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
        if mul_dest_shift_amt = to_unsigned(0, mul_dest_shift_amt'length) then
          rshifted_result <= unsigned(mul_dest(REGISTER_SIZE-1 downto 0));
        end if;
        shifted_result_valid <= mul_dest_valid and sh_enable;
      end if;
    end process;

  end generate SH_GEN0;
  SH_GEN1 : if not SHIFTER_USE_MULTIPLIER generate

    sh : component shifter
      generic map (
        REGiSTER_SIZE => REGISTER_SIZE,
        SINGLE_CYCLE  => SHIFT_SC)
      port map (
        clk                  => clk,
        shift_amt            => shift_amt,
        shift_value          => shift_value,
        lshifted_result      => lshifted_result,
        rshifted_result      => rshifted_result,
        shifted_result_valid => shifted_result_valid,
        sh_enable            => sh_enable
        );

  end generate SH_GEN1;


  less_than        <= sub(sub'left);
--combine slt
  slt_result       <= to_unsigned(1, REGISTER_SIZE) when sub(sub'left) = '1' else to_unsigned(0, REGISTER_SIZE);
  slt_result_valid <= sub_valid;

  upper_immediate(31 downto 12) <= signed(instruction(31 downto 12));
  upper_immediate(11 downto 0)  <= (others => '0');

  alu_proc : process(clk) is
    variable func              : std_logic_vector(2 downto 0);
    variable base_result       : unsigned(REGISTER_SIZE-1 downto 0);
    variable base_result_valid : std_logic;
    variable mul_result        : unsigned(REGISTER_SIZE-1 downto 0);
    variable mul_result_valid  : std_logic;
  begin
    if rising_edge(clk) then
      func := instruction(14 downto 12);

      base_result       := (others => '-');
      base_result_valid := '0';
      case func is
        when ADD_OP =>
          base_result       := unsigned(sub(REGISTER_SIZE-1 downto 0));
          base_result_valid := sub_valid;
        when SLL_OP =>
          base_result       := lshifted_result;
          base_result_valid := shifted_result_valid;
        when SLT_OP =>
          base_result       := slt_result;
          base_result_valid := slt_result_valid;
        when SLTU_OP =>
          base_result       := slt_result;
          base_result_valid := slt_result_valid;
        when XOR_OP =>
          base_result       := data1 xor data2;
          base_result_valid := source_valid;
        when SR_OP =>
          base_result       := rshifted_result;
          base_result_valid := shifted_result_valid;
        when OR_OP =>
          base_result       := data1 or data2;
          base_result_valid := source_valid;
        when AND_OP =>
          base_result       := data1 and data2;
          base_result_valid := source_valid;
        when others =>
          null;
      end case;

      mul_result       := (others => '-');
      mul_result_valid := '0';
      case func is
        when MUL_OP =>
          mul_result       := unsigned(mul_dest(REGISTER_SIZE-1 downto 0));
          mul_result_valid := mul_dest_valid;
        when MULH_OP =>
          mul_result       := unsigned(mul_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
          mul_result_valid := mul_dest_valid;
        when MULHSU_OP =>
          mul_result       := unsigned(mul_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
          mul_result_valid := mul_dest_valid;
        when MULHU_OP =>
          mul_result       := unsigned(mul_dest(REGISTER_SIZE*2-1 downto REGISTER_SIZE));
          mul_result_valid := mul_dest_valid;
        when DIV_OP =>
          mul_result       := unsigned(div_result);
          mul_result_valid := div_result_valid;
        when DIVU_OP =>
          mul_result       := unsigned(div_result);
          mul_result_valid := div_result_valid;
        when REM_OP =>
          mul_result       := unsigned(rem_result);
          mul_result_valid := div_result_valid;
        when REMU_OP =>
          mul_result       := unsigned(rem_result);
          mul_result_valid := div_result_valid;

        when others =>
          null;
      end case;

      data_out_valid <= '0';
      case OPCODE is
        when ALU_OP | LVE_OP =>
          if (func7 = mul_f7 or (instruction(25) = '1' and opcode = LVE_OP))and MULTIPLY_ENABLE then
            data_out       <= std_logic_vector(mul_result);
            data_out_valid <= mul_result_valid;
          else
            data_out       <= std_logic_vector(base_result);
            data_out_valid <= base_result_valid;
          end if;
        when ALUI_OP =>
          data_out       <= std_logic_vector(base_result);
          data_out_valid <= base_result_valid;
        when LUI_OP =>
          data_out       <= std_logic_vector(upper_immediate);
          data_out_valid <= source_valid;
        when AUIPC_OP =>
          data_out       <= std_logic_vector(upper_immediate + signed(program_counter));
          data_out_valid <= source_valid;
        when others =>
          data_out       <= (others => '-');
          data_out_valid <= '0';
      end case;
    end if;  --clock
  end process;

  mul_gen : if MULTIPLY_ENABLE generate
    signal mul_enable : std_logic;

    signal mul_a            : signed(mul_srca'range);
    signal mul_b            : signed(mul_srcb'range);
    signal mul_ab_shift_amt : unsigned(log2(REGISTER_SIZE)-1 downto 0);
    signal mul_ab_valid     : std_logic;
  begin
    mul_enable <= valid_instr and source_valid when ((func7 = mul_f7 and opcode = ALU_OP) or
                                                     (instruction(25) = '1' and opcode = LVE_OP)) and instruction(14) = '0' else '0';
    mul_stall <= mul_enable and (not mul_dest_valid);

    lattice_mul_gen : if FAMILY = "LATTICE" generate
      signal afix : unsigned(mul_a'length-2 downto 0);
      signal bfix : unsigned(mul_b'length-2 downto 0);
      signal abfix : unsigned(mul_a'length-2 downto 0);

      signal mul_a_unsigned : unsigned(mul_a'length-2 downto 0);
      signal mul_b_unsigned : unsigned(mul_b'length-2 downto 0);
      signal mul_dest_unsigned : unsigned((mul_a_unsigned'length+mul_b_unsigned'length)-1 downto 0);
    begin
      afix <= unsigned(mul_a(mul_a'length-2 downto 0)) when mul_b(mul_b'left) = '1' else
              to_unsigned(0, afix'length);
      bfix <= unsigned(mul_b(mul_b'length-2 downto 0)) when mul_a(mul_a'left) = '1' else
              to_unsigned(0, afix'length);

      mul_a_unsigned <= unsigned(mul_a(mul_a'length-2 downto 0));
      mul_b_unsigned <= unsigned(mul_b(mul_b'length-2 downto 0));

      process(clk)
      begin
        if rising_edge(clk) then
          -- The multiplication of the absolute value of the source operands.
          mul_dest_unsigned <= mul_a_unsigned * mul_b_unsigned;
          abfix <= afix + bfix;
        end if;
      end process;

      mul_dest(mul_a_unsigned'length-1 downto 0) <= signed(mul_dest_unsigned(mul_a_unsigned'length-1 downto 0));
      mul_dest(mul_dest_unsigned'left downto mul_a_unsigned'length) <=
        signed(mul_dest_unsigned(mul_dest_unsigned'left downto mul_a_unsigned'length) - abfix);
    end generate lattice_mul_gen;

    default_mul_gen : if FAMILY /= "LATTICE" generate
    begin
      process(clk)
      begin
        if rising_edge(clk) then
          mul_dest <= mul_a * mul_b;
        end if;
      end process;
    end generate default_mul_gen;

    process(clk)
    begin
      if rising_edge(clk) then
        --Register multiplier inputs
        mul_a            <= mul_srca;
        mul_b            <= mul_srcb;
        mul_ab_shift_amt <= mul_src_shift_amt;
        mul_ab_valid     <= mul_src_valid;

        --Register multiplier output
        mul_dest_shift_amt <= mul_ab_shift_amt;
        mul_dest_valid     <= mul_ab_valid;

        --if we don't want to pipeline multiple multiplies (as is the case when we are not using LVE)
        -- then we want to flush the valid signals
        -- Another way of phrasing this is that unless we have an LVE instruction we only want
        -- mul_dest_valid to be high for one cycle
        if stall_from_execute = '0' or (opcode /= LVE_OP and mul_dest_valid = '1') then

          mul_ab_valid   <= '0';
          mul_dest_valid <= '0';
        end if;
      end if;
    end process;
  end generate mul_gen;

  no_mul_gen : if not MULTIPLY_ENABLE generate
    mul_dest_valid     <= '0';
    mul_dest_shift_amt <= (others => '-');
    mul_dest           <= (others => '-');
    mul_stall          <= '0';
  end generate no_mul_gen;

  d_en : if DIVIDE_ENABLE generate
  begin
    div_enable <= '1' when (func7 = mul_f7 and opcode = ALU_OP and instruction(14) = '1') and valid_instr = '1' and source_valid = '1' else '0';
    div : component divider
      generic map (
        REGISTER_SIZE => REGISTER_SIZE)
      port map (
        clk              => clk,
        div_enable       => div_enable,
        unsigned_div     => instruction(12),
        rs1_data         => unsigned(rs1_data),
        rs2_data         => unsigned(rs2_data),
        quotient         => quotient,
        remainder        => remainder,
        div_result_valid => div_result_valid);

    div_result <= signed(quotient);
    rem_result <= signed(remainder);

    div_stall <= div_enable and (not div_result_valid);

  end generate d_en;
  nd_en : if not DIVIDE_ENABLE generate
  begin
    div_stall        <= '0';
    div_result       <= (others => 'X');
    rem_result       <= (others => 'X');
    div_result_valid <= '0';
  end generate;

  stall_from_alu <= div_stall or mul_stall or sh_stall;
end architecture;

-------------------------------------------------------------------------------
-- Shifter
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;


entity shifter is
  generic (
    REGISTER_SIZE : natural;
    SINGLE_CYCLE  : natural
    );
  port(
    clk                  : in  std_logic;
    shift_amt            : in  unsigned(log2(REGISTER_SIZE)-1 downto 0);
    shift_value          : in  signed(REGISTER_SIZE downto 0);
    lshifted_result      : out unsigned(REGISTER_SIZE-1 downto 0);
    rshifted_result      : out unsigned(REGISTER_SIZE-1 downto 0);
    shifted_result_valid : out std_logic;
    sh_enable            : in  std_logic
    );
end entity shifter;

architecture rtl of shifter is

  constant SHIFT_AMT_SIZE : natural := shift_amt'length;
  signal left_tmp         : signed(REGISTER_SIZE downto 0);
  signal right_tmp        : signed(REGISTER_SIZE downto 0);
begin  -- architecture rtl
  assert SINGLE_CYCLE = 1 or SINGLE_CYCLE = 8 or SINGLE_CYCLE = 32 report "Bad SHIFTER_MAX_CYCLES Value" severity failure;

  cycle1 : if SINGLE_CYCLE = 1 generate
    left_tmp             <= SHIFT_LEFT(shift_value, to_integer(shift_amt));
    right_tmp            <= SHIFT_RIGHT(shift_value, to_integer(shift_amt));
    shifted_result_valid <= sh_enable;
  end generate cycle1;

  cycle4N : if SINGLE_CYCLE = 8 generate
    signal left_nxt   : signed(REGISTER_SIZE downto 0);
    signal right_nxt  : signed(REGISTER_SIZE downto 0);
    signal count      : unsigned(SHIFT_AMT_SIZE downto 0);
    signal count_next : unsigned(SHIFT_AMT_SIZE downto 0);
    signal count_sub4 : unsigned(SHIFT_AMT_SIZE downto 0);
    signal shift4     : std_logic;
    type state_t is (IDLE, RUNNING, DONE);
    signal state      : state_t;
  begin
    count_sub4 <= count -4;
    shift4     <= not count_sub4(count_sub4'left);
    count_next <= count_sub4                when shift4 = '1' else count -1;
    left_nxt   <= SHIFT_LEFT(left_tmp, 4)   when shift4 = '1' else SHIFT_LEFT(left_tmp, 1);
    right_nxt  <= SHIFT_RIGHT(right_tmp, 4) when shift4 = '1' else SHIFT_RIGHT(right_tmp, 1);

    process(clk)
    begin
      if rising_edge(clk) then
        shifted_result_valid <= '0';
        if sh_enable = '1' then
          case state is
            when IDLE =>
              left_tmp  <= shift_value;
              right_tmp <= shift_value;
              count     <= unsigned("0"&shift_amt);
              if shift_amt /= 0 then
                state <= RUNNING;
              else
                state                <= IDLE;
                shifted_result_valid <= '1';
              end if;
            when RUNNING =>
              left_tmp  <= left_nxt;
              right_tmp <= right_nxt;
              count     <= count_next;
              if count = 1 or count = 4 then
                shifted_result_valid <= '1';
                state                <= DONE;
              end if;
            when Done =>
              state <= IDLE;
            when others =>
              null;
          end case;
        else
          state <= IDLE;
        end if;
      end if;
    end process;
  end generate cycle4N;

  cycle1N : if SINGLE_CYCLE = 32 generate
    signal left_nxt  : signed(REGISTER_SIZE downto 0);
    signal right_nxt : signed(REGISTER_SIZE downto 0);
    signal count     : signed(SHIFT_AMT_SIZE-1 downto 0);
    type state_t is (IDLE, RUNNING, DONE);
    signal state     : state_t;
  begin
    left_nxt  <= SHIFT_LEFT(left_tmp, 1);
    right_nxt <= SHIFT_RIGHT(right_tmp, 1);

    process(clk)
    begin
      if rising_edge(clk) then
        shifted_result_valid <= '0';
        if sh_enable = '1' then
          case state is
            when IDLE =>
              left_tmp  <= shift_value;
              right_tmp <= shift_value;
              count     <= signed(shift_amt);
              if shift_amt /= 0 then
                state <= RUNNING;
              else
                state                <= IDLE;
                shifted_result_valid <= '1';
              end if;
            when RUNNING =>
              left_tmp  <= left_nxt;
              right_tmp <= right_nxt;
              count     <= count -1;
              if count = 1 then
                shifted_result_valid <= '1';
                state                <= DONE;
              end if;
            when Done =>
              state <= IDLE;
            when others =>
              null;
          end case;
        else
          state <= IDLE;
        end if;
      end if;
    end process;

  end generate cycle1N;

  rshifted_result <= unsigned(right_tmp(REGISTER_SIZE-1 downto 0));
  lshifted_result <= unsigned(left_tmp(REGISTER_SIZE-1 downto 0));

end architecture rtl;



-------------------------------------------------------------------------------
-- Operand Creation
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;


entity operand_creation is
  generic (
    REGISTER_SIZE          : natural;
    INSTRUCTION_SIZE       : natural;
    SIGN_EXTENSION_SIZE    : natural;
    SHIFTER_USE_MULTIPLIER : boolean
    );
  port(
    rs1_data          : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data          : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    source_valid      : in     std_logic;
    instruction       : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension    : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    data1             : buffer unsigned(REGISTER_SIZE-1 downto 0);
    data2             : buffer unsigned(REGISTER_SIZE-1 downto 0);
    sub               : out    signed(REGISTER_SIZE downto 0);
    sub_valid         : out    std_logic;
    shift_amt         : buffer unsigned(log2(REGISTER_SIZE)-1 downto 0);
    shift_value       : buffer signed(REGISTER_SIZE downto 0);
    mul_srca          : out    signed(REGISTER_SIZE downto 0);
    mul_srcb          : out    signed(REGISTER_SIZE downto 0);
    mul_src_shift_amt : out    unsigned(log2(REGISTER_SIZE)-1 downto 0);
    mul_src_valid     : out    std_logic
    );
end entity;

architecture rtl of operand_creation is
  constant MUL_F7 : std_logic_vector(6 downto 0) := "0000001";

  signal is_immediate     : std_logic;
  signal immediate_value  : unsigned(REGISTER_SIZE-1 downto 0);
  signal op1              : signed(REGISTER_SIZE downto 0);
  signal op2              : signed(REGISTER_SIZE downto 0);
  signal shifter_multiply : signed(REGISTER_SIZE downto 0);
  signal m_op1_msk        : std_logic;
  signal m_op2_msk        : std_logic;
  signal m_op1            : signed(REGISTER_SIZE downto 0);
  signal m_op2            : signed(REGISTER_SIZE downto 0);

  signal unsigned_div : std_logic;

  signal op1_msb : std_logic;
  signal op2_msb : std_logic;

  signal is_add : boolean;

  alias func3 : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias func7 : std_logic_vector(6 downto 0) is instruction(31 downto 25);

  constant OP_IMM_IMMEDIATE_SIZE : integer := 12;

begin  -- architecture rtl
  is_immediate <= not instruction(5);
  immediate_value <= unsigned(sign_extension(REGISTER_SIZE-OP_IMM_IMMEDIATE_SIZE-1 downto 0)&
                              instruction(31 downto 20));
  data1     <= unsigned(rs1_data);
  data2     <= unsigned(rs2_data)                              when is_immediate = '0' else immediate_value;
  shift_amt <= unsigned(data2(log2(REGISTER_SIZE)-1 downto 0)) when not SHIFTER_USE_MULTIPLIER else
               unsigned(data2(log2(REGISTER_SIZE)-1 downto 0)) when instruction(14) = '0'else
               32-unsigned(data2(log2(REGISTER_SIZE)-1 downto 0));

  shift_value <= signed((instruction(30) and rs1_data(rs1_data'left)) & rs1_data);

--combine slt
  with instruction(14 downto 12) select
    op1_msb <=
    '0'               when "110",
    '0'               when "111",
    '0'               when "011",
    data1(data1'left) when others;
  with instruction(14 downto 12) select
    op2_msb <=
    '0'               when "110",
    '0'               when "111",
    '0'               when "011",
    data2(data1'left) when others;

  op1 <= signed(op1_msb & data1);
  op2 <= signed(op2_msb & data2);

  with instruction(6 downto 5) select
    is_add <=
    instruction(14 downto 12) = "000"                           when "00",
    instruction(14 downto 12) = "000" and instruction(30) = '0' when "01",
    false                                                       when others;
  sub       <= op1+op2 when is_add else op1 - op2;
  sub_valid <= source_valid;


  shift_mul_gen : for n in shifter_multiply'left-1 downto 0 generate
    shifter_multiply(n) <= '1' when std_logic_vector(shift_amt) = std_logic_vector(to_unsigned(n, shift_amt'length)) else '0';
  end generate shift_mul_gen;
  shifter_multiply(shifter_multiply'left) <= '0';


  m_op1_msk <= '0' when instruction(13 downto 12) = "11" else '1';
  m_op2_msk <= not instruction(13);
  m_op1     <= signed((m_op1_msk and rs1_data(data1'left)) & data1);
  m_op2     <= signed((m_op2_msk and rs2_data(data2'left)) & data2);

  mul_srca          <= signed(m_op1) when instruction(25) = '1' or not SHIFTER_USE_MULTIPLIER else shifter_multiply;
  mul_srcb          <= signed(m_op2) when instruction(25) = '1' or not SHIFTER_USE_MULTIPLIER else shift_value;
  mul_src_shift_amt <= shift_amt;
  mul_src_valid     <= source_valid;
end architecture rtl;


-------------------------------------------------------------------------------
-- DIVISION
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.utils.all;


entity divider is
  generic (
    REGISTER_SIZE : natural
    );
  port(
    clk              : in  std_logic;
    div_enable       : in  std_logic;
    unsigned_div     : in  std_logic;
    rs1_data         : in  unsigned(REGISTER_SIZE-1 downto 0);
    rs2_data         : in  unsigned(REGISTER_SIZE-1 downto 0);
    quotient         : out unsigned(REGISTER_SIZE-1 downto 0);
    remainder        : out unsigned(REGISTER_SIZE-1 downto 0);
    div_result_valid : out std_logic
    );
end entity;

architecture rtl of divider is
  type div_state is (IDLE, DIVIDING, DONE);
  signal state       : div_state;
  signal count       : natural range REGISTER_SIZE-1 downto 0;
  signal numerator   : unsigned(REGISTER_SIZE-1 downto 0);
  signal denominator : unsigned(REGISTER_SIZE-1 downto 0);

  signal div_neg_op1       : std_logic;
  signal div_neg_op2       : std_logic;
  signal div_neg_quotient  : std_logic;
  signal div_neg_remainder : std_logic;

  signal div_zero     : boolean;
  signal div_overflow : boolean;

  signal div_res    : unsigned(REGISTER_SIZE-1 downto 0);
  signal rem_res    : unsigned(REGISTER_SIZE-1 downto 0);
  signal min_signed : unsigned(REGISTER_SIZE-1 downto 0);
begin  -- architecture rtl

  div_neg_op1 <= not unsigned_div when signed(rs1_data) < 0 else '0';
  div_neg_op2 <= not unsigned_div when signed(rs2_data) < 0 else '0';

  min_signed <= (min_signed'left => '1',
                 others          => '0');
  div_zero     <= rs2_data = to_unsigned(0, REGISTER_SIZE);
  div_overflow <= rs1_data = min_signed and
                  rs2_data = unsigned(to_signed(-1, REGISTER_SIZE)) and unsigned_div = '0';


  numerator   <= unsigned(rs1_data) when div_neg_op1 = '0' else unsigned(-signed(rs1_data));
  denominator <= unsigned(rs2_data) when div_neg_op2 = '0' else unsigned(-signed(rs2_data));


  div_proc : process(clk)
    variable D     : unsigned(REGISTER_SIZE-1 downto 0);
    variable N     : unsigned(REGISTER_SIZE-1 downto 0);
    variable R     : unsigned(REGISTER_SIZE-1 downto 0);
    variable Q     : unsigned(REGISTER_SIZE-1 downto 0);
    variable sub   : unsigned(REGISTER_SIZE downto 0);
    variable Q_lsb : std_logic;
  begin

    if rising_edge(clk) then
      div_result_valid <= '0';
      if div_enable = '1' then
        case state is
          when IDLE =>
            div_neg_quotient  <= div_neg_op2 xor div_neg_op1;
            div_neg_remainder <= div_neg_op1;
            D                 := denominator;
            N                 := numerator;
            R                 := (others => '0');
            if div_zero then
              Q                := (others => '1');
              R                := rs1_data;
              div_result_valid <= '1';
            elsif div_overflow then
              Q                := min_signed;
              div_result_valid <= '1';
            else
              state <= DIVIDING;
              count <= Q'length - 1;
            end if;
          when DIVIDING =>
            R(REGISTER_SIZE-1 downto 1) := R(REGISTER_SIZE-2 downto 0);
            R(0)                        := N(N'left);
            N                           := SHIFT_LEFT(N, 1);

            Q_lsb := '0';
            sub   := ("0"&R)-("0"&D);
            if sub(sub'left) = '0' then
              R     := sub(R'range);
              Q_lsb := '1';
            end if;
            Q := Q(Q'left-1 downto 0) & Q_lsb;
            if count /= 0 then
              count <= count - 1;
            else
              div_result_valid <= '1';
              state            <= DONE;
            end if;
          when DONE =>
            state <= IDLE;
        end case;
        div_res <= Q;
        rem_res <= R;
      else
        state <= IDLE;
      end if;

    end if;  -- clk
  end process;

  remainder <= rem_res when div_neg_remainder = '0' else unsigned(-signed(rem_res));
  quotient  <= div_res when div_neg_quotient = '0'  else unsigned(-signed(div_res));
end architecture rtl;
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
use work.constants_pkg.all;
--use IEEE.std_logic_arith.all;

entity branch_unit is


  generic (
    REGISTER_SIZE       : integer;
    SIGN_EXTENSION_SIZE : integer);

  port (
    clk            : in  std_logic;
    stall          : in  std_logic;
    valid          : in  std_logic;
    reset          : in  std_logic;
    rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    current_pc     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    br_taken_in    : in  std_logic;
    instr          : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    less_than      : in  std_logic;
    --unconditional jumps store return address in rd, output return address
    -- on data_out lines
    data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_out_en    : out std_logic;
    new_pc         : out std_logic_vector(REGISTER_SIZE-1 downto 0);  --next pc
    is_branch      : out std_logic;
    br_taken_out   : out std_logic;
    bad_predict    : out std_logic
    );
end entity branch_unit;


architecture latch_middle of branch_unit is

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

  signal branch_taken : std_logic;

  alias func3  : std_logic_vector(2 downto 0) is instr(INSTR_FUNC3'range);
  alias opcode : std_logic_vector(6 downto 0) is instr(6 downto 0);

  signal valid_branch_instr : std_logic;
  signal br_taken_latch     : std_logic;
  signal target_pc_latch    : unsigned(REGISTER_SIZE-1 downto 0);
  signal nbranch_latch      : unsigned(REGISTER_SIZE-1 downto 0);
  signal branch_taken_latch : std_logic;
  signal data_en_latch      : std_logic;

  signal branch_taken_or_jump : std_logic;
  signal is_jal_op               : std_logic;
  signal is_jalr_op              : std_logic;
  signal is_br_op                : std_logic;
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
    branch_taken <=
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
                       instr(31 downto 21) & "0") ;
  jal_imm <= unsigned(RESIZE(signed(instr(31) & instr(19 downto 12) & instr(20) &
                                    instr(30 downto 21)&"0"),REGISTER_SIZE));

  branch_target  <= b_imm + unsigned(current_pc);
  nbranch_target <= to_unsigned(4, REGISTER_SIZE) + unsigned(current_pc);
  jalr_target    <= jalr_imm + unsigned(rs1_data);
  jal_target     <= jal_imm + unsigned(current_pc);

  with opcode select
    target_pc <=
    jalr_target    when JALR_OP,
    jal_target     when JAL_OP,
    branch_target  when BRANCH_OP,
    nbranch_target when others;


  middle_latch : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        valid_branch_instr <= '0';
        br_taken_latch     <= '0';
      else
        valid_branch_instr <= valid and not stall;
        if stall = '0' then
          br_taken_latch     <= br_taken_in;
          target_pc_latch    <= target_pc;
          branch_taken_latch <= branch_taken;

          is_jal_op  <= '0';
          is_jalr_op <= '0';
          is_br_op   <= '0';

          if opcode = JAL_OP then    is_jal_op   <= '1'; end if;
          if opcode = JALR_OP then   is_jalr_op <= '1'; end if;
          if opcode = BRANCH_OP then is_br_op <= '1'; end if;

          nbranch_latch <= nbranch_target;
        end if;
      end if;
    end if;
  end process;


  data_out_en <= valid_branch_instr and (is_jal_op or is_jalr_op);

  branch_taken_or_jump <= (branch_taken_latch and is_br_op) or is_jal_op or is_jalr_op;
  br_taken_out         <= valid_branch_instr and branch_taken_or_jump;
  bad_predict          <= valid_branch_instr when br_taken_latch /= branch_taken_or_jump or is_jalr_op = '1' else '0';
  is_branch            <= valid_branch_instr when is_jal_op = '1' or is_br_op = '1'                             else '0';

  new_pc   <= std_logic_vector(target_pc_latch) when branch_taken_or_jump = '1' else std_logic_vector(nbranch_latch);
  data_out <= std_logic_vector(nbranch_latch);


end architecture;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.constants_pkg.all;
entity decode is
  generic(
    REGISTER_SIZE       : positive;
    SIGN_EXTENSION_SIZE : positive;
    PIPELINE_STAGES     : natural range 1 to 2);
  port(
    clk   : in std_logic;
    reset : in std_logic;
    stall : in std_logic;

    flush       : in std_logic;
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_input : in std_logic;
    --writeback signals
    wb_sel      : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    wb_data     : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    wb_enable   : in std_logic;
    wb_valid    : in std_logic;

    --output signals
    rs1_data       : out    std_logic_vector(REGISTER_SIZE -1 downto 0);
    rs2_data       : out    std_logic_vector(REGISTER_SIZE -1 downto 0);
    sign_extension : out    std_logic_vector(SIGN_EXTENSION_SIZE -1 downto 0);
    --inputs just for carrying to next pipeline stage
    br_taken_in    : in     std_logic;
    pc_curr_in     : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    br_taken_out   : out    std_logic;
    pc_curr_out    : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_out      : buffer std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_instr   : out    std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_valid   : out    std_logic;
    valid_output   : out    std_logic;
    decode_flushed : out    std_logic);
end;

architecture rtl of decode is
  signal rs1   : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2   : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs1_p : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2_p : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal rs1_reg : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal outreg1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_reg : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal outreg2 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal br_taken_latch : std_logic;
  signal pc_next_latch  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pc_curr_latch  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_latch    : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal valid_latch    : std_logic;


  signal i_rd  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal i_rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal i_rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal il_rd     : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal il_rs1    : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal il_rs2    : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal il_opcode : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
begin

  register_file_1 : component register_file
    generic map (
      REGISTER_SIZE      => REGISTER_SIZE,
      REGISTER_NAME_SIZE => REGISTER_NAME_SIZE)
    port map(
      clk         => clk,
      valid_input => valid_input,
      rs1_sel     => rs1,
      rs2_sel     => rs2,
      wb_sel      => wb_sel,
      wb_data     => wb_data,
      wb_enable   => wb_enable,
      wb_valid    => wb_valid,
      rs1_data    => rs1_reg,
      rs2_data    => rs2_reg
      );
  two_cycle : if PIPELINE_STAGES = 2 generate
    rs1 <= instruction(REGISTER_RS1'range) when stall = '0' else instr_latch(REGISTER_RS1'range);
    rs2 <= instruction(REGISTER_RS2'range) when stall = '0' else instr_latch(REGISTER_RS2'range);

    rs1_p <= instr_latch(REGISTER_RS1'range) when stall = '0' else instr_out(REGISTER_RS1'range);
    rs2_p <= instr_latch(REGISTER_RS2'range) when stall = '0' else instr_out(REGISTER_RS2'range);

    decode_flushed <= not (valid_input or valid_latch);

    decode_stage : process (clk, reset) is
    begin  -- process decode_stage
      if rising_edge(clk) then          -- rising clock edge
        if not stall = '1' then
          sign_extension <= std_logic_vector(
            resize(signed(instr_latch(INSTRUCTION_SIZE-1 downto INSTRUCTION_SIZE-1)),
                   SIGN_EXTENSION_SIZE));
          br_taken_latch <= br_taken_in;
          PC_curr_latch  <= PC_curr_in;
          instr_latch    <= instruction;
          valid_latch    <= valid_input;

          br_taken_out <= br_taken_latch;
          pc_curr_out  <= PC_curr_latch;
          instr_out    <= instr_latch;
          valid_output <= valid_latch;

        end if;

        if wb_sel = rs1_p and wb_enable = '1' and wb_valid = '1' then
          outreg1 <= wb_data;
        elsif stall = '0' then
          outreg1 <= rs1_reg;
        end if;
        if wb_sel = rs2_p and wb_enable = '1' and wb_valid = '1' then
          outreg2 <= wb_data;
        elsif stall = '0' then
          outreg2 <= rs2_reg;
        end if;

        if reset = '1' or flush = '1' then
          valid_output <= '0';
          valid_latch  <= '0';
        end if;
      end if;
    end process decode_stage;
    subseq_instr <= instr_latch;
    subseq_valid <= valid_latch;
    rs1_data     <= outreg1;
    rs2_data     <= outreg2;
  end generate two_cycle;


  one_cycle : if PIPELINE_STAGES = 1 generate
    rs1 <= instruction(19 downto 15) when stall = '0' else instr_out(19 downto 15);
    rs2 <= instruction(24 downto 20) when stall = '0' else instr_out(24 downto 20);

    decode_flushed <= not valid_input;
    decode_stage : process (clk, reset) is
    begin  -- process decode_stage
      if rising_edge(clk) then          -- rising clock edge
        if not stall = '1' then
          sign_extension <= std_logic_vector(
            resize(signed(instruction(INSTRUCTION_SIZE-1 downto INSTRUCTION_SIZE-1)),
                   SIGN_EXTENSION_SIZE));
          br_taken_out <= br_taken_in;
          PC_curr_out  <= PC_curr_in;
          instr_out    <= instruction;
          valid_output <= valid_input;
        end if;


        if reset = '1' or flush = '1' then
          valid_output <= '0';
        end if;
      end if;
    end process decode_stage;
    subseq_instr <= instruction;
    subseq_valid <= valid_input;
    rs1_data     <= rs1_reg;
    rs2_data     <= rs2_reg;
  end generate one_cycle;

end architecture;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_textio.all;          -- I/O for logic types

library work;
use work.rv_components.all;
use work.utils.all;
use work.constants_pkg.all;

library STD;
use STD.textio.all;                     -- basic I/O

entity execute is
  generic(
    REGISTER_SIZE       : positive;
    SIGN_EXTENSION_SIZE : positive;
    RESET_VECTOR        : integer;
    MULTIPLY_ENABLE     : boolean;
    DIVIDE_ENABLE       : boolean;
    SHIFTER_MAX_CYCLES  : natural;
    COUNTER_LENGTH      : natural;
    ENABLE_EXCEPTIONS   : boolean;
    SCRATCHPAD_SIZE     : integer;
    FAMILY              : string);
  port(
    clk            : in std_logic;
    scratchpad_clk : in std_logic;
    reset          : in std_logic;
    valid_input    : in std_logic;

    br_taken_in  : in std_logic;
    pc_current   : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction  : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_instr : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_valid : in std_logic;

    rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    sign_extension : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

    wb_sel       : buffer std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    wb_data      : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_enable    : buffer std_logic;
    valid_output : buffer std_logic;


    branch_pred        : out    std_logic_vector(REGISTER_SIZE*2+3 -1 downto 0);
    stall_from_execute : buffer std_logic;



    --memory-bus master
    address   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    byte_en   : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    write_en  : out std_logic;
    read_en   : out std_logic;
    writedata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    readdata  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_ack  : in  std_logic;

    --memory-bus scratchpad-slave
    sp_address   : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
    sp_byte_en   : in  std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    sp_write_en  : in  std_logic;
    sp_read_en   : in  std_logic;
    sp_writedata : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_readdata  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_ack  : out std_logic;

    external_interrupts : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    pipeline_empty      : in  std_logic;
    ifetch_next_pc      : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    interrupt_pending   : out std_logic);


end entity execute;

architecture behavioural of execute is

  alias rd is instruction (REGISTER_RD'range);
  alias rs1 is instruction(REGISTER_RS1'range);
  alias rs2 is instruction(REGISTER_RS2'range);
  alias opcode is instruction(MAJOR_OP'range);

  signal predict_corr    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal predict_corr_en : std_logic;

  signal stall_to_syscall : std_logic;

  signal ls_address    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ls_byte_en    : std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
  signal ls_write_en   : std_logic;
  signal ls_read_en    : std_logic;
  signal ls_write_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ls_read_data  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ls_ack        : std_logic;


  -- various writeback sources
  signal br_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal alu_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ld_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal upp_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sys_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal br_data_enable     : std_logic;
  signal alu_data_out_valid : std_logic;
  signal ld_data_enable     : std_logic;
  signal upp_data_enable    : std_logic;
  signal sys_data_enable    : std_logic;
  signal less_than          : std_logic;
  signal wb_mux             : std_logic_vector(1 downto 0);

  signal stall_to_alu   : std_logic;
  signal stall_from_alu : std_logic;

  signal br_bad_predict : std_logic;
  signal br_new_pc      : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal predict_pc     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal syscall_en     : std_logic;
  signal syscall_target : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal rs1_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal alu_rs1_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal alu_rs2_data : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal stall_to_lsu    : std_logic;
  signal ls_unit_waiting : std_logic;

  signal fwd_sel  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal fwd_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal fwd_en   : std_logic;
  signal fwd_mux  : std_logic;

  signal stall_from_lve       : std_logic;
  signal lve_alu_data1        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal lve_alu_data2        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal lve_alu_source_valid : std_logic;
  signal stall_to_lve         : std_logic;

  signal valid_instr : std_logic;
  signal rd_latch    : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal valid_input_latched : std_logic;


  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

  type fwd_mux_t is (ALU_FWD, NO_FWD);
  signal rs1_mux : fwd_mux_t;
  signal rs2_mux : fwd_mux_t;

  signal finished_instr : std_logic;


  signal entire_pipeline_empty : std_logic;
  signal is_branch             : std_logic;
  signal br_taken_out          : std_logic;


  alias ni_rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is subseq_instr(19 downto 15);
  alias ni_rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is subseq_instr(24 downto 20);

  constant LVE_ENABLE : boolean                            := SCRATCHPAD_SIZE /= 0;

  signal use_after_produce_stall      : std_logic;
  signal use_after_produce_stall_mask : std_logic;

  signal stalled_component : std_logic;

begin
  valid_instr <= valid_input and not use_after_produce_stall;
  -----------------------------------------------------------------------------
  -- REGISTER FORWADING
  -- Knowing the next instruction coming downt the pipeline, we can
  -- generate the mux select bits for the next cycle.
  -- there are several functional units that could generate a writeback. ALU,
  -- JAL, Syscalls, load_store. the Alu forward directly to the next
  -- instruction, The others stall the pipeline to wait for the registers to
  -- propogate if the next instruction uses them.
  --
  -----------------------------------------------------------------------------
  with rs1_mux select
    rs1_data_fwd <=
    alu_data_out when ALU_FWD,
    rs1_data     when others;
  with rs2_mux select
    rs2_data_fwd <=
    alu_data_out when ALU_FWD,
    rs2_data     when others;



  alu_rs1_data <= rs1_data_fwd when not LVE_ENABLE else
                  lve_alu_data1 when lve_alu_source_valid = '1' else
                  alu_data_out  when rs1_mux = ALU_FWD else rs1_data;
  alu_rs2_data <= rs2_data_fwd when not LVE_ENABLE else
                  lve_alu_data2 when lve_alu_source_valid = '1' else
                  alu_data_out  when rs2_mux = ALU_FWD else rs2_data;



  -------------------------------------------------------------------------------
  -- This process is useful for finding bugs in simulation
  -------------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '0' then
        assert (bool_to_int(sys_data_enable) +
                bool_to_int(ld_data_enable) +
                bool_to_int(br_data_enable) +
                bool_to_int(alu_data_out_valid)) <=1  and reset = '0' report "Multiple Data Enables Asserted" severity failure;
      end if;
    end if;
  end process;

  wb_mux <= "00" when sys_data_enable = '1' else
            "01" when ld_data_enable = '1' else
            "10" when br_data_enable = '1' else
            "11";                       --when alu_data_out_valid = '1'

  with wb_mux select
    wb_data <=
    sys_data_out when "00",
    ld_data_out  when "01",
    br_data_out  when "10",
    alu_data_out when others;

  wb_enable <= sys_data_enable or ld_data_enable or br_data_enable or (alu_data_out_valid and (not stall_from_lve)) when wb_sel /= ZERO else '0';
  wb_sel    <= rd_latch;

  fwd_data <= sys_data_out when sys_data_enable = '1' else
              alu_data_out when alu_data_out_valid = '1' else
              br_data_out;

  --use_after_produce_stall <= wb_enable and valid_input and use_after_produce_stall_mask;

  stalled_component  <= ls_unit_waiting or stall_from_alu or use_after_produce_stall or stall_from_lve;
  stall_to_lve       <= (ls_unit_waiting or use_after_produce_stall);
  stall_to_alu       <= (ls_unit_waiting or use_after_produce_stall);
  stall_from_execute <= stalled_component and valid_input;
  stall_to_lsu       <= stalled_component;
  stall_to_syscall   <= stalled_component;

  --TODO clean this up.
  -- There was a bug here that valid output would not go high if a load was followed
  -- by a pipeline bubble, the "or ld_data_enable" belwo fixes that, but it
  -- doesn't seem to be the right fix.
  valid_output <= valid_input_latched or ls_ack;

  process(clk)
    variable current_alu  : boolean;
    variable no_fwd_path  : boolean;
    variable rs1_mux_var  : fwd_mux_t;
    variable rs2_mux_var  : fwd_mux_t;
    variable rd_latch_var : std_logic_vector(rd'range);
  begin
    if rising_edge(clk) then

      valid_input_latched <= valid_input and not stall_from_execute;
      --calculate where the next forward data will go
      current_alu         := opcode = LUI_OP or
                             opcode = AUIPC_OP or
                             opcode = ALU_OP or
                             opcode = ALUI_OP;

      rs1_mux_var := NO_FWD;
      rs2_mux_var := NO_FWD;
      if (current_alu) and valid_instr = '1' and stalled_component = '0' then
        if rd = ni_rs1 and rd /= ZERO then
          rs1_mux_var := ALU_FWD;
        end if;
        if rd = ni_rs2 and rd /= ZERO then
          rs2_mux_var := ALU_FWD;
        end if;
      end if;

      rd_latch_var := rd_latch;
      if (ls_unit_waiting or stall_from_alu) = '0' and valid_input = '1' then
        rd_latch_var := rd;
        --load, csr_read, jal[r] are the only instructions that writeback but
        --don't forward. Of these only csr_read and loads don't flush the
        --pipeline so these are the ones we concern ourselves with here.
        no_fwd_path  := opcode = LOAD_OP or opcode = SYSTEM_OP;
      end if;

      -------------------------------------------------------------------------------
      -- Generate use after produce stall
      --
      -- 1. normally it is low
      -- 2. if it was previously set, and a stall is happening in syscall
      --        (impossible ) or loadstore it should stay high
      -- 3. if there next instruction depends on this instruction and there is
      --       no forward path it shoud go high unless it high and wb_enable is
      --       high
      --
      --  Note this looks pretty complex, but it compiles down to about 20
      --  LUTs (on a CYCLONEIV)
      -------------------------------------------------------------------------------


      use_after_produce_stall <= '0';
      if use_after_produce_stall = '1' and ls_unit_waiting = '1' then
        use_after_produce_stall <= '1';
      end if;

      if ((rd_latch_var = ni_rs1 or rd_latch_var = ni_rs2) and
          rd_latch_var /= ZERO and
          subseq_valid = '1' and
          no_fwd_path and
          not (use_after_produce_stall = '1' and wb_enable = '1'))then
        use_after_produce_stall <= '1';
      end if;

      rd_latch <= rd_latch_var;
      rs1_mux  <= rs1_mux_var;
      rs2_mux  <= rs2_mux_var;
    end if;
  end process;

  alu : component arithmetic_unit
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      MULTIPLY_ENABLE     => MULTIPLY_ENABLE,
      DIVIDE_ENABLE       => DIVIDE_ENABLE,
      SHIFTER_MAX_CYCLES  => SHIFTER_MAX_CYCLES,
      FAMILY              => FAMILY)
    port map (
      clk                => clk,
      stall_to_alu       => stall_to_alu,
      stall_from_execute => stall_from_execute,
      valid_instr        => valid_instr,
      rs1_data           => alu_rs1_data,
      rs2_data           => alu_rs2_data,
      instruction        => instruction,
      sign_extension     => sign_extension,
      program_counter    => pc_current,
      data_out           => alu_data_out,
      data_out_valid     => alu_data_out_valid,
      less_than          => less_than,
      stall_from_alu     => stall_from_alu,

      lve_data1        => lve_alu_data1,
      lve_data2        => lve_alu_data2,
      lve_source_valid => lve_alu_source_valid
      );


  branch : entity work.branch_unit(latch_middle)
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(
      clk            => clk,
      reset          => reset,
      valid          => valid_instr,
      stall          => stalled_component,
      rs1_data       => rs1_data_fwd,
      rs2_data       => rs2_data_fwd,
      current_pc     => pc_current,
      br_taken_in    => br_taken_in,
      instr          => instruction,
      less_than      => less_than,
      sign_extension => sign_extension,
      data_out       => br_data_out,
      data_out_en    => br_data_enable,
      new_pc         => br_new_pc,
      is_branch      => is_branch,
      br_taken_out   => br_taken_out,
      bad_predict    => br_bad_predict);

  ls_unit : component load_store_unit
    generic map(
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(
      clk            => clk,
      reset          => reset,
      valid          => valid_instr,
      stall_to_lsu   => stall_to_lsu,
      rs1_data       => rs1_data_fwd,
      rs2_data       => rs2_data_fwd,
      instruction    => instruction,
      sign_extension => sign_extension,
      stalled        => ls_unit_waiting,
      data_out       => ld_data_out,
      data_enable    => ld_data_enable,
      --memory bus
      address        => ls_address,
      byte_en        => ls_byte_en,
      write_en       => ls_write_en,
      read_en        => ls_read_en,
      write_data     => ls_write_data,
      read_data      => ls_read_data,
      ack            => ls_ack);

  entire_pipeline_empty <= pipeline_empty and not valid_input;

  syscall : component system_calls
    generic map (
      REGISTER_SIZE     => REGISTER_SIZE,
      RESET_VECTOR      => RESET_VECTOR,
      ENABLE_EXCEPTIONS => ENABLE_EXCEPTIONS,
      COUNTER_LENGTH    => COUNTER_LENGTH)
    port map (
      clk   => clk,
      reset => reset,
      valid => valid_instr,

      stall_in => stall_to_syscall,

      rs1_data    => rs1_data_fwd,
      instruction => instruction,
      wb_data     => sys_data_out,
      wb_enable   => sys_data_enable,

      current_pc    => pc_current,
      pc_correction => syscall_target,
      pc_corr_en    => syscall_en,

      interrupt_pending   => interrupt_pending,
      pipeline_empty      => entire_pipeline_empty,
      external_interrupts => external_interrupts,

      instruction_fetch_pc => ifetch_next_pc,
      br_bad_predict       => br_bad_predict,
      br_new_pc            => br_new_pc);

  enable_lve : if LVE_ENABLE generate
  begin
    lve : component lve_top
      generic map (
        REGISTER_SIZE    => REGISTER_SIZE,
        SCRATCHPAD_SIZE  => SCRATCHPAD_SIZE,
        SLAVE_DATA_WIDTH => REGISTER_SIZE,
        FAMILY           => FAMILY)
      port map (
        clk            => clk,
        scratchpad_clk => scratchpad_clk,
        reset          => reset,
        instruction    => instruction,
        valid_instr    => valid_instr,
        stall_to_lve   => stall_to_lve,
        rs1_data       => rs1_data_fwd,
        rs2_data       => rs2_data_fwd,
        slave_address  => sp_address,
        slave_read_en  => sp_read_en,
        slave_write_en => sp_write_en,
        slave_byte_en  => sp_byte_en,
        slave_data_in  => sp_writedata,
        slave_data_out => sp_readdata,
        slave_ack      => sp_ack,

        stall_from_lve       => stall_from_lve,
        lve_alu_data1        => lve_alu_data1,
        lve_alu_data2        => lve_alu_data2,
        lve_alu_source_valid => lve_alu_source_valid,
        lve_alu_result       => alu_data_out,
        lve_alu_result_valid => alu_data_out_valid
        );

  end generate enable_lve;

  n_enable_lve : if not LVE_ENABLE generate
    stall_from_lve <= '0';

    lve_alu_source_valid <= '0';
    lve_alu_data1        <= (others => '-');
    lve_alu_data2        <= (others => '-');
  end generate n_enable_lve;

  ls_read_data <= readdata;
  ls_ack       <= data_ack;

  byte_en   <= ls_byte_en;
  address   <= ls_address;
  write_en  <= ls_write_en;
  read_en   <= ls_read_en;
  writedata <= ls_write_data;



  predict_corr_en <= syscall_en or br_bad_predict;
  predict_corr    <= br_new_pc  when syscall_en = '0' else syscall_target;
  predict_pc      <= pc_current when rising_edge(clk);

  branch_pred <= branch_pack_signal(predict_pc,       --this pc
                                    predict_corr,     --branch target
                                    br_taken_out,     --taken
                                    predict_corr_en,  --flush
                                    is_branch);       --is_branch


  -----------------------------------------------------------------------------
  -- This process does some debug printing during simulation,
  -- it should have no impact on synthesis
  -----------------------------------------------------------------------------
--pragma translate_off
  my_print : process(clk)
    variable my_line          : line;   -- type 'line' comes from textio
    variable last_valid_pc    : std_logic_vector(pc_current'range);
    type register_list is array(0 to 31) of std_logic_vector(REGISTER_SIZE-1 downto 0);
    variable shadow_registers : register_list := (others => (others => '0'));

    constant DEBUG_WRITEBACK : boolean := false;

  begin
    if rising_edge(clk) then

      if valid_output = '1' and DEBUG_WRITEBACK then
        write(my_line, string'("WRITEBACK: PC = "));
        hwrite(my_line, last_valid_pc);
        if wb_enable = '1' then
          shadow_registers(to_integer(unsigned(wb_sel))) := wb_data;
        end if;
        write(my_line, string'(" REGISTERS = {"));
        for i in shadow_registers'range loop
          hwrite(my_line, shadow_registers(i));
          if i /= shadow_registers'right then
            write(my_line, string'(","));
          end if;

        end loop;  -- i
        write(my_line, string'("}"));
        writeline(output, my_line);
      end if;


      if valid_instr = '1' then
        write(my_line, string'("executing pc = "));  -- formatting
        hwrite(my_line, (pc_current));  -- format type std_logic_vector as hex
        write(my_line, string'(" instr =  "));       -- formatting
        hwrite(my_line, (instruction));  -- format type std_logic_vector as hex
        if stall_from_execute = '1' then
          write(my_line, string'(" stalling"));      -- formatting
        else
          last_valid_pc := pc_current;
        end if;
        writeline(output, my_line);     -- write to "output"
      else
      --write(my_line, string'("bubble"));  -- formatting
      --writeline(output, my_line);     -- write to "output"
      end if;

    end if;
  end process my_print;
--pragma translate_on
end architecture;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.utils.all;
use work.constants_pkg.all;

entity instruction_fetch is
  generic (
    REGISTER_SIZE     : positive;
    RESET_VECTOR      : integer;
    BRANCH_PREDICTORS : natural);
  port (
    clk                : in std_logic;
    reset              : in std_logic;
    downstream_stalled : in std_logic;
    interrupt_pending  : in std_logic;
    branch_pred        : in std_logic_vector(REGISTER_SIZE*2+3-1 downto 0);

    br_taken        : buffer std_logic;
    instr_out       : out    std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    pc_out          : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    next_pc_out     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    valid_instr_out : out    std_logic;

    read_address   : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    read_en        : buffer std_logic;
    read_data      : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    read_datavalid : in     std_logic;
    read_wait      : in     std_logic);
end entity instruction_fetch;


architecture rtl of instruction_fetch is
  type state_t is (state_0, state_1, state_2);

  signal state : state_t;

  signal move_to_next_address : boolean;
  signal program_counter      : unsigned(REGISTER_SIZE-1 downto 0);

  signal pc_corr    : unsigned(REGISTER_SIZE-1 downto 0);
  signal pc_corr_en : std_logic;

  signal pc_corr_saved    : unsigned(REGISTER_SIZE-1 downto 0);
  signal pc_corr_saved_en : std_logic;

  signal instr_out_saved       : std_logic_vector(instr_out'range);
  signal valid_instr_out_saved : std_logic;

  signal predicted_pc : unsigned(REGISTER_SIZE -1 downto 0);
  signal next_address : unsigned(REGISTER_SIZE -1 downto 0);

  signal suppress_valid_instr_out : std_logic;
  signal dont_increment           : std_logic;
begin  -- architecture rtl


  --unpack branch_pred_data_in
  --branch_pc       <= branch_get_pc(branch_pred);
  --branch_taken_in <= branch_get_taken(branch_pred);
  --branch_en       <= branch_get_enable(branch_pred);
  pc_corr    <= unsigned(branch_get_tgt(branch_pred));
  pc_corr_en <= branch_get_flush(branch_pred);

  dont_increment <= downstream_stalled or interrupt_pending;

  move_to_next_address <= (state = state_1 and read_datavalid = '1' and dont_increment = '0') or
                          (state = state_2 and dont_increment = '0');



  process(clk)
  begin
    if rising_edge(clk) then
      case state is
        when state_0 =>                 --waiting for read_wait
          if read_wait = '0' then
            state <= state_1;
          else
            state <= state_0;
          end if;
        when state_1 =>                 --waiting for readvalid
          if read_datavalid = '1' then
            if dont_increment = '1' then
              state <= state_2;
            elsif read_wait = '0' then
              state <= state_1;
            else
              state <= state_0;
            end if;
          end if;
        when state_2 =>                 -- waiting for execute_stall
          if dont_increment = '0' then
            if read_wait = '0' then
              state <= state_1;
            else
              state <= state_0;
            end if;

          else
            state <= state_2;
          end if;
        when others => null;
      end case;

      if reset = '1' then
        state <= state_0;
      end if;
    end if;
  end process;


  bramch_pred_proc : process(clk)
  begin
    if rising_edge(clk) then
      predicted_pc <= next_address +4;
    end if;
  end process;

  pc_corr_proc : process(clk)
  begin
    if rising_edge(clk) then
      if not move_to_next_address then
        if pc_corr_en = '1' then
          pc_corr_saved    <= pc_corr;
          pc_corr_saved_en <= '1';
        end if;
      else
        pc_corr_saved_en <= '0';
      end if;
    end if;
  end process;

  program_counter_transition : process(clk)
  begin
    if rising_edge(clk) then
      if move_to_next_address then
        program_counter <= next_address;
      end if;
      if reset = '1' then
        program_counter <= unsigned(to_signed(RESET_VECTOR, REGISTER_SIZE));
      end if;
    end if;
  end process;

  save_fetched_instr : process(clk)
  begin
    if rising_edge(clk) then
      if downstream_stalled = '1' then
        if read_datavalid = '1' then
          instr_out_saved       <= read_data;
          valid_instr_out_saved <= read_datavalid;
        end if;
      else
        valid_instr_out_saved <= '0';
      end if;
    end if;
  end process;

  suppress_valid_instr_out_proc : process(clk)
  begin
    if rising_edge(clk) then
      if pc_corr_en = '1' then
        suppress_valid_instr_out <= not interrupt_pending;
      end if;
      if read_datavalid = '1' then
        suppress_valid_instr_out <= '0';
      end if;
      if reset = '1' then
        suppress_valid_instr_out <= '0';
      end if;
    end if;
  end process;

  pc_out          <= std_logic_vector(program_counter);
  instr_out       <= read_data when valid_instr_out_saved = '0' else instr_out_saved;
  valid_instr_out <= (read_datavalid or valid_instr_out_saved) and not (suppress_valid_instr_out or pc_corr_en or interrupt_pending);


  next_address <= pc_corr when pc_corr_en = '1' and move_to_next_address else
                  pc_corr_saved when pc_corr_saved_en = '1' and move_to_next_address else
                  predicted_pc  when move_to_next_address else
                  program_counter;
  next_pc_out  <= std_logic_vector(next_address);
  read_address <= std_logic_vector(program_counter) when state = state_0                           else std_logic_vector(next_address);
  read_en      <= not reset                         when (state = state_0 or move_to_next_address) else '0';
  br_taken     <= '0';
end architecture rtl;
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.constants_pkg.all;


entity load_store_unit is
  generic (
    REGISTER_SIZE       : integer;
    SIGN_EXTENSION_SIZE : integer);

  port (
    clk            : in     std_logic;
    reset          : in     std_logic;
    valid          : in     std_logic;
    stall_to_lsu   : in     std_logic;
    rs1_data       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction    : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    sign_extension : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    stalled        : buffer std_logic;
    data_out       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_enable    : out    std_logic;
--memory-bus
    address        : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    byte_en        : out    std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    write_en       : buffer std_logic;
    read_en        : buffer std_logic;
    write_data     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    read_data      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    ack            : in     std_logic);

end entity load_store_unit;

architecture rtl of load_store_unit is

  constant BYTE_SIZE  : std_logic_vector(2 downto 0) := "000";
  constant HALF_SIZE  : std_logic_vector(2 downto 0) := "001";
  constant WORD_SIZE  : std_logic_vector(2 downto 0) := "010";
  constant UBYTE_SIZE : std_logic_vector(2 downto 0) := "100";
  constant UHALF_SIZE : std_logic_vector(2 downto 0) := "101";

  constant STORE_INSTR : std_logic_vector(6 downto 0) := "0100011";
  constant LOAD_INSTR  : std_logic_vector(6 downto 0) := "0000011";

  alias base_address : std_logic_vector(REGISTER_SIZE-1 downto 0) is rs1_data;
  alias source_data  : std_logic_vector(REGISTER_SIZE-1 downto 0) is rs2_data;

  signal fun3         : std_logic_vector(2 downto 0);
  signal latched_fun3 : std_logic_vector(2 downto 0);
  signal opcode       : std_logic_vector(6 downto 0);
  signal imm          : std_logic_vector(11 downto 0);

  signal address_unaligned : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal alignment         : std_logic_vector(1 downto 0);

  signal w0 : std_logic_vector(7 downto 0);
  signal w1 : std_logic_vector(7 downto 0);
  signal w2 : std_logic_vector(7 downto 0);
  signal w3 : std_logic_vector(7 downto 0);

  --individual register byte
  signal r0           : std_logic_vector(7 downto 0);
  signal r1           : std_logic_vector(7 downto 0);
  signal r2           : std_logic_vector(7 downto 0);
  signal r3           : std_logic_vector(7 downto 0);
  signal fixed_data   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal latched_data : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal expecting_r_ack : std_logic;
  signal expecting_w_ack : std_logic;
  signal expecting_ack   : std_logic;
  signal write_instr     : boolean;
  signal read_instr      : boolean;
begin

  --prepare memory signals
  opcode <= instruction(6 downto 0);
  fun3   <= instruction(14 downto 12);

  write_instr <= opcode = STORE_INSTR and valid = '1';
  read_instr  <= opcode = LOAD_INSTR and valid = '1';

  write_en <= valid when write_instr and stall_to_lsu = '0' else '0';
  read_en  <= valid when read_instr and stall_to_lsu = '0'  else '0';

  imm <= instruction(31 downto 25) & instruction(11 downto 7) when instruction(5) = '1'
         else instruction(31 downto 20);

  address_unaligned <= std_logic_vector(unsigned(sign_extension(REGISTER_SIZE-12-1 downto 0) &
                                                 imm)+unsigned(base_address));
  --set the byte enables correctly, (Remember little endian)
  byte_en <= "0001" when fun3 = BYTE_SIZE and address_unaligned(1 downto 0) = "00" else
             "0010" when fun3 = BYTE_SIZE and address_unaligned(1 downto 0) = "01" else
             "0100" when fun3 = BYTE_SIZE and address_unaligned(1 downto 0) = "10" else
             "1000" when fun3 = BYTE_SIZE and address_unaligned(1 downto 0) = "11" else
             "0011" when fun3 = HALF_SIZE and address_unaligned(1 downto 0) = "00" else
             "1100" when fun3 = HALF_SIZE and address_unaligned(1 downto 0) = "10" else
             "1111";

  --move bytes around to be placed at correct address

  w3 <= source_data(7 downto 0) when address_unaligned(1 downto 0) = "11" else
        source_data(15 downto 8) when address_unaligned(1 downto 0) = "10" else
        source_data(31 downto 24);
  w2 <= source_data(7 downto 0) when address_unaligned(1 downto 0) = "10" else
        source_data(23 downto 16);
  w1 <= source_data(7 downto 0) when address_unaligned(1 downto 0) = "01" else
        source_data(15 downto 8);
  w0 <= source_data(7 downto 0);


  --little endian
  write_data <= w3 & w2 & w1 & w0;
  --align to word boundary
  address    <= address_unaligned(REGISTER_SIZE-1 downto 2) & "00";

  stalled <= '1' when ((expecting_r_ack and not ack) = '1') or ((expecting_w_ack and not ack) = '1' and (read_instr or write_instr)) else '0';

  expecting_ack <= expecting_r_ack or expecting_w_ack;

  --outputs, all of these assignments should happen on the rising edge,
  -- they should only depend on latched signals
  latched_inputs : process(clk)
  begin
    if rising_edge(clk) then
      --expecting w ack
      if expecting_ack = '0' or ack = '1' then
        alignment    <= address_unaligned(1 downto 0);
        latched_fun3 <= fun3;
      end if;
      if expecting_r_ack = '1' and ack = '1' then
        expecting_r_ack <= '0';
      end if;
      if read_en = '1' then
        expecting_r_ack <= '1';
      end if;
      --expecting w ack
      if expecting_w_ack = '1' and ack = '1'  then
        expecting_w_ack <= '0';
      end if;
      if write_en = '1' then
        expecting_w_ack <= '1';
      end if;

      if reset = '1' then
        expecting_r_ack <= '0';
        expecting_w_ack <= '0';
      end if;
    end if;
  end process;

  --sort the read data into to correct byte in the register
  r3 <= read_data(31 downto 24);
  r2 <= read_data(23 downto 16);
  r1 <= read_data(15 downto 8) when alignment = "00" else
        read_data(31 downto 24);
  r0 <= read_data(7 downto 0) when alignment = "00" else
        read_data(15 downto 8)  when alignment = "01" else
        read_data(23 downto 16) when alignment = "10" else
        read_data(31 downto 24);

  --zero/sign extend the read data
  with latched_fun3 select
    fixed_data <=
    std_logic_vector(resize(signed(r0), REGISTER_SIZE))      when BYTE_SIZE,
    std_logic_vector(resize(signed(r1 & r0), REGISTER_SIZE)) when HALF_SIZE,
    x"000000"&r0                                             when UBYTE_SIZE,
    x"0000"&r1 & r0                                          when UHALF_SIZE,
    r3 &r2 & r1 & r0                                         when others;

  data_enable <= ack and expecting_r_ack;
  data_out    <= fixed_data;

end architecture;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;
use work.constants_pkg.all;

entity lve_ci is
  generic (
    REGISTER_SIZE : positive := 32
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    func3 : in std_logic_vector(2 downto 0);


    valid_in : in std_logic;
    data1_in : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    data2_in : in std_logic_vector(REGISTER_SIZE-1 downto 0);

    align1_in : in std_logic_vector(1 downto 0);
    align2_in : in std_logic_vector(1 downto 0);

    valid_out        : out std_logic;
    write_enable_out : out std_logic;
    data_out         : out std_logic_vector(REGISTER_SIZE-1 downto 0)
    );
end entity;

architecture rtl of lve_ci is
  constant PIPELINE_DEPTH : positive := 3;

  --For testing pipeline the result

  constant VCUSTOM0_FUNC3 : std_logic_vector(2 downto 0) := "101";
  constant VCUSTOM1_FUNC3 : std_logic_vector(2 downto 0) := "110";
  constant VCUSTOM2_FUNC3 : std_logic_vector(2 downto 0) := "111";
  constant VCUSTOM3_FUNC3 : std_logic_vector(2 downto 0) := "000";
  constant VCUSTOM4_FUNC3 : std_logic_vector(2 downto 0) := "001";
  constant VCUSTOM5_FUNC3 : std_logic_vector(2 downto 0) := "010";

  signal cust0_out_data : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal conv_weights : std_logic_vector(8 downto 0);
  type row_t is array(0 to 2) of signed(8 downto 0);
  type rows_t is array(0 to 2) of row_t;

  signal rows   : rows_t;
  signal in_row : row_t;
  signal align  : std_logic_vector(1 downto 0);

  constant CONV_ADDER_WIDTH : integer := 12;
  function addsub_pix (
    in_pix : signed(8 downto 0);
    weight : std_logic)
    return signed is
  begin  -- function addsub_pix
    if weight = '1' then
      return RESIZE(in_pix, CONV_ADDER_WIDTH);
    end if;
    return -RESIZE(in_pix, CONV_ADDER_WIDTH);
  end function addsub_pix;

  type sum_t is array(0 to 7) of signed(CONV_ADDER_WIDTH-1 downto 0);
  signal conv_sum           : sum_t;
  signal conv_valid_data    : std_logic_vector(2 downto 0);
  signal conv_data_out      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal conv_we, conv_done : std_logic;
begin

  -----------------------------------------------------------------------------
  -- WORD to byte saturation conversion
  -----------------------------------------------------------------------------
  cust0_out_data(7 downto 0) <= x"FF" when signed(data1_in) > 255 else
                                x"00" when signed(data1_in) < 0 else
                                data1_in(7 downto 0);

  cust0_out_data(31 downto 8) <= data1_in(31 downto 8);



  -----------------------------------------------------------------------------
  -- CONVOLUTION CUSTOM INSTRUCTION
  -----------------------------------------------------------------------------
  weight_setup : process(clk)
  begin
    if rising_edge(clk) then
      if func3 = VCUSTOM1_FUNC3 and valid_in = '1'then
        conv_weights <= data1_in(8 downto 0);
      end if;
    end if;
  end process;

  with align1_in select
    in_row(0) <=
    signed("0"&data1_in(31 downto 24)) when "11",
    signed("0"&data1_in(23 downto 16)) when "10",
    signed("0"&data1_in(15 downto 8))  when "01",
    signed("0"&data1_in(7 downto 0))   when others;
  with align1_in select
    in_row(1) <=
    signed("0"&data1_in(15 downto 8))  when "00",
    signed("0"&data1_in(23 downto 16)) when "01",
    signed("0"&data1_in(31 downto 24)) when "10",
    signed("0"&data2_in(7 downto 0))   when others;

  with align1_in select
    in_row(2) <=
    signed("0"&data1_in(23 downto 16)) when "00",
    signed("0"&data1_in(31 downto 24)) when "01",
    signed("0"&data2_in(7 downto 0))   when "10",
    signed("0"&data2_in(15 downto 8))  when others;

  --latch some of these if we want better timing
  --Layer 0 ( with 1 extra add)
  conv_sum(0) <= addsub_pix(rows(0)(0), conv_weights(8))+
                 addsub_pix(rows(0)(1), conv_weights(7));
  conv_sum(1) <= addsub_pix(rows(0)(2), conv_weights(6))+
                 addsub_pix(rows(1)(0), conv_weights(5));
  conv_sum(2) <= addsub_pix(rows(1)(1), conv_weights(4))+
                 addsub_pix(rows(1)(2), conv_weights(3));
  conv_sum(3) <= addsub_pix(rows(2)(0), conv_weights(2))+
                 addsub_pix(rows(2)(1), conv_weights(1));
  conv_sum(4) <= addsub_pix(rows(2)(2), conv_weights(0)) +
                 conv_sum(3);
  --layer 1
  conv_sum(5) <= conv_sum(0) + conv_sum(1);
  conv_sum(6) <= conv_sum(2) + conv_sum(4);
  --layer2
  conv_sum(7) <= conv_sum(5) + conv_sum(6);


  process(clk)
  begin
    if rising_edge(clk) then

      --rotatie rows
      conv_valid_data <= conv_valid_data(1 downto 0) & valid_in;
      rows(2)         <= in_row;
      rows(1)         <= rows(2);
      rows(0)         <= rows(1);
      conv_data_out   <= std_logic_vector(RESIZE(conv_sum(7), conv_data_out'length));
      conv_we         <= bool_to_sl(conv_valid_data = "111");
      conv_done       <= conv_valid_data(2);
    end if;
  end process;


  -----------------------------------------------------------------------------
  -- COMMON STUFF
  -----------------------------------------------------------------------------
  process (clk) is
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      valid_out        <= '0';
      write_enable_out <= '0';
      data_out         <= (others => '0');

      if func3 = VCUSTOM0_FUNC3 then
        --word to byte conversion
        valid_out        <= valid_in;
        write_enable_out <= valid_in;
        data_out         <= cust0_out_data;
      end if;
      if func3 = VCUSTOM1_FUNC3 then
        --setup weights
        valid_out <= valid_in;
      --no writeback
      end if;
      if func3 = VCUSTOM2_FUNC3 then
        --convolution instruction
        valid_out        <= conv_done;
        write_enable_out <= conv_we;
        data_out         <= conv_data_out;
      end if;

    end if;
  end process;

end architecture rtl;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;
use work.constants_pkg.all;
use work.rv_components.all;

entity lve_top is
  generic(
    REGISTER_SIZE    : natural;
    SLAVE_DATA_WIDTH : natural := 32;
    SCRATCHPAD_SIZE  : integer := 1024;
    FAMILY           : string  := "ALTERA");
  port(
    clk            : in std_logic;
    scratchpad_clk : in std_logic;
    reset          : in std_logic;
    instruction    : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_instr    : in std_logic;
    stall_to_lve   : in std_logic;
    rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);

    slave_address  : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
    slave_read_en  : in  std_logic;
    slave_write_en : in  std_logic;
    slave_byte_en  : in  std_logic_vector(SLAVE_DATA_WIDTH/8 -1 downto 0);
    slave_data_in  : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_data_out : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_ack      : out std_logic;

    stall_from_lve       : out    std_logic;
    lve_alu_data1        : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_alu_data2        : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_alu_source_valid : out    std_logic;
    lve_alu_result       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_alu_result_valid : in     std_logic
    );
end entity;

architecture rtl of lve_top is

  component ram_4port is
    generic(
      MEM_DEPTH : natural;
      MEM_WIDTH : natural;
      FAMILY    : string := "ALTERA");
    port(
      clk            : in  std_logic;
      scratchpad_clk : in  std_logic;
      reset          : in  std_logic;
                                        --read source A
      raddr0         : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      ren0           : in  std_logic;
      scalar_value   : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      scalar_enable  : in  std_logic;
      data_out0      : out std_logic_vector(MEM_WIDTH-1 downto 0);

                                        --read source B
      raddr1      : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      ren1        : in  std_logic;
      enum_value  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      enum_enable : in  std_logic;
      data_out1   : out std_logic_vector(MEM_WIDTH-1 downto 0);
      ack01       : out std_logic;
      --write dest
      waddr2      : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      byte_en2    : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      wen2        : in  std_logic;
      data_in2    : in  std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --external slave port
      rwaddr3     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      wen3        : in  std_logic;
      ren3        : in  std_logic;      --cannot be asserted same cycle as wen3
      byte_en3    : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      data_in3    : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      ack3        : out std_logic;
      data_out3   : out std_logic_vector(MEM_WIDTH-1 downto 0));
  end component;



  constant CUSTOM0 : std_logic_vector(6 downto 0) := "0101011";

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
  alias cmv_instr : std_logic is instruction(28);
  alias acc       : std_logic is instruction(26);
  alias func_bit3 : std_logic is instruction(25);
  alias func      : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias srca_s    : std_logic is instruction(10);
  alias srcb_e    : std_logic is instruction(11);
  alias dim       : std_logic_vector(1 downto 0) is instruction(9 downto 8);
  alias sign_d    : std_logic is instruction(7);

  alias func3 : std_logic_vector is instruction(INSTR_FUNC3'range);

  signal lve_result_valid : std_logic;
  signal lve_source_valid : std_logic;
  signal cmv_result_valid : std_logic;
  signal lve_result       : std_logic_vector(lve_alu_result'range);
  signal cmv_result       : std_logic_vector(lve_alu_result'range);
  signal lve_data1        : std_logic_vector(lve_alu_data1'range);
  signal lve_data2        : std_logic_vector(lve_alu_data2'range);

  signal cmv_write_en : std_logic;

  signal srca_ptr            : unsigned(REGISTER_SIZE-1 downto 0);
  signal srcb_ptr            : unsigned(REGISTER_SIZE-1 downto 0);
  signal dest_ptr            : unsigned(REGISTER_SIZE-1 downto 0);
  signal read_vector_length  : unsigned(15 downto 0);
  signal write_vector_length : unsigned(15 downto 0);
  signal writeback_data      : unsigned(REGISTER_SIZE-1 downto 0);

  signal waddr2   : std_logic_vector(log2(SCRATCHPAD_SIZE/4)-1 downto 0);
  signal byte_en2 : std_logic_vector(3 downto 0);

  signal scalar_value : unsigned(REGISTER_SIZE-1 downto 0);

  signal srca_data_read : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal srcb_data_read : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal dest_data      : unsigned(REGISTER_SIZE-1 downto 0);
  signal enum_count     : unsigned(REGISTER_SIZE-1 downto 0);

  signal rd_en         : std_logic;
  signal first_element : std_logic;
  signal write_enable  : std_logic;

  signal valid_lve_instr : std_logic;


  signal accumulation_register : unsigned(REGISTER_SIZE - 1 downto 0);
  signal accumulation_result   : unsigned(REGISTER_SIZE - 1 downto 0);

  signal pointer_increment : unsigned(15 downto 0);
  signal dest_incr         : unsigned(15 downto 0);
  signal src_incr          : unsigned(15 downto 0);

  signal dest_size, src_size : std_logic_vector(1 downto 0);
  signal readdata_valid      : std_logic;
  signal eqz                 : std_logic;

  signal enum_enable          : std_logic;
  signal scalar_enable        : std_logic;
  signal lve_ack              : std_logic;
  signal external_port_enable : std_logic;

  signal slave_address_reg    : std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
  signal slave_read_en_reg    : std_logic;
  signal slave_write_en_reg   : std_logic;
  signal slave_byte_en_reg    : std_logic_vector(SLAVE_DATA_WIDTH/8 -1 downto 0);
  signal slave_data_in_reg    : std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);


  function align_input (
    sign  : std_logic;
    size  : std_logic_vector(1 downto 0);
    align : std_logic_vector(1 downto 0);
    data  : std_logic_vector(REGISTER_SIZE-1 downto 0))
    return std_logic_vector is
    variable data_8bit  : std_logic_vector(7 downto 0);
    variable data_9bit  : signed(8 downto 0);
    variable data_32bit : signed(8 downto 0);
  begin  -- function select_byte

    if size = LVE_BYTE_SIZE then
      if align = "00" then
        data_8bit := data(REGISTER_SIZE-1 downto REGISTER_SIZE-8);
      elsif align = "01" then
        data_8bit := data(REGISTER_SIZE-1-8 downto REGISTER_SIZE-8-8);
      elsif align = "10" then
        data_8bit := data(REGISTER_SIZE-1-16 downto REGISTER_SIZE-8-16);
      else
        data_8bit := data(REGISTER_SIZE-1-24 downto REGISTER_SIZE-8-24);
      end if;
      data_9bit := signed((data_8bit(7) and sign) & data_8bit);

      return std_logic_vector(RESIZE(data_9bit, 32));
    end if;
    return data;
  end function align_input;

  --Custom instruction
  signal ci_valid_in     : std_logic;
  signal ci_result_valid : std_logic;
  signal ci_write_en     : std_logic;
  signal ci_result       : std_logic_vector(REGISTER_SIZE-1 downto 0);
begin

  lve_alu_data1        <= lve_data1;
  lve_alu_data2        <= lve_data2;
  lve_alu_source_valid <= lve_source_valid and not cmv_instr;
  lve_result_valid     <= lve_alu_result_valid when cmv_instr = '0' else cmv_result_valid;

  lve_result <= lve_alu_result when cmv_instr = '0' else
                cmv_result;

  valid_lve_instr <= valid_instr when major_op = CUSTOM0 else '0';

  pointer_increment <= unsigned(rs2_data(rs2_data'left downto rs2_data'length - pointer_increment'length));
  with dest_size select
    dest_incr <=
    SHIFT_LEFT(pointer_increment, 2) when LVE_WORD_SIZE,
    --Don't enable halfe words
    pointer_increment                when others;

  --source bust be aways word
  with src_size select
    src_incr <=
    SHIFT_LEFT(pointer_increment, 2) when LVE_WORD_SIZE,
    --Don't enable halfe words
    pointer_increment                when others;

  --src_incr <= SHIFT_LEFT(pointer_increment, 2);

  process (clk) is
  begin  -- process
    if rising_edge(clk) then
      slave_address_reg  <= slave_address;
      slave_read_en_reg  <= slave_read_en;
      slave_write_en_reg <= slave_write_en;
      slave_byte_en_reg  <= slave_byte_en;
      slave_data_in_reg  <= slave_data_in;
    end if;
  end process;

  external_port_enable <= slave_read_en_reg or slave_write_en_reg;

  --instruction parsing process
  address_gen : process(clk)
  begin
    if rising_edge(clk) then

      if valid_lve_instr = '1' and not stall_to_lve = '1' then

        if lve_result_valid = '1' then
          if acc = '0' then
            dest_ptr <= dest_ptr + dest_incr;
          end if;
          write_vector_length   <= write_vector_length - 1;
          accumulation_register <= accumulation_result;
        end if;

        if is_prefix = '1' then
          first_element <= '1';
          scalar_value  <= unsigned(rs1_data);
          enum_count    <= to_unsigned(0, enum_count'length);

          srca_ptr  <= unsigned(rs1_data);
          srcb_ptr  <= unsigned(rs2_data);
          dest_size <= instruction(14 downto 13);
          src_size  <= instruction(12 downto 11);
        else
          if external_port_enable = '0' then
            srca_ptr <= srca_ptr+ src_incr;
            srcb_ptr <= srcb_ptr+ src_incr;
          end if;

          if first_element = '1' then
            dest_ptr              <= unsigned(rs1_data);
            write_vector_length   <= unsigned(rs2_data(write_vector_length'range));
            read_vector_length    <= unsigned(rs2_data(write_vector_length'range));
            accumulation_register <= to_unsigned(0, accumulation_register'length);
          else
            if external_port_enable = '0' then
              enum_count <= enum_count +1;
              if read_vector_length /= 0 then
                read_vector_length <= read_vector_length - 1;
              end if;
            end if;

          end if;
          first_element <= '0';
        end if;
      else
        write_vector_length <= to_unsigned(0, write_vector_length'length);
      end if;
      if reset = '1' then
        srca_ptr <= (others => '0');
        srcb_ptr <= (others => '0');
        dest_ptr <= (others => '0');

        first_element      <= '0';
        read_vector_length <= to_unsigned(0, read_vector_length'length);
      end if;
    end if;

  end process;

  stall_from_lve <= valid_lve_instr and not is_prefix when first_element = '1' or (read_vector_length /= 0) or (write_vector_length /= 0) else '0';

  rd_en <= valid_lve_instr when external_port_enable = '0' and (read_vector_length > 1 or first_element = '1') else '0';


  --lve_data1 <= align_input(sign_a, src_size, s_align, srca_data_read);
  --lve_data2 <= align_input(sign_b, src_size, s_align, srcb_data_read);
  lve_data1 <= srca_data_read;
  lve_data2 <= srcb_data_read;

  writeback_proc : process(clk)
    variable tmp_data : unsigned(lve_result'range);
  begin
    if rising_edge(clk) then
      tmp_data := unsigned(lve_result);
      waddr2   <= std_logic_vector(dest_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2));
      if acc = '1' then
        tmp_data := accumulation_result;
      end if;
      byte_en2       <= "1111";
      writeback_data <= tmp_data;
      if dest_size = LVE_BYTE_SIZE then
        writeback_data <= tmp_data(7 downto 0) &tmp_data(7 downto 0)&tmp_data(7 downto 0) &tmp_data(7 downto 0);
        case dest_ptr(1 downto 0) is
          when "00" =>
            byte_en2 <= "0001";
          when "01" =>
            byte_en2 <= "0010";
          when "10" =>
            byte_en2 <= "0100";
          when "11" =>
            byte_en2 <= "1000";
          when others => null;
        end case;
      end if;
      write_enable <= (lve_alu_result_valid or cmv_write_en) and (valid_lve_instr and not is_prefix);
    end if;
  end process;


  accumulation_result <= accumulation_register + unsigned(lve_result);




  -----------------------------------------------------------------------------
  -- Conditional moves
  -----------------------------------------------------------------------------
  eqz <= bool_to_sl(unsigned(lve_data2) = 0);
  process(clk)
  begin
    if rising_edge(clk) then
      cmv_result_valid <= '0';
      cmv_write_en     <= '0';
      cmv_result       <= lve_data1;
      if valid_lve_instr = '1' and cmv_instr = '1' then
        if func3 = LVE_VCMV_Z_FUNC3 then
          if lve_source_valid = '1' then
            cmv_result_valid <= '1';
            if eqz = '1' then
              cmv_write_en <= '1';
            end if;
          end if;
        elsif func3 = LVE_VCMV_NZ_FUNC3 then
          if lve_source_valid = '1' then
            cmv_result_valid <= '1';
            if eqz = '0' then
              cmv_write_en <= '1';
            end if;
          end if;
        else
          cmv_result_valid <= ci_result_valid;
          cmv_result       <= ci_result;
          cmv_write_en     <= ci_write_en;
        end if;
      end if;
    end if;
  end process;

  ci_valid_in <= '1' when ((valid_lve_instr and lve_source_valid) = '1' and
                           func3 /= LVE_VCMV_Z_FUNC3 and
                           func3 /= LVE_VCMV_NZ_FUNC3) else
                 '0';
  the_lve_ci : component lve_ci
    generic map (
      REGISTER_SIZE => REGISTER_SIZE
      )
    port map (
      clk   => clk,
      reset => reset,

      func3 => func3,

      valid_in => ci_valid_in,
      data1_in => lve_data1,
      data2_in => lve_data2,

      align1_in => std_logic_vector(srca_ptr(1 downto 0)),
      align2_in => std_logic_vector(srcb_ptr(1 downto 0)),


      valid_out        => ci_result_valid,
      write_enable_out => ci_write_en,
      data_out         => ci_result
      );


  scalar_enable <= srca_s;
  enum_enable   <= srcb_e;


  scratchpad_memory : component ram_4port
    generic map (
      MEM_WIDTH => 32,
      MEM_DEPTH => SCRATCHPAD_SIZE/4,
      FAMILY    => FAMILY)
    port map (
      clk            => clk,
      scratchpad_clk => scratchpad_clk,
      reset          => reset,
      raddr0         => std_logic_vector(srca_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2)),
      ren0           => rd_en,
      scalar_value   => std_logic_vector(scalar_value),
      scalar_enable  => scalar_enable,

      data_out0   => srca_data_read,
      raddr1      => std_logic_vector(srcb_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2)),
      ren1        => rd_en,
      data_out1   => srcb_data_read,
      enum_value  => std_logic_vector(enum_count),
      enum_enable => enum_enable,

      ack01     => lve_source_valid,
      waddr2    => waddr2,
      byte_en2  => byte_en2,
      wen2      => write_enable,
      data_in2  => std_logic_vector(writeback_data),
      rwaddr3   => slave_address_reg(log2(SCRATCHPAD_SIZE)-1 downto 2),
      ren3      => slave_read_en_reg,
      wen3      => slave_write_en_reg,
      byte_en3  => slave_byte_en_reg,
      data_out3 => slave_data_out,
      ack3      => slave_ack,
      data_in3  => slave_data_in_reg);

end architecture;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.rv_components.all;
use work.utils.all;
use work.constants_pkg.all;

entity orca_core is

  generic (
    REGISTER_SIZE      : integer;
    RESET_VECTOR       : integer;
    MULTIPLY_ENABLE    : natural range 0 to 1;
    DIVIDE_ENABLE      : natural range 0 to 1;
    SHIFTER_MAX_CYCLES : natural;
    COUNTER_LENGTH     : natural;
    ENABLE_EXCEPTIONS  : natural;
    BRANCH_PREDICTORS  : natural;
    PIPELINE_STAGES    : natural range 4 to 5;
    NUM_EXT_INTERRUPTS : integer range 0 to 32;
    LVE_ENABLE         : natural range 0 to 1;
    SCRATCHPAD_SIZE    : integer;
    FAMILY             : string);

  port(clk            : in std_logic;
       scratchpad_clk : in std_logic;
       reset          : in std_logic;

       --avalon master bus
       core_data_address              : out std_logic_vector(REGISTER_SIZE-1 downto 0);
       core_data_byteenable           : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
       core_data_read                 : out std_logic;
       core_data_readdata             : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => 'X');
       core_data_write                : out std_logic;
       core_data_writedata            : out std_logic_vector(REGISTER_SIZE-1 downto 0);
       core_data_ack                  : in  std_logic                                  := '0';
       --avalon master bus
       core_instruction_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
       core_instruction_read          : out std_logic;
       core_instruction_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => 'X');
       core_instruction_waitrequest   : in  std_logic                                  := '0';
       core_instruction_readdatavalid : in  std_logic                                  := '0';

       --memory-bus scratchpad-slave
       sp_address   : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
       sp_byte_en   : in  std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
       sp_write_en  : in  std_logic;
       sp_read_en   : in  std_logic;
       sp_writedata : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
       sp_readdata  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
       sp_ack       : out std_logic;

       external_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0) := (others => '0')
       );

end entity Orca_core;

architecture rtl of orca_core is
  constant SIGN_EXTENSION_SIZE : integer := 20;

  --signals going into fetch
  signal if_valid_out : std_logic;

  --signals going into decode
  signal d_instr     : std_logic_vector(INSTRUCTION_SIZE -1 downto 0);
  signal d_pc        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal d_br_taken  : std_logic;
  signal d_valid     : std_logic;
  signal d_valid_out : std_logic;

  signal wb_data        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_sel         : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_en          : std_logic;
  signal wb_valid       : std_logic;
  --signals going into execute
  signal e_instr        : std_logic_vector(INSTRUCTION_SIZE -1 downto 0);
  signal e_subseq_instr : std_logic_vector(INSTRUCTION_SIZE -1 downto 0);
  signal e_subseq_valid : std_logic;
  signal e_pc           : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal e_br_taken     : std_logic;
  signal e_valid        : std_logic;
  signal e_data_ack     : std_logic;
  signal pipeline_empty : std_logic;

  signal execute_stalled : std_logic;
  signal rs1_data        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sign_extension  : std_logic_vector(REGISTER_SIZE-12-1 downto 0);

  signal pipeline_flush : std_logic;

  signal data_address    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_byte_en    : std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
  signal data_write_en   : std_logic;
  signal data_read_en    : std_logic;
  signal data_write_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal data_read_data  : std_logic_vector(REGISTER_SIZE-1 downto 0);


  signal instr_address : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instr_data    : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

  signal instr_read_wait : std_logic;
  signal instr_read_en   : std_logic;
  signal instr_readvalid : std_logic;

  -- Interrupt lines
  signal e_interrupt_pending : std_logic;
  signal ext_int_resized     : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal branch_pred_to_instr_fetch : std_logic_vector(REGISTER_SIZE*2 + 3-1 downto 0);

  signal decode_flushed : std_logic;
  signal ifetch_next_pc : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal e_sp_addr : std_logic_vector(CONDITIONAL(LVE_ENABLE = 1, sp_address'length,0)-1 downto 0);
begin  -- architecture rtl
  pipeline_flush <= branch_get_flush(branch_pred_to_instr_fetch);


  instr_fetch : component instruction_fetch
    generic map (
      REGISTER_SIZE     => REGISTER_SIZE,
      RESET_VECTOR      => RESET_VECTOR,
      BRANCH_PREDICTORS => BRANCH_PREDICTORS)
    port map (
      clk                => clk,
      reset              => reset,
      downstream_stalled => execute_stalled,
      interrupt_pending  => e_interrupt_pending,
      branch_pred        => branch_pred_to_instr_fetch,

      instr_out       => d_instr,
      pc_out          => d_pc,
      next_pc_out     => ifetch_next_pc,
      br_taken        => d_br_taken,
      valid_instr_out => if_valid_out,
      read_address    => instr_address,
      read_en         => instr_read_en,
      read_data       => instr_data,
      read_datavalid  => instr_readvalid,
      read_wait       => instr_read_wait);

  d_valid <= if_valid_out and not pipeline_flush;

  D : component decode
    generic map(
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      PIPELINE_STAGES     => PIPELINE_STAGES-3)
    port map(
      clk            => clk,
      reset          => reset,
      stall          => execute_stalled,
      flush          => pipeline_flush,
      instruction    => d_instr,
      valid_input    => d_valid,
      --writeback signals
      wb_sel         => wb_sel,
      wb_data        => wb_data,
      wb_enable      => wb_en,
      wb_valid       => wb_valid,
      --output signals
      rs1_data       => rs1_data,
      rs2_data       => rs2_data,
      sign_extension => sign_extension,
      --inputs just for carrying to next pipeline stage
      br_taken_in    => d_br_taken,
      pc_curr_in     => d_pc,
      br_taken_out   => e_br_taken,
      pc_curr_out    => e_pc,
      instr_out      => e_instr,
      subseq_instr   => e_subseq_instr,
      subseq_valid   => e_subseq_valid,
      valid_output   => d_valid_out,
      decode_flushed => decode_flushed);

  e_valid <= d_valid_out and not pipeline_flush;
  e_sp_addr <= sp_address(e_sp_addr'range);
  X : component execute
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      RESET_VECTOR        => RESET_VECTOR,
      MULTIPLY_ENABLE     => MULTIPLY_ENABLE = 1,
      DIVIDE_ENABLE       => DIVIDE_ENABLE = 1,
      SHIFTER_MAX_CYCLES  => SHIFTER_MAX_CYCLES,
      COUNTER_LENGTH      => COUNTER_LENGTH,
      ENABLE_EXCEPTIONS   => ENABLE_EXCEPTIONS = 1,
      SCRATCHPAD_SIZE     => SCRATCHPAD_SIZE,
      FAMILY              => FAMILY)
    port map (
      clk                => clk,
      scratchpad_clk     => scratchpad_clk,
      reset              => reset,
      valid_input        => e_valid,
      br_taken_in        => e_br_taken,
      pc_current         => e_pc,
      instruction        => e_instr,
      subseq_instr       => e_subseq_instr,
      subseq_valid       => e_subseq_valid,
      rs1_data           => rs1_data,
      rs2_data           => rs2_data,
      sign_extension     => sign_extension,
      wb_sel             => wb_sel,
      wb_data            => wb_data,
      wb_enable          => wb_en,
      valid_output       => wb_valid,
      branch_pred        => branch_pred_to_instr_fetch,
      ifetch_next_pc     => ifetch_next_pc,
      stall_from_execute => execute_stalled,

      --Memory bus
      address   => data_address,
      byte_en   => data_byte_en,
      write_en  => data_write_en,
      read_en   => data_read_en,
      writedata => data_write_data,
      readdata  => data_read_data,
      data_ack  => e_data_ack,

      --sp slave
      sp_address   => e_sp_addr,
      sp_byte_en   => sp_byte_en,
      sp_write_en  => sp_write_en,
      sp_read_en   => sp_read_en,
      sp_writedata => sp_writedata,
      sp_readdata  => sp_readdata,
      sp_ack       => sp_ack,

      -- Interrupt lines
      external_interrupts => ext_int_resized,
      pipeline_empty      => decode_flushed,
      interrupt_pending   => e_interrupt_pending);

  ext_int_resized <= std_logic_vector(RESIZE(unsigned(external_interrupts), ext_int_resized'length));

  core_data_address    <= data_address;
  core_data_byteenable <= data_byte_en;
  core_data_read       <= data_read_en;
  core_data_write      <= data_write_en;
  core_data_writedata  <= data_write_data;

  data_read_data <= core_data_readdata;
  e_data_ack     <= core_data_ack;

  core_instruction_address <= instr_address;
  core_instruction_read    <= instr_read_en;
  instr_data               <= core_instruction_readdata;
  instr_read_wait          <= core_instruction_waitrequest;
  instr_readvalid          <= core_instruction_readdatavalid;

end architecture rtl;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.rv_components.all;
use work.utils.all;

entity Orca is
  generic (
    REGISTER_SIZE   : integer              := 32;
    --BUS Select
    AVALON_ENABLE   : integer range 0 to 1 := 0;
    WISHBONE_ENABLE : integer range 0 to 1 := 0;
    AXI_ENABLE      : integer range 0 to 1 := 0;

    RESET_VECTOR          : integer               := 16#00000200#;
    MULTIPLY_ENABLE       : natural range 0 to 1  := 0;
    DIVIDE_ENABLE         : natural range 0 to 1  := 0;
    SHIFTER_MAX_CYCLES    : natural               := 1;
    COUNTER_LENGTH        : natural               := 0;
    ENABLE_EXCEPTIONS     : natural               := 1;
    BRANCH_PREDICTORS     : natural               := 0;
    PIPELINE_STAGES       : natural range 4 to 5  := 5;
    LVE_ENABLE            : natural range 0 to 1  := 0;
    ENABLE_EXT_INTERRUPTS : natural range 0 to 1  := 0;
    NUM_EXT_INTERRUPTS    : integer range 1 to 32 := 1;
    SCRATCHPAD_ADDR_BITS  : integer               := 10;
    FAMILY                : string                := "ALTERA");
  port(
    clk            : in std_logic;
    scratchpad_clk : in std_logic;
    reset          : in std_logic;

    --avalon data bus
    avm_data_address              : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_data_byteenable           : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    avm_data_read                 : out std_logic;
    avm_data_readdata             : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := x"00000000";
    avm_data_write                : out std_logic;
    avm_data_writedata            : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_data_waitrequest          : in  std_logic                                  := '0';
    avm_data_readdatavalid        : in  std_logic                                  := '0';
    --avalon instruction bus
    avm_instruction_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_instruction_read          : out std_logic;
    avm_instruction_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := x"00000000";
    avm_instruction_waitrequest   : in  std_logic                                  := '0';
    avm_instruction_readdatavalid : in  std_logic                                  := '0';
    --wishbone data bus
    data_ADR_O                    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_DAT_I                    : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_DAT_O                    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    data_WE_O                     : out std_logic;
    data_SEL_O                    : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    data_STB_O                    : out std_logic;
    data_ACK_I                    : in  std_logic;
    data_CYC_O                    : out std_logic;
    data_CTI_O                    : out std_logic_vector(2 downto 0);
    data_STALL_I                  : in  std_logic;
    --wishbone instruction bus
    instr_ADR_O                   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_DAT_I                   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_STB_O                   : out std_logic;
    instr_ACK_I                   : in  std_logic;
    instr_CYC_O                   : out std_logic;
    instr_CTI_O                   : out std_logic_vector(2 downto 0);
    instr_STALL_I                 : in  std_logic;

    --AXI

    -- Write address channel ---------------------------------------------------------
    data_AWID    : out std_logic_vector(3 downto 0);  -- ID for write address signals
    data_AWADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);  -- Address of the first transferin a burst
    data_AWLEN   : out std_logic_vector(3 downto 0);  -- Number of transfers in a burst, burst must not cross 4 KB boundary, burst length of 1 to 16 transfers in AXI3
    data_AWSIZE  : out std_logic_vector(2 downto 0);  -- Maximum number of bytes to transfer in each data transfer (beat) in a burst
    -- See Table A3-2 for AxSIZE encoding
    -- 0b010 => 4 bytes in a transfer
    data_AWBURST : out std_logic_vector(1 downto 0);  -- defines the burst type, fixed, incr, or wrap
    -- fixed accesses the same address repeatedly, incr increments the address for each transfer, wrap = incr except rolls over to lower address if upper limit is reached
    -- see table A3-3 for AxBURST encoding
    data_AWLOCK  : out std_logic_vector(1 downto 0);  -- Ensures that only the master can access the targeted slave region
    data_AWCACHE : out std_logic_vector(3 downto 0);  -- specifies memory type, see Table A4-5
    data_AWPROT  : out std_logic_vector(2 downto 0);  -- specifies access permission, see Table A4-6
    data_AWVALID : out std_logic;  -- Valid address and control information on bus, asserted until slave asserts AWREADY
    data_AWREADY : in  std_logic := '-';  -- Slave is ready to accept address and control signals

    -- Write data channel ------------------------------------------------------------
    data_WID    : out std_logic_vector(3 downto 0);  -- ID for write data signals
    data_WDATA  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    data_WSTRB  : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);  -- Specifies which byte lanes contain valid information
    data_WLAST  : out std_logic;  -- Asserted when master is driving the final write transfer in the burst
    data_WVALID : out std_logic;  -- Valid data available on bus, asserted until slave asserts WREADY
    data_WREADY : in  std_logic := '-';  -- Slave is now available to accept write data

    -- Write response channel ---------------------------------------------------------
    data_BID    : in  std_logic_vector(3 downto 0) := (others => '-');  -- ID for write response
    data_BRESP  : in  std_logic_vector(1 downto 0) := (others => '-');  -- Slave response (with error codes) to a write
    data_BVALID : in  std_logic                    := '-';  -- Indicates that the channel is signaling a valid write response
    data_BREADY : out std_logic;  -- Indicates that master has acknowledged write response

    -- Read address channel ------------------------------------------------------------
    data_ARID    : out std_logic_vector(3 downto 0);
    data_ARADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    data_ARLEN   : out std_logic_vector(3 downto 0);
    data_ARSIZE  : out std_logic_vector(2 downto 0);
    data_ARBURST : out std_logic_vector(1 downto 0);
    data_ARLOCK  : out std_logic_vector(1 downto 0);
    data_ARCACHE : out std_logic_vector(3 downto 0);
    data_ARPROT  : out std_logic_vector(2 downto 0);
    data_ARVALID : out std_logic;
    data_ARREADY : in  std_logic := '-';

    -- Read data channel -----------------------------------------------------------------
    data_RID    : in  std_logic_vector(3 downto 0)                := (others => '-');
    data_RDATA  : in  std_logic_vector(REGISTER_SIZE -1 downto 0) := (others => '-');
    data_RRESP  : in  std_logic_vector(1 downto 0)                := (others => '-');
    data_RLAST  : in  std_logic                                   := '-';
    data_RVALID : in  std_logic                                   := '-';
    data_RREADY : out std_logic;

    -- Read address channel ------------------------------------------------------------
    instr_ARID    : out std_logic_vector(3 downto 0);
    instr_ARADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    instr_ARLEN   : out std_logic_vector(3 downto 0);
    instr_ARSIZE  : out std_logic_vector(2 downto 0);
    instr_ARBURST : out std_logic_vector(1 downto 0);
    instr_ARLOCK  : out std_logic_vector(1 downto 0);
    instr_ARCACHE : out std_logic_vector(3 downto 0);
    instr_ARPROT  : out std_logic_vector(2 downto 0);
    instr_ARVALID : out std_logic;
    instr_ARREADY : in  std_logic := '-';

    -- Read data channel -----------------------------------------------------------------
    instr_RID    : in  std_logic_vector(3 downto 0)                := (others => '-');
    instr_RDATA  : in  std_logic_vector(REGISTER_SIZE -1 downto 0) := (others => '-');
    instr_RRESP  : in  std_logic_vector(1 downto 0)                := (others => '-');
    instr_RLAST  : in  std_logic                                   := '-';
    instr_RVALID : in  std_logic                                   := '-';
    instr_RREADY : out std_logic;

    instr_AWID    : out std_logic_vector(3 downto 0);
    instr_AWADDR  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    instr_AWLEN   : out std_logic_vector(3 downto 0);
    instr_AWSIZE  : out std_logic_vector(2 downto 0);
    instr_AWBURST : out std_logic_vector(1 downto 0);
    instr_AWLOCK  : out std_logic_vector(1 downto 0);
    instr_AWCACHE : out std_logic_vector(3 downto 0);
    instr_AWPROT  : out std_logic_vector(2 downto 0);
    instr_AWVALID : out std_logic;
    instr_AWREADY : in  std_logic                    := '-';
    instr_WID     : out std_logic_vector(3 downto 0);
    instr_WDATA   : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    instr_WSTRB   : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    instr_WLAST   : out std_logic;
    instr_WVALID  : out std_logic;
    instr_WREADY  : in  std_logic                    := '-';
    instr_BID     : in  std_logic_vector(3 downto 0) := (others => '-');
    instr_BRESP   : in  std_logic_vector(1 downto 0) := (others => '-');
    instr_BVALID  : in  std_logic                    := '-';
    instr_BREADY  : out std_logic;

    -------------------------------------------------------------------------------
    -- Scratchpad Slave
    -------------------------------------------------------------------------------
    --avalon
    avm_scratch_address       : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
    avm_scratch_byteenable    : in  std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    avm_scratch_read          : in  std_logic;
    avm_scratch_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_scratch_write         : in  std_logic;
    avm_scratch_writedata     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    avm_scratch_waitrequest   : out std_logic;
    avm_scratch_readdatavalid : out std_logic;

    --wishbone
    sp_ADR_I   : in  std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
    sp_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_WE_I    : in  std_logic;
    sp_SEL_I   : in  std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    sp_STB_I   : in  std_logic;
    sp_ACK_O   : out std_logic;
    sp_CYC_I   : in  std_logic;
    sp_CTI_I   : in  std_logic_vector(2 downto 0);
    sp_STALL_O : out std_logic;


    global_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0) := (others => '0')
    );

end entity Orca;

architecture rtl of Orca is

  signal core_data_address    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_data_byteenable : std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
  signal core_data_read       : std_logic;
  signal core_data_readdata   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_data_write      : std_logic;
  signal core_data_writedata  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_data_ack        : std_logic;

  signal core_instruction_address       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_instruction_read          : std_logic;
  signal core_instruction_readdata      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal core_instruction_waitrequest   : std_logic;
  signal core_instruction_readdatavalid : std_logic;

  signal sp_address   : std_logic_vector(SCRATCHPAD_ADDR_BITS-1 downto 0);
  signal sp_byte_en   : std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
  signal sp_write_en  : std_logic;
  signal sp_read_en   : std_logic;
  signal sp_writedata : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sp_readdata  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sp_ack       : std_logic;




begin  -- architecture rtl
  assert AVALON_ENABLE + WISHBONE_ENABLE + AXI_ENABLE = 1 report "Exactly one bus type must be enabled" severity failure;


  -----------------------------------------------------------------------------
  -- AVALON
  -----------------------------------------------------------------------------
  avalon_enabled : if AVALON_ENABLE = 1 generate
    signal is_writing : std_logic;
    signal is_reading : std_logic;
    signal write_ack  : std_logic;

    signal ack_mask : std_logic;
  begin
    core_data_readdata <= avm_data_readdata;

    core_data_ack  <= avm_data_readdatavalid or write_ack;
    avm_data_write <= is_writing;
    avm_data_read  <= is_reading;
    process(clk)

    begin
      if rising_edge(clk) then


        if (is_writing or is_reading) = '1' and avm_data_waitrequest = '1' then

        else
          is_reading          <= core_data_read;
          avm_data_address    <= core_data_address;
          is_writing          <= core_data_write;
          avm_data_writedata  <= core_data_writedata;
          avm_data_byteenable <= core_data_byteenable;
        end if;

        write_ack <= '0';
        if is_writing = '1' and avm_data_waitrequest = '0' then
          write_ack <= '1';
        end if;
      end if;

    end process;

    avm_instruction_address        <= core_instruction_address;
    avm_instruction_read           <= core_instruction_read;
    core_instruction_readdata      <= avm_instruction_readdata;
    core_instruction_waitrequest   <= avm_instruction_waitrequest;
    core_instruction_readdatavalid <= avm_instruction_readdatavalid;

    sp_address              <= avm_scratch_address;
    sp_byte_en              <= avm_scratch_byteenable;
    sp_read_en              <= avm_scratch_read;
    sp_write_en             <= avm_scratch_write;
    sp_writedata            <= avm_scratch_writedata;
    avm_scratch_readdata    <= sp_readdata;
    avm_scratch_waitrequest <= '0';
    process(clk)
    begin
      if rising_edge(clk) then
        if sp_ack = '1' then
          ack_mask <= '0';
        end if;
        if sp_read_en = '1' then
          ack_mask <= '1';
        end if;
      end if;
    end process;
    avm_scratch_readdatavalid <= sp_ack and ack_mask;

  end generate avalon_enabled;

  -----------------------------------------------------------------------------
  -- WISHBONE
  -----------------------------------------------------------------------------
  wishbone_enabled : if WISHBONE_ENABLE = 1 generate
    signal is_read_transaction : std_logic;
  begin
    core_data_readdata <= data_DAT_I;
    core_data_ack      <= data_ACK_I;

    instr_ADR_O                    <= core_instruction_address;
    instr_CYC_O                    <= core_instruction_read;
    instr_STB_O                    <= core_instruction_read;
    core_instruction_readdata      <= instr_DAT_I;
    core_instruction_waitrequest   <= instr_STALL_I;
    core_instruction_readdatavalid <= instr_ACK_I;

    process(clk)
    begin
      if rising_edge(clk) then
        if data_STALL_I = '0' then
          data_ADR_O <= core_data_address;
          data_SEL_O <= core_data_byteenable;
          data_CYC_O <= core_data_read or core_data_write;
          data_STB_O <= core_data_read or core_data_write;
          data_WE_O  <= core_data_write;
          data_DAT_O <= core_data_writedata;
        end if;
      end if;
    end process;

    --scrachpad slave
    sp_address   <= sp_ADR_I;
    sp_DAT_O     <= sp_readdata;
    sp_writedata <= sp_DAT_I;
    sp_write_en  <= sp_WE_I and sp_STB_I and sp_CYC_I;
    sp_read_en   <= not sp_WE_I and sp_STB_I and sp_CYC_I;
    sp_byte_en   <= sp_SEL_I;
    sp_ACK_O     <= sp_ack;
    sp_STALL_O   <= '0';


  end generate wishbone_enabled;

  axi_enabled : if AXI_ENABLE = 1 generate
    -- 1 transfer
    constant BURST_LEN  : std_logic_vector(3 downto 0) := "0000";
    -- 4 bytes in transfer
    constant BURST_SIZE : std_logic_vector(2 downto 0) := "010";
    -- incremental bursts
    constant BURST_INCR : std_logic_vector(1 downto 0) := "01";


    signal core_data_stall1        : std_logic;
    signal core_data_stall2        : std_logic;
    signal core_data_stall3        : std_logic;
    signal write_ack               : std_logic;
    signal core_instruction_stall4 : std_logic;

    type state_t is (IDLE, WRITE_ADDR, WRITE_DATA);
    signal state : state_t;
  begin

--BUG: this combinational logic assumes that AWREADY and WREADY are the same signal
--BUG: this logic disregards the write response data

    data_AWID        <= (others => '0');
    data_AWADDR      <= core_data_address;
    data_AWLEN       <= BURST_LEN;
    data_AWSIZE      <= BURST_SIZE;
    data_AWBURST     <= BURST_INCR;
    data_AWLOCK      <= (others => '0');
    data_AWCACHE     <= (others => '0');
    data_AWPROT      <= (others => '0');
    data_AWVALID     <= core_data_write when (state /= WRITE_DATA) else '0';
    core_data_stall1 <= not data_AWREADY;
    data_WID         <= (others => '0');
    data_WDATA       <= core_data_writedata;
    data_WSTRB       <= core_data_byteenable;
    data_WLAST       <= '1';
    data_WVALID      <= core_data_write when (state /= WRITE_ADDR) else '0';
    core_data_stall2 <= data_WREADY;
    --data_BID
    --data_BRESP
    --data_BVALID
    data_BREADY      <= '1';


    data_ARID          <= (others => '0');
    data_ARADDR        <= core_data_address;
    data_ARLEN         <= BURST_LEN;
    data_ARSIZE        <= BURST_SIZE;
    data_ARBURST       <= BURST_INCR;
    data_ARLOCK        <= (others => '0');
    data_ARCACHE       <= (others => '0');
    data_ARPROT        <= (others => '0');
    data_ARVALID       <= core_data_read;
    core_data_stall3   <= not data_ARREADY;
    -- data_RID
    core_data_readdata <= data_RDATA;
    -- data_RRESP
    -- data_RLAST
    core_data_ack      <= data_RVALID or write_ack;
    data_RREADY        <= '1';

    -- This Process handles coupling the decoupled write data and write address channels
    data_write_proc : process(clk)
    begin
      if rising_edge(clk) then
        write_ack <= '0';
        case state is
          when IDLE =>
            if core_data_write = '1' then
              write_ack <= data_AWREADY and data_WREADY;
              if (data_AWREADY and not data_WREADY) = '1' then
                state <= WRITE_DATA;
              elsif (not data_AWREADY and data_WREADY) = '1' then
                state <= WRITE_ADDR;
              end if;
            end if;
          when WRITE_ADDR =>
            if data_AWREADY = '1' then
              state     <= IDLE;
              write_ack <= '1';
            end if;
          when WRITE_DATA =>
            if data_WREADY = '1' then
              state     <= IDLE;
              write_ack <= '1';
            end if;
          when others => null;
        end case;
        if reset = '1' then
          state <= IDLE;
        end if;
      end if;
    end process;

    --Instruction read port

    instr_ARID                     <= (others => '0');
    instr_ARADDR                   <= core_instruction_address;
    instr_ARLEN                    <= BURST_LEN;
    instr_ARSIZE                   <= BURST_SIZE;
    instr_ARBURST                  <= BURST_INCR;
    instr_ARLOCK                   <= (others => '0');
    instr_ARCACHE                  <= (others => '0');
    instr_ARPROT                   <= (others => '0');
    instr_ARVALID                  <= core_instruction_read;
    core_instruction_stall4        <= not instr_ARREADY;
                                        -- instr_RID
    core_instruction_readdata      <= instr_RDATA;
                                        --instr_RRESP
                                        --instr_RLAST
    core_instruction_readdatavalid <= instr_RVALID;
    instr_RREADY                   <= '1';

    core_instruction_waitrequest <= core_instruction_stall4;

    instr_AWID    <= (others => '0');
    instr_AWADDR  <= (others => '0');
    instr_AWLEN   <= (others => '0');
    instr_AWSIZE  <= (others => '0');
    instr_AWBURST <= (others => '0');
    instr_AWLOCK  <= (others => '0');
    instr_AWCACHE <= (others => '0');
    instr_AWPROT  <= (others => '0');
    instr_AWVALID <= '0';
    instr_WID     <= (others => '0');
    instr_WDATA   <= (others => '0');
    instr_WSTRB   <= (others => '0');
    instr_WLAST   <= '0';
    instr_WVALID  <= '0';
    instr_BREADY  <= '1';


  end generate axi_enabled;

  core : component orca_core
    generic map(
      REGISTER_SIZE      => REGISTER_SIZE,
      RESET_VECTOR       => RESET_VECTOR,
      MULTIPLY_ENABLE    => MULTIPLY_ENABLE,
      DIVIDE_ENABLE      => DIVIDE_ENABLE,
      SHIFTER_MAX_CYCLES => SHIFTER_MAX_CYCLES,
      COUNTER_LENGTH     => COUNTER_LENGTH,
      ENABLE_EXCEPTIONS  => ENABLE_EXCEPTIONS,
      BRANCH_PREDICTORS  => BRANCH_PREDICTORS,
      PIPELINE_STAGES    => PIPELINE_STAGES,
      LVE_ENABLE         => LVE_ENABLE,
      NUM_EXT_INTERRUPTS => CONDITIONAL(ENABLE_EXT_INTERRUPTS > 0, NUM_EXT_INTERRUPTS, 0),
      SCRATCHPAD_SIZE    => CONDITIONAL(LVE_ENABLE = 1, 2**SCRATCHPAD_ADDR_BITS, 0),
      FAMILY             => FAMILY)

    port map(
      clk            => clk,
      scratchpad_clk => scratchpad_clk,
      reset          => reset,

                                        --avalon master bus
      core_data_address              => core_data_address,
      core_data_byteenable           => core_data_byteenable,
      core_data_read                 => core_data_read,
      core_data_readdata             => core_data_readdata,
      core_data_write                => core_data_write,
      core_data_writedata            => core_data_writedata,
      core_data_ack                  => core_data_ack,
                                        --avalon master bus
      core_instruction_address       => core_instruction_address,
      core_instruction_read          => core_instruction_read,
      core_instruction_readdata      => core_instruction_readdata,
      core_instruction_waitrequest   => core_instruction_waitrequest,
      core_instruction_readdatavalid => core_instruction_readdatavalid,

      sp_address   => sp_address(CONDITIONAL(LVE_ENABLE = 1, SCRATCHPAD_ADDR_BITS, 0)-1 downto 0),
      sp_byte_en   => sp_byte_en,
      sp_write_en  => sp_write_en,
      sp_read_en   => sp_read_en,
      sp_writedata => sp_writedata,
      sp_readdata  => sp_readdata,
      sp_ack       => sp_ack,

      external_interrupts => global_interrupts(CONDITIONAL(ENABLE_EXT_INTERRUPTS > 0, NUM_EXT_INTERRUPTS, 0)-1 downto 0));




end architecture rtl;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants_pkg.all;

entity register_file is
  generic(
    REGISTER_SIZE      : positive;
    REGISTER_NAME_SIZE : positive
    );
  port(
    clk         : in std_logic;
    valid_input : in std_logic;
    rs1_sel     : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    rs2_sel     : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    wb_sel      : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    wb_data     : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    wb_enable   : in std_logic;
    wb_valid    : in std_logic;

    rs1_data : buffer std_logic_vector(REGISTER_SIZE -1 downto 0);
    rs2_data : buffer std_logic_vector(REGISTER_SIZE -1 downto 0)
    );
end;

architecture rtl of register_file is
  type register_list is array(31 downto 0) of std_logic_vector(REGISTER_SIZE-1 downto 0);


  signal registers : register_list := (others => (others => '0'));

  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

  signal read_during_write1 : std_logic;
  signal read_during_write2 : std_logic;
  signal out1               : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal out2               : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_data_latched    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal we                 : std_logic;

--These aliases are useful during simulation of software.
  alias ra  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_RA ));
  alias sp  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_SP ));
  alias gp  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_GP ));
  alias tp  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_TP ));
  alias t0  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_T0 ));
  alias t1  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_T1 ));
  alias t2  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_T2 ));
  alias s0  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S0 ));
  alias s1  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S1 ));
  alias a0  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_A0 ));
  alias a1  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_A1 ));
  alias a2  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_A2 ));
  alias a3  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_A3 ));
  alias a4  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_A4 ));
  alias a5  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_A5 ));
  alias a6  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_A6 ));
  alias a7  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_A7 ));
  alias s2  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S2 ));
  alias s3  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S3 ));
  alias s4  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S4 ));
  alias s5  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S5 ));
  alias s6  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S6 ));
  alias s7  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S7 ));
  alias s8  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S8 ));
  alias s9  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S9 ));
  alias s10 : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S10));
  alias s11 : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_S11));
  alias t3  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_T3 ));
  alias t4  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_T4 ));
  alias t5  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_T5 ));
  alias t6  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(to_integer(REGISTER_T6 ));

begin

  we <= wb_enable and wb_valid;
  register_proc : process (clk) is
  begin
    if rising_edge(clk) then
      if we = '1' then
        registers(to_integer(unsigned(wb_sel))) <= wb_data;
      end if;
      out1 <= registers(to_integer(unsigned(rs1_sel)));
      out2 <= registers(to_integer(unsigned(rs2_sel)));
    end if;  --rising edge
  end process;


  --read during write logic
  rs1_data <= wb_data_latched when read_during_write1 = '1'else out1;
  rs2_data <= wb_data_latched when read_during_write2 = '1'else out2;
  process(clk) is
  begin
    if rising_edge(clk) then
      read_during_write2 <= '0';
      read_during_write1 <= '0';
      if rs1_sel = wb_sel and wb_enable = '1' and wb_valid = '1' then
        read_during_write1 <= '1';
      end if;
      if rs2_sel = wb_sel and wb_enable = '1' and wb_valid = '1' then
        read_during_write2 <= '1';
      end if;
      wb_data_latched <= wb_data;
    end if;

  end process;

end architecture;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants_pkg.all;

entity instruction_legal is
  generic (
    CHECK_LEGAL_INSTRUCTIONS : boolean);
  port (
    instruction : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    legal       : out std_logic);
end entity;

architecture rtl of instruction_legal is
  alias opcode7 is instruction(6 downto 0);
  alias func3 is instruction(INSTR_FUNC3'range);
  alias func7 is instruction(31 downto 25);
  alias csr_num is instruction(SYSTEM_MINOR_OP'range);
begin

  legal <=
    '1' when (CHECK_LEGAL_INSTRUCTIONS = false or
              opcode7 = LUI_OP or
              opcode7 = AUIPC_OP or
              opcode7 = JAL_OP or
              (opcode7 = JALR_OP and func3 = "000") or
              (opcode7 = BRANCH_OP and func3 /= "010" and func3 /= "011") or
              (opcode7 = LOAD_OP and func3 /= "011" and func3 /= "110" and func3 /= "111") or
              (opcode7 = STORE_OP and (func3 = "000" or func3 = "001" or func3 = "010")) or
              opcode7 = ALUI_OP or      --Does not catch illegal
                                        --shift amountes
              (opcode7 = ALU_OP and (func7 = ALU_F7 or func7 = MUL_F7 or func7 = SUB_F7))or
              (opcode7 = FENCE_OP) or   --all fence ops are treated as legal
              (opcode7 = SYSTEM_OP and csr_num /= SYSTEM_ECALL and csr_num /= SYSTEM_EBREAK) or
              opcode7 = LVE_OP) else '0';

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants_pkg.all;

entity system_calls is

  generic (
    REGISTER_SIZE     : natural;
    RESET_VECTOR      : integer;
    ENABLE_EXCEPTIONS : boolean := true;
    COUNTER_LENGTH    : natural);

  port (
    clk         : in std_logic;
    reset       : in std_logic;
    valid       : in std_logic;
    stall_in    : in std_logic;
    rs1_data    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

    wb_data   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_enable : out std_logic;

    current_pc    : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_correction : out    std_logic_vector(REGISTER_SIZE -1 downto 0);
    pc_corr_en    : buffer std_logic;


    -- To the Instruction Fetch Stage
    interrupt_pending   : buffer std_logic;
    external_interrupts : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    -- Signals when an interrupt may proceed.
    pipeline_empty      : in     std_logic;

    -- These signals are used to tell the interrupt handler which instruction
    -- to return to upon exit. They are sourced from the instruction fetch
    -- stage of the processor.
    instruction_fetch_pc : in std_logic_vector(REGISTER_SIZE-1 downto 0);

    br_bad_predict : in std_logic;
    br_new_pc      : in std_logic_vector(REGISTER_SIZE-1 downto 0));

end entity system_calls;

architecture rtl of system_calls is


  component instruction_legal is
    generic (
      check_legal_instructions : boolean);
    port (
      instruction : in  std_logic_vector(instruction_size-1 downto 0);
      legal       : out std_logic);
  end component;

  --csr singnals. These are initialized to zero so that if any bits are nevver
  --assigned, they act like constants
  signal mstatus  : std_logic_vector(register_size-1 downto 0) := (others => '0');
  signal mie      : std_logic_vector(register_size-1 downto 0) := (others => '0');
  signal mepc     : std_logic_vector(register_size-1 downto 0) := (others => '0');
  signal mcause   : std_logic_vector(register_size-1 downto 0) := (others => '0');
  signal mbadaddr : std_logic_vector(register_size-1 downto 0) := (others => '0');
  signal mip      : std_logic_vector(register_size-1 downto 0) := (others => '0');
  signal mtime    : std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
  signal mtimeh   : std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');
  signal meimask  : std_logic_vector(register_size-1 downto 0) := (others => '0');
  signal meipend  : std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => '0');



  alias csr_select is instruction(CSR_ADDRESS'range);
  alias func3 is instruction(INSTR_FUNC3'range);

  signal bit_sel       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal csr_read_val  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal csr_write_val : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal legal_instr : std_logic;

  signal was_mret    : std_logic;
  signal was_illegal : std_logic;
  signal was_fence_i : std_logic;
  signal pc_add_4    : std_logic_vector(current_pc'range);

  signal interrupt_processor : std_logic;

  signal time_counter : unsigned(63 downto 0);

begin  -- architecture rtl


  -----------------------------------------------------------------------------
  -- Implement the following :
  -- mret instruction
  -- csrrw
  -- csrrs
  -- csrrc (possibly not needed)
  -- Omit immediate versions of the csr* instructions
  -- Omit ECALL and EBREAK, as I can'tsee a reason with only mmode inplemented
  --
  -- Implement the following CSRs:
  --     MSTATUS  (for IE,PIE bits)
  --     MEPC
  --     MCAUSE
  --     MBADADDR (if bad reads are caught)
  --     MIP
  --     If expternal interupts are enabled:
  --         MEIMASK  (external interrupt mask)
  --         MEIPEND  (external interrupt
  -----------------------------------------------------------------------------

  instr_check : component instruction_legal
    generic map (
      check_legal_instructions => true)
    port map (
      instruction => instruction,
      legal       => legal_instr);

  --TIMER
  process(clk)
  begin
    if rising_edge(clk) then
      time_counter <= time_counter + 1;
      if reset = '1' then
        time_counter <= (others => '0');
      end if;
    end if;
  end process;

  mtime  <= std_logic_vector(time_counter(REGISTER_SIZE - 1 downto 0)) when COUNTER_LENGTH /= 0 else (others => '0');
  mtimeh <= std_logic_vector(time_counter(time_counter'left downto time_counter'left-REGISTER_SIZE+1))
            when REGISTER_SIZE = 32 and COUNTER_LENGTH = 64 else (others => '0');

  with csr_select select
    csr_read_val <=
    mstatus         when CSR_MSTATUS,
    mepc            when CSR_MEPC,
    mcause          when CSR_MCAUSE,
    mbadaddr        when CSR_MBADADDR,
    mip             when CSR_MIP,
    meimask         when CSR_MEIMASK,
    meipend         when CSR_MEIPEND,
    mtime           when CSR_MTIME,
    mtimeh          when CSR_MTIMEH,
    mtime           when CSR_UTIME,
    mtimeh          when CSR_UTIMEH,

    (others => '0') when others;

  bit_sel <= rs1_data;

  with func3 select
    csr_write_val <=
    rs1_data                     when CSRRW_FUNC3,
    csr_read_val or bit_sel      when CSRRS_FUNC3,
    csr_read_val and not bit_sel when CSRRC_FUNC3,
    csr_read_val                 when others;  --no write


  process(clk)
  begin
    if rising_edge(clk) then
      wb_enable   <= '0';
      wb_data     <= csr_read_val;
      pc_add_4    <= std_logic_vector(unsigned(current_pc) + 4);
      was_mret    <= '0';
      was_fence_i <= '0';
      was_illegal <= '0';
      if valid = '1' then
        if legal_instr /= '1' and ENABLE_EXCEPTIONS then
          ---------------------------------------------------------------------
          -- Handle illegal instructions
          ---------------------------------------------------------------------
          mstatus(CSR_MSTATUS_MIE)  <= '0';
          mstatus(CSR_MSTATUS_MPIE) <= mstatus(CSR_MSTATUS_MIE);
          mcause                    <= std_logic_vector(to_unsigned(CSR_MCAUSE_ILLEGAL, mcause'length));
          mepc                      <= current_pc;
          was_illegal               <= '1';
        elsif instruction(MAJOR_OP'range) = SYSTEM_OP  and stall_in = '0' then
          if func3 /= "000" then
            ---------------------------------------------------------------------
            -- CSR READ/WRITE
            ---------------------------------------------------------------------
            wb_enable <= '1';

            --disable csr writes if exceptions are not enabled
            if ENABLE_EXCEPTIONS then
              case csr_select is
                when CSR_MSTATUS =>
                  --only 2 bits writeable
                  mstatus(CSR_MSTATUS_MIE)  <= csr_write_val(CSR_MSTATUS_MIE);
                  mstatus(CSR_MSTATUS_MPIE) <= csr_write_val(CSR_MSTATUS_MPIE);
                when CSR_MEPC =>
                  mepc <= csr_write_val;
                when CSR_MCAUSE =>
                  mcause <= csr_write_val;
                when CSR_MBADADDR =>
                  mbadaddr <= csr_write_val;
                when CSR_MEIMASK =>
                  meimask <= csr_write_val;

                --READ only Registers
                --when CSR_MIP      =>
                --  mbadaddr <= csr_write_val;
                --when CSR_MEIPEND  =>
                --  meipend <= csr_write_val;
                when others => null;
              end case;
            end if;
          elsif instruction(SYSTEM_NOT_CSR'range) = SYSTEM_NOT_CSR then
            ---------------------------------------------------------------------
            -- OTHER SYSTEM INSTRUCTIONS (just Mret)
            ---------------------------------------------------------------------
            if instruction(31 downto 30) = "00" and instruction(27 downto 20) = "00000010" then
              --treat all [USHM]RET instructions the same
              mstatus(CSR_MSTATUS_MIE)  <= mstatus(CSR_MSTATUS_MPIE);
              mstatus(CSR_MSTATUS_MPIE) <= '0';
              was_mret                  <= '1';
            end if;  --other system
          end if;  --any system
        elsif instruction(MAJOR_OP'range) = FENCE_OP then
          --all FENCE is a NOP
          --FENCE.I is a pipeline flush
          was_fence_i <= instruction(12);
        end if;  --valid
      elsif interrupt_processor = '1' and ENABLE_EXCEPTIONS then
        mstatus(CSR_MSTATUS_MIE)  <= '0';
        mstatus(CSR_MSTATUS_MPIE) <= '1';
        mcause(mcause'left)       <= '1';
        mcause(3 downto 0)        <= std_logic_vector(to_unsigned(11, 4));
        mepc                      <= instruction_fetch_pc;
      end if;
      if reset = '1' then

        if ENABLE_EXCEPTIONS then
          mstatus(CSR_MSTATUS_MIE)  <= '0';
          mstatus(CSR_MSTATUS_MPIE) <= '0';
          mie                       <= (others => '0');
          mepc                      <= (others => '0');
          mcause                    <= (others => '0');
          meimask                   <= (others => '0');

        end if;

                                        --READ-ONLY
                                        --mip     <= (others => '0');
                                        --meipend <= (others => '0');
      end if;
    end if;
  end process;

-------------------------------------------------------------------------------
-- handle external interrupts
--
--TODO: (Not yet implemented)
-- nterrupt_processor goes high when pipeline is empty and and interrupt
--is pending
--
--If interrupt is pending and enabled, slip the pipeline.
-------------------------------------------------------------------------------
  meipend <= external_interrupts;

  interrupt_processor <= interrupt_pending and pipeline_empty;
  interrupt_pending   <= mstatus(CSR_MSTATUS_MIE) when unsigned(meimask and meipend) /= 0 else '0';


-----------------------------------------------------------------------------
-- There are several reasons that sys_calls might send a pc correction
-- Timer interrupt (if timer enabled)
-- external enterrupt
-- illegal instruction
-- mret instruction
-- fence.i  (flush pipelin, and start over)
-----------------------------------------------------------------------------

  pc_corr_en <= was_fence_i or was_mret or was_illegal or interrupt_processor;

  pc_correction <= pc_add_4 when was_fence_i = '1' else
                   std_logic_vector(to_unsigned(RESET_VECTOR, pc_correction'length)) when was_illegal = '1' or interrupt_processor = '1' else
                   mepc                                                              when was_mret = '1' else
                   (others => '-');



end architecture rtl;
