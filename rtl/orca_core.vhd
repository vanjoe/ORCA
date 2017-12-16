library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library work;
use work.rv_components.all;
use work.utils.all;
use work.constants_pkg.all;

entity orca_core is
  generic (
    REGISTER_SIZE          : integer;
    RESET_VECTOR           : std_logic_vector(31 downto 0);
    INTERRUPT_VECTOR       : std_logic_vector(31 downto 0);
    MAX_IFETCHES_IN_FLIGHT : positive range 1 to 4;
    BTB_ENTRIES            : natural;
    MULTIPLY_ENABLE        : natural range 0 to 1;
    DIVIDE_ENABLE          : natural range 0 to 1;
    SHIFTER_MAX_CYCLES     : natural;
    POWER_OPTIMIZED        : natural range 0 to 1;
    COUNTER_LENGTH         : natural;
    ENABLE_EXCEPTIONS      : natural;
    PIPELINE_STAGES        : natural range 4 to 5;
    ENABLE_EXT_INTERRUPTS  : natural range 0 to 1;
    NUM_EXT_INTERRUPTS     : positive range 1 to 32;
    LVE_ENABLE             : natural range 0 to 1;
    WRITE_FIRST_SMALL_RAMS : boolean;
    FAMILY                 : string;

    HAS_ICACHE : boolean;
    HAS_DCACHE : boolean
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    --ICache control (Invalidate/flush/writeback/enable/disable)
    from_icache_control_ready : in     std_logic;
    to_icache_control_valid   : buffer std_logic;
    to_icache_control_command : out    cache_control_command;

    --DCache control (Invalidate/flush/writeback/enable/disable)
    from_dcache_control_ready : in     std_logic;
    to_dcache_control_valid   : buffer std_logic;
    to_dcache_control_command : out    cache_control_command;

    memory_interface_idle : in std_logic;

    --Instruction Orca-internal memory-mapped master
    ifetch_oimm_address       : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    ifetch_oimm_requestvalid  : buffer std_logic;
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


    ---------------------------------------------------------------------------
    -- Vector Co-Processor Port
    ---------------------------------------------------------------------------
    vcp_data0 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    vcp_data1 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    vcp_data2 : out std_logic_vector(REGISTER_SIZE-1 downto 0);

    vcp_instruction      : out std_logic_vector(40 downto 0);
    vcp_valid_instr      : out std_logic;
    vcp_ready            : in  std_logic;
    vcp_executing        : in  std_logic;
    vcp_alu_data1        : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    vcp_alu_data2        : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    vcp_alu_op_size      : in  std_logic_vector(1 downto 0);
    vcp_alu_source_valid : in  std_logic;
    vcp_alu_result       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    vcp_alu_result_valid : out std_logic;

    global_interrupts : in std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0)
    );
end entity orca_core;

architecture rtl of orca_core is
  signal interrupt_pending : std_logic;

  signal ifetch_idle  : std_logic;
  signal decode_idle  : std_logic;
  signal execute_idle : std_logic;
  signal core_idle    : std_logic;

  signal program_counter : unsigned(REGISTER_SIZE-1 downto 0);

  signal to_pc_correction_data        : unsigned(REGISTER_SIZE-1 downto 0);
  signal to_pc_correction_source_pc   : unsigned(REGISTER_SIZE-1 downto 0);
  signal to_pc_correction_valid       : std_logic;
  signal to_pc_correction_predictable : std_logic;
  signal from_pc_correction_ready     : std_logic;

  signal ifetch_to_decode_instruction     : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal ifetch_to_decode_program_counter : unsigned(REGISTER_SIZE-1 downto 0);
  signal ifetch_to_decode_predicted_pc    : unsigned(REGISTER_SIZE-1 downto 0);
  signal from_ifetch_valid                : std_logic;
  signal decode_to_ifetch_ready           : std_logic;

  signal to_decode_valid                    : std_logic;
  signal decode_to_execute_rs1_data         : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal decode_to_execute_rs2_data         : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal decode_to_execute_rs3_data         : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal decode_to_execute_sign_extension   : std_logic_vector(REGISTER_SIZE-12-1 downto 0);
  signal decode_to_execute_program_counter  : unsigned(REGISTER_SIZE-1 downto 0);
  signal decode_to_execute_predicted_pc     : unsigned(REGISTER_SIZE-1 downto 0);
  signal decode_to_execute_instruction      : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal decode_to_execute_next_instruction : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal decode_to_execute_next_valid       : std_logic;
  signal from_decode_valid                  : std_logic;
  signal execute_to_decode_ready            : std_logic;

  signal to_execute_valid     : std_logic;
  signal execute_to_rf_select : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal execute_to_rf_data   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal execute_to_rf_valid  : std_logic;
begin
  I : instruction_fetch
    generic map (
      REGISTER_SIZE          => REGISTER_SIZE,
      RESET_VECTOR           => RESET_VECTOR,
      MAX_IFETCHES_IN_FLIGHT => MAX_IFETCHES_IN_FLIGHT,
      BTB_ENTRIES            => BTB_ENTRIES
      )
    port map (
      clk   => clk,
      reset => reset,

      to_pc_correction_data        => to_pc_correction_data,
      to_pc_correction_source_pc   => to_pc_correction_source_pc,
      to_pc_correction_valid       => to_pc_correction_valid,
      to_pc_correction_predictable => to_pc_correction_predictable,
      from_pc_correction_ready     => from_pc_correction_ready,

      interrupt_pending => interrupt_pending,

      ifetch_idle => ifetch_idle,

      from_ifetch_instruction     => ifetch_to_decode_instruction,
      from_ifetch_program_counter => ifetch_to_decode_program_counter,
      from_ifetch_predicted_pc    => ifetch_to_decode_predicted_pc,
      from_ifetch_valid           => from_ifetch_valid,
      to_ifetch_ready             => decode_to_ifetch_ready,

      program_counter => program_counter,

      oimm_address       => ifetch_oimm_address,
      oimm_requestvalid  => ifetch_oimm_requestvalid,
      oimm_readdata      => ifetch_oimm_readdata,
      oimm_readdatavalid => ifetch_oimm_readdatavalid,
      oimm_waitrequest   => ifetch_oimm_waitrequest
      );

  to_decode_valid <= from_ifetch_valid and (not to_pc_correction_valid);
  D : decode
    generic map (
      REGISTER_SIZE          => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE    => SIGN_EXTENSION_SIZE,
      LVE_ENABLE             => LVE_ENABLE = 1,
      PIPELINE_STAGES        => PIPELINE_STAGES-3,
      WRITE_FIRST_SMALL_RAMS => WRITE_FIRST_SMALL_RAMS,
      FAMILY                 => FAMILY
      )
    port map (
      clk   => clk,
      reset => reset,

      to_rf_select => execute_to_rf_select,
      to_rf_data   => execute_to_rf_data,
      to_rf_valid  => execute_to_rf_valid,

      to_decode_program_counter => ifetch_to_decode_program_counter,
      to_decode_predicted_pc    => ifetch_to_decode_predicted_pc,
      to_decode_instruction     => ifetch_to_decode_instruction,
      to_decode_valid           => to_decode_valid,
      from_decode_ready         => decode_to_ifetch_ready,

      quash_decode => to_pc_correction_valid,
      decode_idle  => decode_idle,

      from_decode_rs1_data         => decode_to_execute_rs1_data,
      from_decode_rs2_data         => decode_to_execute_rs2_data,
      from_decode_rs3_data         => decode_to_execute_rs3_data,
      from_decode_sign_extension   => decode_to_execute_sign_extension,
      from_decode_program_counter  => decode_to_execute_program_counter,
      from_decode_predicted_pc     => decode_to_execute_predicted_pc,
      from_decode_instruction      => decode_to_execute_instruction,
      from_decode_next_instruction => decode_to_execute_next_instruction,
      from_decode_next_valid       => decode_to_execute_next_valid,
      from_decode_valid            => from_decode_valid,
      to_decode_ready              => execute_to_decode_ready
      );

  to_execute_valid <= from_decode_valid and (not to_pc_correction_valid);
  X : execute
    generic map (
      REGISTER_SIZE         => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE   => SIGN_EXTENSION_SIZE,
      INTERRUPT_VECTOR      => INTERRUPT_VECTOR,
      BTB_ENTRIES           => BTB_ENTRIES,
      MULTIPLY_ENABLE       => MULTIPLY_ENABLE = 1,
      DIVIDE_ENABLE         => DIVIDE_ENABLE = 1,
      POWER_OPTIMIZED       => POWER_OPTIMIZED = 1,
      SHIFTER_MAX_CYCLES    => SHIFTER_MAX_CYCLES,
      COUNTER_LENGTH        => COUNTER_LENGTH,
      ENABLE_EXCEPTIONS     => ENABLE_EXCEPTIONS = 1,
      ENABLE_EXT_INTERRUPTS => ENABLE_EXT_INTERRUPTS,
      NUM_EXT_INTERRUPTS    => NUM_EXT_INTERRUPTS,
      LVE_ENABLE            => LVE_ENABLE,
      FAMILY                => FAMILY,
      HAS_ICACHE => HAS_ICACHE,
      HAS_DCACHE => HAS_DCACHE
      )
    port map (
      clk   => clk,
      reset => reset,

      global_interrupts     => global_interrupts,
      program_counter       => program_counter,
      core_idle             => core_idle,
      memory_interface_idle => memory_interface_idle,


      to_execute_valid            => to_execute_valid,
      to_execute_program_counter  => decode_to_execute_program_counter,
      to_execute_predicted_pc     => decode_to_execute_predicted_pc,
      to_execute_instruction      => decode_to_execute_instruction,
      to_execute_next_instruction => decode_to_execute_next_instruction,
      to_execute_next_valid       => decode_to_execute_next_valid,
      to_execute_rs1_data         => decode_to_execute_rs1_data,
      to_execute_rs2_data         => decode_to_execute_rs2_data,
      to_execute_rs3_data         => decode_to_execute_rs3_data,
      to_execute_sign_extension   => decode_to_execute_sign_extension,
      from_execute_ready          => execute_to_decode_ready,

      execute_idle => execute_idle,

      to_pc_correction_data        => to_pc_correction_data,
      to_pc_correction_source_pc   => to_pc_correction_source_pc,
      to_pc_correction_valid       => to_pc_correction_valid,
      to_pc_correction_predictable => to_pc_correction_predictable,
      from_pc_correction_ready     => from_pc_correction_ready,

      to_rf_select => execute_to_rf_select,
      to_rf_data   => execute_to_rf_data,
      to_rf_valid  => execute_to_rf_valid,

      lsu_oimm_address       => lsu_oimm_address,
      lsu_oimm_byteenable    => lsu_oimm_byteenable,
      lsu_oimm_requestvalid  => lsu_oimm_requestvalid,
      lsu_oimm_readnotwrite  => lsu_oimm_readnotwrite,
      lsu_oimm_writedata     => lsu_oimm_writedata,
      lsu_oimm_readdata      => lsu_oimm_readdata,
      lsu_oimm_readdatavalid => lsu_oimm_readdatavalid,
      lsu_oimm_waitrequest   => lsu_oimm_waitrequest,

      from_icache_control_ready => from_icache_control_ready,
      to_icache_control_valid   => to_icache_control_valid,
      to_icache_control_command => to_icache_control_command,

      from_dcache_control_ready => from_dcache_control_ready,
      to_dcache_control_valid   => to_dcache_control_valid,
      to_dcache_control_command => to_dcache_control_command,

      interrupt_pending => interrupt_pending,

      vcp_data0            => vcp_data0,
      vcp_data1            => vcp_data1,
      vcp_data2            => vcp_data2,
      vcp_instruction      => vcp_instruction,
      vcp_valid_instr      => vcp_valid_instr,
      vcp_ready            => vcp_ready,
      vcp_executing        => vcp_executing,
      vcp_alu_data1        => vcp_alu_data1,
      vcp_alu_data2        => vcp_alu_data2,
      vcp_alu_op_size      => vcp_alu_op_size,
      vcp_alu_source_valid => vcp_alu_source_valid,
      vcp_alu_result       => vcp_alu_result,
      vcp_alu_result_valid => vcp_alu_result_valid

      );

  core_idle <= ifetch_idle and decode_idle and execute_idle;
end architecture rtl;
