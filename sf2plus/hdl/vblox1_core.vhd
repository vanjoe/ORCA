-- vblox1_core.vhd
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

entity vblox1_core is
  generic (
    VECTOR_LANES               : integer                                    := 1;
    VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS := 0;
    VCI_CONFIGS                : vci_config_array                           := DEFAULT_VCI_CONFIGS;
    VCI_DEPTHS                 : vci_depth_array                            := DEFAULT_VCI_DEPTHS;
    MAX_MASKED_WAVES           : positive range 128 to 8192                 := 128;
    MASK_PARTITIONS            : natural                                    := 1;

    MIN_MULTIPLIER_HW : min_size_type := BYTE;

    MULFXP_WORD_FRACTION_BITS : integer range 1 to 31 := 25;
    MULFXP_HALF_FRACTION_BITS : integer range 1 to 15 := 15;
    MULFXP_BYTE_FRACTION_BITS : integer range 1 to 7  := 4;

    CFG_FAM : config_family_type;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk    : in std_logic;
    reset  : in std_logic;
    clk_2x : in std_logic;

    core_pipeline_empty : out std_logic;

    dma_instr_valid : out std_logic;
    dma_instruction : out instruction_type;
    dma_instr_read  : in  std_logic;
    dma_status      : in  std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);

    scratch_port_a : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    scratch_port_b : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    scratch_port_c : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);

    readdata_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    readdata_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

    instr_fifo_empty    : in  std_logic;
    instr_fifo_readdata : in  instruction_type;
    instr_fifo_read     : out std_logic;

    mask_status_update  : out std_logic;
    mask_length_nonzero : out std_logic;

    vci_valid  : out std_logic_vector(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);
    vci_signed : out std_logic;
    vci_opsize : out std_logic_vector(1 downto 0);

    vci_vector_start : out std_logic;
    vci_vector_end   : out std_logic;
    vci_byte_valid   : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
    vci_dest_addr_in : out std_logic_vector(31 downto 0);

    vci_data_a : out std_logic_vector(VECTOR_LANES*32-1 downto 0);
    vci_flag_a : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
    vci_data_b : out std_logic_vector(VECTOR_LANES*32-1 downto 0);
    vci_flag_b : out std_logic_vector(VECTOR_LANES*4-1 downto 0);

    vci_port          : out unsigned(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0);
    vci_data_out      : in  std_logic_vector(VECTOR_LANES*32-1 downto 0);
    vci_flag_out      : in  std_logic_vector(VECTOR_LANES*4-1 downto 0);
    vci_byteenable    : in  std_logic_vector(VECTOR_LANES*4-1 downto 0);
    vci_dest_addr_out : in  std_logic_vector(31 downto 0)
    );

  -- attribute secure_netlist     : string;  -- OFF, ENCRYPT, (PROHIBIT not allowed in Vivado)
  -- attribute secure_config      : string;  -- OFF, PROTECT
  -- attribute secure_net_editing : string;  -- OFF, PROHIBIT
  -- attribute secure_bitstream   : string;  -- OFF, PROHIBIT
  -- attribute secure_net_probing : string;  -- OFF, PROHIBIT
  -- attribute check_license      : string;

  -- attribute secure_netlist of vblox1_core : entity is "OFF";
  -- attribute secure_config  of vblox1_core : entity is "OFF";
  -- attribute check_license  of vblox1_core : entity is "ipvblox_mxp";

end entity vblox1_core;

architecture rtl of vblox1_core is
  constant MULTIPLIER_DELAY : positive        := CFG_SEL(CFG_FAM).MULTIPLIER_DELAY;
  constant VCI_PADDING      : vci_depth_array :=
    vci_padding_gen(MULTIPLIER_DELAY, VECTOR_CUSTOM_INSTRUCTIONS, VCI_CONFIGS, VCI_DEPTHS);
  constant VCI_INFO_ROM : vci_info_array :=
    vci_info_rom_gen(VECTOR_LANES, MULTIPLIER_DELAY, VECTOR_CUSTOM_INSTRUCTIONS, VCI_CONFIGS, VCI_PADDING, VCI_DEPTHS);

  constant ACCUM_DELAY        : integer := 1 + (log2(VECTOR_LANES)/ACCUM_BRANCHES_PER_CLK);
  constant EXTRA_ALIGN_STAGES : integer := log2(VECTOR_LANES)/ALIGN_STAGES_PER_CLK;
  constant PIPELINE_STAGES    : integer := 1+SCRATCHPAD_READ_DELAY+EXTRA_ALIGN_STAGES+1+MULTIPLIER_DELAY+1+ACCUM_DELAY+1+EXTRA_ALIGN_STAGES+1;
  constant HAZARD_STAGES      : integer := PIPELINE_STAGES-WRITE_READ_OVERLAP;

  constant STAGE_IN_SHIFT_START : integer := 1+SCRATCHPAD_READ_DELAY;
  constant STAGE_IN_SHIFT_END   : integer := STAGE_IN_SHIFT_START+EXTRA_ALIGN_STAGES;

  constant STAGE_MUL_START : integer := STAGE_IN_SHIFT_END+1;
  constant STAGE_MUL_END   : integer := STAGE_MUL_START+MULTIPLIER_DELAY;

  constant STAGE_ACCUM_START : integer := STAGE_MUL_END+1;
  constant STAGE_ACCUM_END   : integer := STAGE_ACCUM_START+ACCUM_DELAY;

  constant STAGE_OUT_SHIFT_START : integer := STAGE_ACCUM_END+1;
  constant STAGE_OUT_SHIFT_END   : integer := STAGE_OUT_SHIFT_START+EXTRA_ALIGN_STAGES;

  signal dma_op               : std_logic;
  signal dma_instr_pending    : std_logic;
  signal not_executing        : std_logic;
  signal core_instr_pending   : std_logic;
  signal core_instr_read      : std_logic;
  signal new_instruction_read : std_logic;

  signal shifted_a                : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal shifted_b                : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal in_shift_element         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal exec_dest_addr           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal exec_byteena             : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal accum_byteena            : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal accum_dest_addr          : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal dest_byteena             : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal dest_addr                : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal exec_first_column        : std_logic;
  signal exec_last_cycle          : std_logic;
  signal exec_last_cooldown_cycle : std_logic;
  signal exec_read                : std_logic;
  signal exec_write               : std_logic;
  signal exec_we                  : std_logic;
  signal accum_first_column       : std_logic;
  signal accum_we                 : std_logic;
  signal dest_we                  : std_logic;
  signal accum_writedata          : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal dest_writedata           : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal scalar_a                 : std_logic_vector(31 downto 0);
  signal offset_a                 : std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
  signal offset_b                 : std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);

  signal instr_vci_info       : vci_info_type;
  signal flush                : std_logic;
  signal stall                : std_logic;
  signal instruction_pipeline : instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);
  signal first_pipeline       : std_logic_vector(PIPELINE_STAGES-1 downto 0);
  signal valid_pipeline       : std_logic_vector(PIPELINE_STAGES-1 downto 0);

  signal mask_writedata_enables : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
begin
  core_pipeline_empty <= not_executing and (not valid_pipeline(0));

  dma_op               <= op_is_dma(instruction_pipeline(0).op);
  dma_instr_pending    <= dma_op and valid_pipeline(0);
  core_instr_pending   <= (not dma_op) and valid_pipeline(0) and (not flush);
  dma_instr_valid      <= dma_instr_pending and not_executing;
  dma_instruction      <= instruction_pipeline(0);
  new_instruction_read <= (dma_instr_read or core_instr_read) or ((not valid_pipeline(0)) and (not instr_fifo_empty));
  instr_fifo_read      <= new_instruction_read and (not instr_fifo_empty);
  instr_vci_info       <=
    VCI_INFO_ROM(to_integer(unsigned(instruction_pipeline(0).op(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0))));

  -- purpose: Indicate if instructions are valid
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then
        valid_pipeline(0) <= '0';
        first_pipeline(0) <= '0';
        flush             <= '0';
      else
        if stall = '0' then
          first_pipeline(0) <= '0';
        end if;

        if not_executing = '1' then
          --If flushing, it's done when not_executing
          flush <= '0';

          --If flushing and not_executing, set first cycle if there's already a
          --waiting instruction
          if flush = '1' then
            first_pipeline(0) <= valid_pipeline(0);
          end if;
        end if;

        if new_instruction_read = '1' then
          if op_is_custom(instruction_pipeline(0).op) = '1' then
            flush <= instr_vci_info.flush;
          end if;
          if instr_fifo_empty = '0' then
            valid_pipeline(0) <= '1';
            first_pipeline(0) <= '1';
          else
            valid_pipeline(0) <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Register new instructions and shift
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if new_instruction_read = '1' then
        instruction_pipeline(0) <= instr_fifo_readdata;
      end if;
      if stall = '0' then
        instruction_pipeline(3 downto 1) <= instruction_pipeline(2 downto 0);
        first_pipeline(3 downto 1)       <= first_pipeline(2 downto 0);
        valid_pipeline(1)                <= core_instr_pending;
        valid_pipeline(3 downto 2)       <= valid_pipeline(2 downto 1);
      end if;
      first_pipeline(PIPELINE_STAGES-1 downto 4)   <= first_pipeline(PIPELINE_STAGES-2 downto 3);
      valid_pipeline(valid_pipeline'left downto 4) <= valid_pipeline(valid_pipeline'left-1 downto 3);
    end if;
  end process;

  -- purpose: reset last stages in pipeline so they doesn't get put into shift register (helps with timing)
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then               -- synchronous reset (active high)
        instruction_pipeline(instruction_pipeline'left downto 4) <= (others => INSTRUCTION_NULL);
      else
        instruction_pipeline(instruction_pipeline'left downto 4) <= instruction_pipeline(instruction_pipeline'left-1 downto 3);
      end if;
    end if;
  end process;

  not_executing <= '1' when valid_pipeline(valid_pipeline'left downto 1) = std_logic_vector(to_unsigned(0, valid_pipeline'length-1)) else '0';

  address_generation : addr_gen
    generic map (
      VECTOR_LANES               => VECTOR_LANES,
      VECTOR_CUSTOM_INSTRUCTIONS => VECTOR_CUSTOM_INSTRUCTIONS,
      VCI_CONFIGS                => VCI_CONFIGS,
      VCI_INFO_ROM               => VCI_INFO_ROM,
      MAX_MASKED_WAVES           => MAX_MASKED_WAVES,
      MASK_PARTITIONS            => MASK_PARTITIONS,

      PIPELINE_STAGES      => PIPELINE_STAGES,
      HAZARD_STAGES        => HAZARD_STAGES,
      STAGE_IN_SHIFT_START => STAGE_IN_SHIFT_START,
      STAGE_MUL_START      => STAGE_MUL_START,
      STAGE_ACCUM_START    => STAGE_ACCUM_START,
      STAGE_ACCUM_END      => STAGE_ACCUM_END,

      CFG_FAM => CFG_FAM,

      ADDR_WIDTH => ADDR_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      core_instr_pending   => core_instr_pending,
      dma_status           => dma_status,
      instruction_pipeline => instruction_pipeline,

      mask_writedata_enables => mask_writedata_enables,
      mask_status_update     => mask_status_update,
      mask_length_nonzero    => mask_length_nonzero,

      core_instr_read => core_instr_read,
      stall           => stall,

      in_shift_element         => in_shift_element,
      exec_dest_addr           => exec_dest_addr,
      exec_byteena             => exec_byteena,
      exec_first_column        => exec_first_column,
      exec_last_cycle          => exec_last_cycle,
      exec_last_cooldown_cycle => exec_last_cooldown_cycle,
      exec_read                => exec_read,
      exec_write               => exec_write,
      exec_we                  => exec_we,

      scalar_a => scalar_a,
      offset_a => offset_a,
      offset_b => offset_b,

      scratch_port_a => scratch_port_a,
      scratch_port_b => scratch_port_b
      );

  input_shifter : in_shifter
    generic map (
      VECTOR_LANES => VECTOR_LANES,

      PIPELINE_STAGES      => PIPELINE_STAGES,
      EXTRA_ALIGN_STAGES   => EXTRA_ALIGN_STAGES,
      STAGE_IN_SHIFT_START => STAGE_IN_SHIFT_START,
      STAGE_IN_SHIFT_END   => STAGE_IN_SHIFT_END,

      ADDR_WIDTH => ADDR_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      instruction_pipeline => instruction_pipeline,
      scalar_a             => scalar_a,
      in_shift_element     => in_shift_element,

      offset_a   => offset_a,
      readdata_a => readdata_a,
      shifted_a  => shifted_a,

      offset_b   => offset_b,
      readdata_b => readdata_b,
      shifted_b  => shifted_b
      );

  exec_stage : exec_unit
    generic map (
      VECTOR_LANES => VECTOR_LANES,
      VCI_INFO_ROM => VCI_INFO_ROM,

      MIN_MULTIPLIER_HW => MIN_MULTIPLIER_HW,

      MULFXP_WORD_FRACTION_BITS => MULFXP_WORD_FRACTION_BITS,
      MULFXP_HALF_FRACTION_BITS => MULFXP_HALF_FRACTION_BITS,
      MULFXP_BYTE_FRACTION_BITS => MULFXP_BYTE_FRACTION_BITS,

      CFG_FAM => CFG_FAM,

      PIPELINE_STAGES => PIPELINE_STAGES,
      STAGE_MUL_START => STAGE_MUL_START,
      STAGE_MUL_END   => STAGE_MUL_END,

      ADDR_WIDTH => ADDR_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      exec_first_cycle         => first_pipeline(STAGE_MUL_START),
      exec_first_column        => exec_first_column,
      exec_last_cycle          => exec_last_cycle,
      exec_last_cooldown_cycle => exec_last_cooldown_cycle,
      exec_read                => exec_read,
      exec_write               => exec_write,
      exec_we                  => exec_we,
      exec_byteena             => exec_byteena,
      exec_dest_addr           => exec_dest_addr,
      instruction_pipeline     => instruction_pipeline,

      data_a => shifted_a,
      data_b => shifted_b,

      accum_first_column => accum_first_column,
      accum_byteena      => accum_byteena,
      accum_dest_addr    => accum_dest_addr,
      exec_out           => accum_writedata,
      accum_we           => accum_we,

      mask_writedata_enables => mask_writedata_enables,

      vci_valid  => vci_valid,
      vci_signed => vci_signed,
      vci_opsize => vci_opsize,

      vci_vector_start => vci_vector_start,
      vci_vector_end   => vci_vector_end,
      vci_byte_valid   => vci_byte_valid,
      vci_dest_addr_in => vci_dest_addr_in,

      vci_data_a => vci_data_a,
      vci_flag_a => vci_flag_a,
      vci_data_b => vci_data_b,
      vci_flag_b => vci_flag_b,

      vci_port          => vci_port,
      vci_data_out      => vci_data_out,
      vci_flag_out      => vci_flag_out,
      vci_byteenable    => vci_byteenable,
      vci_dest_addr_out => vci_dest_addr_out
      );

  accum_stage : accum_unit
    generic map (
      VECTOR_LANES => VECTOR_LANES,

      PIPELINE_STAGES   => PIPELINE_STAGES,
      ACCUM_DELAY       => ACCUM_DELAY,
      STAGE_ACCUM_START => STAGE_ACCUM_START,
      STAGE_ACCUM_END   => STAGE_ACCUM_END,

      ADDR_WIDTH => ADDR_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      accum_first_column   => accum_first_column,
      accum_byteena        => accum_byteena,
      accum_dest_addr      => accum_dest_addr,
      accum_writedata      => accum_writedata,
      accum_we             => accum_we,
      instruction_pipeline => instruction_pipeline,

      dest_byteena   => dest_byteena,
      dest_addr      => dest_addr,
      dest_writedata => dest_writedata,
      dest_we        => dest_we
      );

  output_shifter : out_shifter
    generic map (
      VECTOR_LANES => VECTOR_LANES,

      EXTRA_ALIGN_STAGES => EXTRA_ALIGN_STAGES,

      CFG_FAM => CFG_FAM,

      ADDR_WIDTH => ADDR_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      instruction      => instruction_pipeline(STAGE_OUT_SHIFT_START),
      next_instruction => instruction_pipeline(STAGE_OUT_SHIFT_START-1),

      dest_addr      => dest_addr,
      dest_byteena   => dest_byteena,
      dest_writedata => dest_writedata,
      dest_we        => dest_we,

      scratch_port_c => scratch_port_c
      );

end architecture rtl;
