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
    RESET_VECTOR       : std_logic_vector(31 downto 0);
    INTERRUPT_VECTOR   : std_logic_vector(31 downto 0);
    MULTIPLY_ENABLE    : natural range 0 to 1;
    DIVIDE_ENABLE      : natural range 0 to 1;
    SHIFTER_MAX_CYCLES : natural;
    POWER_OPTIMIZED    : natural range 0 to 1 := 0;
    COUNTER_LENGTH     : natural;
    ENABLE_EXCEPTIONS  : natural;
    BRANCH_PREDICTORS  : natural;
    PIPELINE_STAGES    : natural range 4 to 5;
    NUM_EXT_INTERRUPTS : integer range 0 to 32;
    LVE_ENABLE         : natural range 0 to 1;
    SCRATCHPAD_SIZE    : integer;
    FAMILY             : string
    );
  port(
    clk            : in std_logic;
    scratchpad_clk : in std_logic;
    reset          : in std_logic;

    --Instruction Orca-internal memory-mapped master
    ifetch_oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    ifetch_oimm_requestvalid  : buffer std_logic;
    ifetch_oimm_readnotwrite  : out    std_logic;
    ifetch_oimm_readdata      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    ifetch_oimm_waitrequest   : in     std_logic;
    ifetch_oimm_readdatavalid : in     std_logic;

    --Data Orca-internal memory-mapped master
    lsu_oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    lsu_oimm_byteenable    : out    std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    lsu_oimm_requestvalid  : buffer std_logic;
    lsu_oimm_readnotwrite  : buffer std_logic;
    lsu_oimm_writedata     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    lsu_oimm_readdata      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    lsu_oimm_readdatavalid : in     std_logic;
    lsu_oimm_waitrequest   : in     std_logic;

    --Scratchpad memory-mapped slave
    sp_address   : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
    sp_byte_en   : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    sp_write_en  : in  std_logic;
    sp_read_en   : in  std_logic;
    sp_writedata : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_readdata  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_ack       : out std_logic;

    external_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0) := (others => '0')
    );
end entity orca_core;

architecture rtl of orca_core is
  constant SIGN_EXTENSION_SIZE : integer := 20;

  --signals going into fetch
  signal if_valid_out : std_logic;

  --signals going into decode
  signal d_instr     : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal d_pc        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal d_br_taken  : std_logic;
  signal d_valid     : std_logic;
  signal d_valid_out : std_logic;

  signal wb_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_sel  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_en   : std_logic;

  --signals going into execute
  signal e_instr        : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal e_subseq_instr : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal e_subseq_valid : std_logic;
  signal e_pc           : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal e_br_taken     : std_logic;
  signal e_valid        : std_logic;
  signal pipeline_empty : std_logic;

  signal execute_stalled : std_logic;
  signal rs1_data        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sign_extension  : std_logic_vector(REGISTER_SIZE-12-1 downto 0);

  signal pipeline_flush : std_logic;

  signal fetch_in_flight : std_logic;

  -- Interrupt lines
  signal e_interrupt_pending : std_logic;
  signal ext_int_resized     : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal branch_pred_to_instr_fetch : std_logic_vector(REGISTER_SIZE*2 + 3-1 downto 0);

  signal decode_flushed : std_logic;
  signal ifetch_next_pc : std_logic_vector(REGISTER_SIZE-1 downto 0);
begin  -- architecture rtl
  pipeline_flush <= branch_get_flush(branch_pred_to_instr_fetch);

  instr_fetch : instruction_fetch
    generic map (
      REGISTER_SIZE     => REGISTER_SIZE,
      RESET_VECTOR      => RESET_VECTOR,
      BRANCH_PREDICTORS => BRANCH_PREDICTORS
      )
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
      fetch_in_flight => fetch_in_flight,

      oimm_address       => ifetch_oimm_address,
      oimm_readnotwrite  => ifetch_oimm_readnotwrite,
      oimm_requestvalid  => ifetch_oimm_requestvalid,
      oimm_readdata      => ifetch_oimm_readdata,
      oimm_readdatavalid => ifetch_oimm_readdatavalid,
      oimm_waitrequest   => ifetch_oimm_waitrequest
      );

  d_valid <= if_valid_out and not pipeline_flush;

  D : decode
    generic map(
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      PIPELINE_STAGES     => PIPELINE_STAGES-3,
      FAMILY              => FAMILY
      )
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
      decode_flushed => decode_flushed
      );

  e_valid <= d_valid_out and not pipeline_flush;
  X : execute
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      INTERRUPT_VECTOR    => INTERRUPT_VECTOR,
      MULTIPLY_ENABLE     => MULTIPLY_ENABLE = 1,
      DIVIDE_ENABLE       => DIVIDE_ENABLE = 1,
      POWER_OPTIMIZED     => POWER_OPTIMIZED = 1,
      SHIFTER_MAX_CYCLES  => SHIFTER_MAX_CYCLES,
      COUNTER_LENGTH      => COUNTER_LENGTH,
      ENABLE_EXCEPTIONS   => ENABLE_EXCEPTIONS = 1,
      LVE_ENABLE          => LVE_ENABLE,
      SCRATCHPAD_SIZE     => SCRATCHPAD_SIZE,
      FAMILY              => FAMILY
      )
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
      branch_pred        => branch_pred_to_instr_fetch,
      ifetch_next_pc     => ifetch_next_pc,
      stall_from_execute => execute_stalled,

      --Data memory-mapped master
      lsu_oimm_address       => lsu_oimm_address,
      lsu_oimm_byteenable    => lsu_oimm_byteenable,
      lsu_oimm_requestvalid  => lsu_oimm_requestvalid,
      lsu_oimm_readnotwrite  => lsu_oimm_readnotwrite,
      lsu_oimm_writedata     => lsu_oimm_writedata,
      lsu_oimm_readdata      => lsu_oimm_readdata,
      lsu_oimm_readdatavalid => lsu_oimm_readdatavalid,
      lsu_oimm_waitrequest   => lsu_oimm_waitrequest,

      --Scratchpad memory-mapped slave
      sp_address   => sp_address,
      sp_byte_en   => sp_byte_en,
      sp_write_en  => sp_write_en,
      sp_read_en   => sp_read_en,
      sp_writedata => sp_writedata,
      sp_readdata  => sp_readdata,
      sp_ack       => sp_ack,

      -- Interrupt lines
      external_interrupts => ext_int_resized,
      pipeline_empty      => decode_flushed,
      fetch_in_flight     => fetch_in_flight,
      interrupt_pending   => e_interrupt_pending
      );

  ext_int_resized <= std_logic_vector(RESIZE(unsigned(external_interrupts), ext_int_resized'length));
end architecture rtl;
