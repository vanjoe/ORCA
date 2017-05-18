-- addr_gen.vhd
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

entity addr_gen is
  generic (
    VECTOR_LANES               : integer                                    := 1;
    VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS := 0;
    VCI_CONFIGS                : vci_config_array                           := DEFAULT_VCI_CONFIGS;
    VCI_INFO_ROM               : vci_info_array                             := DEFAULT_VCI_INFO_ROM;
    MAX_MASKED_WAVES           : positive range 128 to 8192                 := 128;
    MASK_PARTITIONS            : natural                                    := 1;

    PIPELINE_STAGES      : integer := 1;
    HAZARD_STAGES        : integer := 1;
    STAGE_IN_SHIFT_START : integer := 1;
    STAGE_MUL_START      : integer := 1;
    STAGE_ACCUM_START    : integer := 1;
    STAGE_ACCUM_END      : integer := 1;

    CFG_FAM : config_family_type;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    core_instr_pending   : in std_logic;
    dma_status           : in std_logic_vector(dma_info_vector_length(ADDR_WIDTH)-1 downto 0);
    instruction_pipeline : in instruction_pipeline_type;

    mask_writedata_enables : in  std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    mask_status_update     : out std_logic;
    mask_length_nonzero    : out std_logic;

    core_instr_read : out std_logic;
    stall           : out std_logic;

    in_shift_element         : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    exec_dest_addr           : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    exec_byteena             : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    exec_first_column        : out std_logic;
    exec_last_cycle          : out std_logic;
    exec_last_cooldown_cycle : out std_logic;
    exec_read                : out std_logic;
    exec_write               : out std_logic;
    exec_we                  : out std_logic;

    scalar_a : out std_logic_vector(31 downto 0);
    offset_a : out std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
    offset_b : out std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);

    scratch_port_a : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0);
    scratch_port_b : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0)
    );

  -- attribute secure_netlist     : string;  -- OFF, ENCRYPT, (PROHIBIT not allowed in Vivado)
  -- attribute secure_config      : string;  -- OFF, PROTECT
  -- attribute secure_net_editing : string;  -- OFF, PROHIBIT
  -- attribute secure_bitstream   : string;  -- OFF, PROHIBIT
  -- attribute secure_net_probing : string;  -- OFF, PROHIBIT
  -- attribute check_license      : string;

  -- attribute secure_netlist of addr_gen : entity is "OFF";
  -- attribute secure_config  of addr_gen : entity is "OFF";
  -- attribute check_license  of addr_gen : entity is "ipvblox_mxp";

end entity addr_gen;

architecture rtl of addr_gen is
  constant COMBI_SCRATCH_PORT_ADDR     : boolean  := CFG_SEL(CFG_FAM).COMBI_SCRATCH_PORT_ADDR;
  constant VECTOR_BYTES                : positive := VECTOR_LANES*4;
  constant CONNECTED_DEEP_PIPELINE_VCI : boolean  := connected_deep_pipeline(VCI_INFO_ROM);
  constant MAX_VCI_COUNTDOWN           : natural  := max_countdown(VCI_INFO_ROM);

  signal instruction    : instruction_type;
  signal instr_vci_info : vci_info_type;

  signal set_op                    : std_logic;
  signal set_vl                    : std_logic;
  signal set_vl2d_id               : std_logic;
  signal set_ia_ib                 : std_logic;
  signal first_cycle               : std_logic;
  signal multicycle                : std_logic;
  signal last_column               : std_logic;
  signal last_row                  : std_logic;
  signal last_cycle                : std_logic;
  signal process_op                : std_logic;
  signal vector_length             : std_logic_vector(ADDR_WIDTH downto 0);
  signal current_vl                : std_logic_vector(ADDR_WIDTH downto 0);
  signal element_num               : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal vector_elements_processed : std_logic_vector(ADDR_WIDTH downto 0);
  signal vci_elements_processed    : std_logic_vector(ADDR_WIDTH downto 0);
  signal vci_lanes                 : unsigned(log2(VECTOR_LANES) downto 0);
  signal elements_processed        : std_logic_vector(ADDR_WIDTH downto 0);
  signal size                      : opsize;
  signal in_size                   : opsize;
  signal out_size                  : opsize;
  signal is_custom                 : std_logic;
  signal is_three_d                : std_logic;

  signal shrink2 : std_logic;
  signal shrink4 : std_logic;
  signal shrink  : std_logic_vector(1 downto 0);
  signal grow2   : std_logic;
  signal grow4   : std_logic;
  signal grow    : std_logic_vector(1 downto 0);

  signal addr_a       : std_logic_vector(31 downto 0);
  signal instr_uses_a : std_logic;
  signal addr_b       : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal instr_uses_b : std_logic;

  signal vector_src_addr_add  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal vci_src_addr_add     : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal src_addr_add         : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal vector_dest_addr_add : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal vci_dest_addr_add    : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal dest_addr_add        : std_logic_vector(ADDR_WIDTH-1 downto 0);

  signal current_vl_lt    : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal current_vl_bytes : std_logic_vector(log2((VECTOR_LANES*4)) downto 0);

  type   scalar_shifter_type is array (SCRATCHPAD_READ_DELAY-1 downto 0) of std_logic_vector(31 downto 0);
  signal scalar_a_shifter            : scalar_shifter_type;
  type   offset_shifter_type is array (SCRATCHPAD_READ_DELAY-1 downto 0) of std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
  signal offset_b_shifter            : offset_shifter_type;
  signal prev_addr_b                 : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal prev_instr_uses_a           : std_logic;
  signal prev_instr_uses_b           : std_logic;
  type   byteena_shifter_type is array (natural range <>) of std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal exec_byteena_shifter        : byteena_shifter_type(STAGE_MUL_START-1 downto 0);
  signal mask_write_last             : std_logic;
  signal mask_write                  : std_logic;
  signal dest_addr_shifter           : addr_pipeline_type(PIPELINE_STAGES-1 downto 0);
  type   offset_pipeline_type is array (natural range <>) of unsigned(ADDR_WIDTH-1 downto 0);
  signal offset_shifter              : offset_pipeline_type(PIPELINE_STAGES-1 downto 0);
  signal mask_writedata_offset       : std_logic_vector(ADDR_WIDTH-1 downto 0);
  type   element_num_shifter_type is array (STAGE_IN_SHIFT_START-1 downto 0) of std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal element_num_shifter         : element_num_shifter_type;
  signal last_cycle_shifter          : std_logic_vector(HAZARD_STAGES-1 downto 0);
  signal last_cooldown_cycle_shifter : std_logic_vector(HAZARD_STAGES-1 downto 0);
  signal last_column_shifter         : std_logic_vector(0 downto 0);
  signal first_column_shifter        : std_logic_vector(HAZARD_STAGES-1 downto 0);
  signal we_shifter                  : std_logic_vector(HAZARD_STAGES-1 downto 0);
  signal read_shifter                : std_logic_vector(HAZARD_STAGES-1 downto 0);
  signal write_shifter               : std_logic_vector(HAZARD_STAGES-1 downto 0);
  signal mask_set_shifter            : std_logic_vector(STAGE_MUL_START+1 downto 0);
  signal mask_set_last_shifter       : std_logic_vector(STAGE_MUL_START+2 downto 0);
  signal current_instruction         : std_logic_vector(HAZARD_STAGES-1 downto 0);

  signal hazard                : std_logic;
  signal dma_hazard            : std_logic;
  signal dma_hazard_shifter    : std_logic_vector(arbiter_extra_align_stages(VECTOR_LANES)-1 downto 0);
  signal instr_hazard          : std_logic;
  signal instr_hazard_pipeline : std_logic_vector(HAZARD_STAGES-1 downto 0);
  signal instr_hazard_shifter  : std_logic_vector(HAZARD_STAGES downto 0);
  signal current_vl_lt_ep      : std_logic;

  signal row_addr_a           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal row_addr_b           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal row_addr_dest        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal next_row_addr_a      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal next_row_addr_b      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal next_row_addr_dest   : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal row_incr_a           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal row_incr_b           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal row_incr_dest        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal current_vl2d         : std_logic_vector(ADDR_WIDTH downto 0);
  signal vector_length_2d     : std_logic_vector(ADDR_WIDTH downto 0);
  signal current_vl2d_lte_one : std_logic;
  signal new_row              : std_logic;

  signal current_vl3d         : std_logic_vector(ADDR_WIDTH downto 0);
  signal vector_length_3d     : std_logic_vector(ADDR_WIDTH downto 0);
  signal current_vl3d_lte_one : std_logic;
  signal new_mat              : std_logic;
  signal last_mat             : std_logic;
  signal set_vl3d_id3d        : std_logic;
  signal set_ia3d_ib3d        : std_logic;
  signal mat_incr_a           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal mat_incr_b           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal mat_incr_dest        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal mat_addr_a           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal mat_addr_b           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal mat_addr_dest        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal next_mat_addr_a      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal next_mat_addr_b      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal next_mat_addr_dest   : std_logic_vector(ADDR_WIDTH-1 downto 0);

  signal scratch_port_a_addr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal scratch_port_a_byteena   : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal scratch_port_a_writedata : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal scratch_port_a_we        : std_logic;
  signal scratch_port_b_addr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal scratch_port_b_byteena   : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal scratch_port_b_writedata : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal scratch_port_b_we        : std_logic;

  signal scratch_port_a_addr_ce : std_logic;
  signal scratch_port_b_addr_ce : std_logic;

  signal masked_addrs  : std_logic;
  signal writes_mask   : std_logic;
  signal mask_set_slip : std_logic;

  signal masked_enables     : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal masked_offset      : std_logic_vector(log2(MAX_MASKED_WAVES*VECTOR_LANES*4)+1 downto 0);
  signal masked_offset_src  : std_logic_vector(log2(MAX_MASKED_WAVES*VECTOR_LANES*4)+1 downto 0);
  signal masked_offset_dest : std_logic_vector(log2(MAX_MASKED_WAVES*VECTOR_LANES*4)+1 downto 0);
  signal masked_end         : std_logic;

  signal mask_exec_slip          : std_logic;
  signal process_op_no_exec_slip : std_logic;
  signal last_cooldown_cycle     : std_logic;
  signal cooling_down            : std_logic;
begin
  scratch_port_a <= scratchpad_control_in_flatten(scratch_port_a_addr,
                                                  scratch_port_a_addr_ce,
                                                  scratch_port_a_byteena,
                                                  scratch_port_a_writedata,
                                                  scratch_port_a_we);
  scratch_port_b <= scratchpad_control_in_flatten(scratch_port_b_addr,
                                                  scratch_port_b_addr_ce,
                                                  scratch_port_b_byteena,
                                                  scratch_port_b_writedata,
                                                  scratch_port_b_we);


  scratch_port_a_byteena   <= (others => '1');
  scratch_port_b_byteena   <= (others => '1');
  scratch_port_a_we        <= '0';
  scratch_port_b_we        <= '0';
  scratch_port_a_writedata <= (others => (data => (others => '0'), flag => '0'));
  scratch_port_b_writedata <= (others => (data => (others => '0'), flag => '0'));

  instruction    <= instruction_pipeline(0);
  instr_vci_info <=
    VCI_INFO_ROM(to_integer(unsigned(instruction_pipeline(0).op(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0))));
  vci_lanes <= resize(instr_vci_info.lanes, log2(VECTOR_LANES)+1);

  --3D bit without 2D bit is an encoding for mask setup, not real 3D instruction
  is_three_d <= instruction.three_d and instruction.two_d;

  --Decoded parameters from instruction
  set_op        <= '1' when core_instr_pending = '1' and instruction.op = OP_SET_VL else '0';
  set_vl        <= set_op and (not instruction.two_d);
  set_vl2d_id   <= set_op and (instruction.two_d and (not instruction.three_d)) and (not instruction.acc);
  set_ia_ib     <= set_op and (instruction.two_d and (not instruction.three_d)) and instruction.acc;
  set_vl3d_id3d <= set_op and instruction.three_d and (not instruction.acc);
  set_ia3d_ib3d <= set_op and instruction.three_d and instruction.acc;
  masked_addrs  <= instruction.masked and ((not writes_mask) or instruction.acc);
  writes_mask   <= instruction.masked and (instruction.three_d or instruction.two_d);

  --Indicates normal instruction execution (not set/dma/etc or invalid/hazard)
  process_op_no_exec_slip <= op_is_process(instruction.op) and core_instr_pending and
                             (not hazard) and (not mask_set_slip);
  process_op <= op_is_process(instruction.op) and core_instr_pending and
                (not hazard) and (not mask_exec_slip) and (not mask_set_slip);

  --Set operations execute immediately, otherwise read a new instruction on the
  --last cycle unless it's a deep pipeline VCI
  core_instr_read <= set_op or last_cycle when is_custom = '0' or instr_vci_info.deep_pipeline = '0' else
                     last_cooldown_cycle and (not hazard);
  current_vl_lt_ep     <= '1' when current_vl <= elements_processed                              else '0';
  current_vl2d_lte_one <= '1' when unsigned(current_vl2d) <= to_unsigned(1, current_vl2d'length) else '0';
  current_vl3d_lte_one <= '1' when unsigned(current_vl3d) <= to_unsigned(1, current_vl3d'length) else '0';
  last_column          <= process_op and current_vl_lt_ep
                          when masked_addrs = '0' else process_op and masked_end;
  last_row <= process_op and (current_vl2d_lte_one or (not instruction.two_d))
              when masked_addrs = '0' else process_op and masked_end;
  last_mat <= process_op and (current_vl3d_lte_one or (not is_three_d)) when masked_addrs = '0'
              else process_op and masked_end;
  last_cycle  <= last_column and last_row and last_mat;
  first_cycle <= process_op and (not multicycle) and (not cooling_down);

  is_custom <= op_is_custom(instruction.op);

  --Manage input/output size, including how much to add to src/dests
  size     <= instruction.size;
  in_size  <= instruction.in_size;
  out_size <= instruction.out_size;
  shrink2 <= '1' when ((size = OPSIZE_WORD and out_size = OPSIZE_HALF) or
                       (size = OPSIZE_HALF and out_size = OPSIZE_BYTE)) else
             '0';
  shrink4 <= '1' when size = OPSIZE_WORD and out_size = OPSIZE_BYTE else '0';
  grow2 <= '1' when ((in_size = OPSIZE_HALF and size = OPSIZE_WORD) or
                     (in_size = OPSIZE_BYTE and size = OPSIZE_HALF)) else
           '0';
  grow4 <= '1' when in_size = OPSIZE_BYTE and size = OPSIZE_WORD
           else '0';

  shrink <= shrink4 & shrink2;
  with shrink select
    vector_dest_addr_add <=
    std_logic_vector(to_unsigned((VECTOR_LANES*2), dest_addr_add'length)) when "01",
    std_logic_vector(to_unsigned(VECTOR_LANES, dest_addr_add'length))     when "10",
    std_logic_vector(to_unsigned((VECTOR_LANES*4), dest_addr_add'length)) when others;
  with shrink select
    vci_dest_addr_add <=
    std_logic_vector(resize((vci_lanes & '0'), dest_addr_add'length))  when "01",
    std_logic_vector(resize(vci_lanes, dest_addr_add'length))          when "10",
    std_logic_vector(resize((vci_lanes & "00"), dest_addr_add'length)) when others;
  dest_addr_add <= vci_dest_addr_add when is_custom = '1' else vector_dest_addr_add;
  with shrink select
    masked_offset_dest <=
    '0' & masked_offset(masked_offset'left downto 1)  when "01",
    "00" & masked_offset(masked_offset'left downto 2) when "10",
    masked_offset                                     when others;

  grow <= grow4 & grow2;
  with grow select
    vector_src_addr_add <=
    std_logic_vector(to_unsigned((VECTOR_LANES*2), src_addr_add'length)) when "01",
    std_logic_vector(to_unsigned(VECTOR_LANES, src_addr_add'length))     when "10",
    std_logic_vector(to_unsigned((VECTOR_LANES*4), src_addr_add'length)) when others;
  with grow select
    vci_src_addr_add <=
    std_logic_vector(resize((vci_lanes & '0'), src_addr_add'length))  when "01",
    std_logic_vector(resize(vci_lanes, src_addr_add'length))          when "10",
    std_logic_vector(resize((vci_lanes & "00"), src_addr_add'length)) when others;
  src_addr_add <= vci_src_addr_add when is_custom = '1' else vector_src_addr_add;
  with grow select
    masked_offset_src <=
    '0' & masked_offset(masked_offset'left downto 1)  when "01",
    "00" & masked_offset(masked_offset'left downto 2) when "10",
    masked_offset                                     when others;

  with size select
    vector_elements_processed <=
    std_logic_vector(to_unsigned((VECTOR_LANES*2), elements_processed'length)) when OPSIZE_HALF,
    std_logic_vector(to_unsigned((VECTOR_LANES*4), elements_processed'length)) when OPSIZE_BYTE,
    std_logic_vector(to_unsigned(VECTOR_LANES, elements_processed'length))     when others;
  with size select
    vci_elements_processed <=
    std_logic_vector(resize((vci_lanes & '0'), elements_processed'length))  when OPSIZE_HALF,
    std_logic_vector(resize((vci_lanes & "00"), elements_processed'length)) when OPSIZE_BYTE,
    std_logic_vector(resize(vci_lanes, elements_processed'length))          when others;
  elements_processed <= vci_elements_processed when is_custom = '1' else vector_elements_processed;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then               -- synchronous reset (active high)
        vector_length    <= (others => '0');
        current_vl       <= (others => '0');
        element_num      <= (others => '0');
        current_vl2d     <= (others => '0');
        vector_length_2d <= (others => '0');
        row_incr_dest    <= (others => '0');
        row_incr_a       <= (others => '0');
        row_incr_b       <= (others => '0');
        current_vl3d     <= (others => '0');
        vector_length_3d <= (others => '0');
        mat_incr_dest    <= (others => '0');
        mat_incr_a       <= (others => '0');
        mat_incr_b       <= (others => '0');
      else
        if set_vl = '1' then
          vector_length <= instruction.a(vector_length'range);
          current_vl    <= instruction.a(current_vl'range);
          element_num   <= (others => '0');
        elsif last_column = '1' then
          current_vl  <= vector_length;
          element_num <= (others => '0');
        elsif process_op = '1' and current_vl_lt_ep = '0' and cooling_down = '0' then
          current_vl  <= std_logic_vector(unsigned(current_vl) - unsigned(elements_processed));
          element_num <= std_logic_vector(unsigned(element_num) + unsigned(elements_processed(element_num'range)));
        end if;

        if set_vl2d_id = '1' then
          vector_length_2d <= instruction.a(vector_length_2d'range);
          current_vl2d     <= instruction.a(current_vl2d'range);
          row_incr_dest    <= instruction.b(ADDR_WIDTH-1 downto 0);
        elsif last_row = '1' and last_column = '1' then
          current_vl2d <= vector_length_2d;
        elsif process_op = '1' and current_vl_lt_ep = '1' and cooling_down = '0' then
          current_vl2d <= std_logic_vector(unsigned(current_vl2d) - to_unsigned(1, current_vl2d'length));
        end if;
        if set_ia_ib = '1' then
          row_incr_a <= instruction.a(row_incr_a'range);
          row_incr_b <= instruction.b(ADDR_WIDTH-1 downto 0);
        end if;

        if set_vl3d_id3d = '1' then
          vector_length_3d <= instruction.a(vector_length_3d'range);
          current_vl3d     <= instruction.a(current_vl3d'range);
          mat_incr_dest    <= instruction.b(ADDR_WIDTH-1 downto 0);
        elsif last_mat = '1' and last_row = '1' and last_column = '1' then
          current_vl3d <= vector_length_3d;
        elsif process_op = '1' and current_vl2d_lte_one = '1' and current_vl_lt_ep = '1' and cooling_down = '0' then
          current_vl3d <= std_logic_vector(unsigned(current_vl3d) - to_unsigned(1, current_vl3d'length));
        end if;
        if set_ia3d_ib3d = '1' then
          mat_incr_a <= instruction.a(mat_incr_a'range);
          mat_incr_b <= instruction.b(ADDR_WIDTH-1 downto 0);
        end if;
      end if;
    end if;
  end process;
  next_row_addr_a    <= std_logic_vector(unsigned(row_addr_a) + unsigned(row_incr_a));
  next_row_addr_b    <= std_logic_vector(unsigned(row_addr_b) + unsigned(row_incr_b));
  next_row_addr_dest <= std_logic_vector(unsigned(row_addr_dest) + unsigned(row_incr_dest));
  next_mat_addr_a    <= std_logic_vector(unsigned(mat_addr_a) + unsigned(mat_incr_a));
  next_mat_addr_b    <= std_logic_vector(unsigned(mat_addr_b) + unsigned(mat_incr_b));
  next_mat_addr_dest <= std_logic_vector(unsigned(mat_addr_dest) + unsigned(mat_incr_dest));

  no_masked_unit_gen : if MASK_PARTITIONS = 0 generate
    mask_set_slip       <= '0';
    mask_status_update  <= '0';
    mask_length_nonzero <= '-';
    masked_enables      <= (others => '0');
    masked_offset       <= (others => '-');
    masked_end          <= '1';
    mask_exec_slip      <= '0';
  end generate no_masked_unit_gen;
  masked_unit_gen : if MASK_PARTITIONS > 0 generate
    constant EXTRA_MASK_STAGES : positive := 1;

    signal next_mask : std_logic;

    --Signals for extra mask delay stages for timing
    signal masked_enables_nodelay : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    signal masked_offset_nodelay  : std_logic_vector(log2(MAX_MASKED_WAVES*VECTOR_LANES*4)+1 downto 0);
    signal masked_end_nodelay     : std_logic;

    signal masked_enables_delayed_by : byteena_shifter_type(EXTRA_MASK_STAGES downto 0);
    type   mask_offset_shifter_type is array (natural range <>) of std_logic_vector(log2(MAX_MASKED_WAVES*VECTOR_LANES*4)+1 downto 0);
    signal masked_offset_delayed_by  : mask_offset_shifter_type(EXTRA_MASK_STAGES downto 0);
    signal masked_end_delayed_by     : std_logic_vector(EXTRA_MASK_STAGES downto 0);
    signal mask_valid_delayed_by     : std_logic_vector(EXTRA_MASK_STAGES downto 0);
    signal next_mask_nodelay         : std_logic;
    signal next_mask_shift           : std_logic;
  begin
    the_masked_unit : masked_unit
      generic map (
        VECTOR_LANES     => VECTOR_LANES,
        MAX_MASKED_WAVES => MAX_MASKED_WAVES,
        MASK_PARTITIONS  => MASK_PARTITIONS,

        ADDR_WIDTH => ADDR_WIDTH
        )
      port map (
        clk   => clk,
        reset => reset,

        mask_write             => mask_write,
        mask_write_size        => instruction_pipeline(STAGE_MUL_START).size,
        mask_write_last        => mask_write_last,
        mask_writedata_enables => mask_writedata_enables,
        mask_writedata_offset  => mask_writedata_offset,

        next_mask           => next_mask,
        mask_read_size      => instruction.size,
        mask_status_update  => mask_status_update,
        mask_length_nonzero => mask_length_nonzero,
        masked_enables      => masked_enables_nodelay,
        masked_offset       => masked_offset_nodelay,
        masked_end          => masked_end_nodelay
        );
    masked_enables_delayed_by(0) <= masked_enables_nodelay when mask_valid_delayed_by(0) = '1' else (others => '0');
    masked_offset_delayed_by(0)  <= masked_offset_nodelay;
    masked_end_delayed_by(0)     <= masked_end_nodelay     when mask_valid_delayed_by(0) = '1' else '0';
    mask_valid_delayed_by(0)     <=
      '1' when masked_end_delayed_by(EXTRA_MASK_STAGES downto 1) = replicate_bit('0', EXTRA_MASK_STAGES) else '0';

    vci_equal_vector_gen : if min_vci_lanes(VECTOR_LANES, VECTOR_CUSTOM_INSTRUCTIONS, VCI_CONFIGS) = VECTOR_LANES generate
      next_mask       <= next_mask_nodelay when mask_valid_delayed_by(0) = '1' else '0';
      next_mask_shift <= next_mask_nodelay;
      masked_offset   <= masked_offset_delayed_by(EXTRA_MASK_STAGES);
      masked_end      <= masked_end_delayed_by(EXTRA_MASK_STAGES);
      masked_enables  <= masked_enables_delayed_by(EXTRA_MASK_STAGES);
    end generate vci_equal_vector_gen;
    vci_less_than_vector_gen : if min_vci_lanes(VECTOR_LANES, VECTOR_CUSTOM_INSTRUCTIONS, VCI_CONFIGS) < VECTOR_LANES generate
      signal masked_offset_offset      : unsigned(log2(VECTOR_BYTES)-1 downto 0);
      signal next_masked_offset_offset : unsigned(log2(VECTOR_BYTES) downto 0);
      signal next_vci_mask             : std_logic;

      --Need to shift mask enables by the number of VCI lanes currently in use.
      --Instead of creating a shifter for every possible # of lanes, only
      --create shifted versions for unique VCI lanes instantiated.  These
      --constants have the number of unqiue VCI lanes (not including VCIs that
      --are VECTOR_LANES wide) and array of the values.
      constant NUM_NARROW_LANES : positive :=
        num_narrow_vci_lanes(VECTOR_LANES, VECTOR_CUSTOM_INSTRUCTIONS, VCI_CONFIGS);
      constant NARROW_LANES : lanes_array(NUM_NARROW_LANES-1 downto 0) :=
        narrow_vci_lanes(VECTOR_LANES, NUM_NARROW_LANES, VECTOR_CUSTOM_INSTRUCTIONS, VCI_CONFIGS);
    begin
      next_masked_offset_offset <= resize(masked_offset_offset, next_masked_offset_offset'length) +
                                   resize((vci_lanes & "00"), next_masked_offset_offset'length);
      next_vci_mask   <= next_masked_offset_offset(next_masked_offset_offset'left);
      next_mask_shift <= next_mask_nodelay and ((not is_custom) or next_vci_mask);
      next_mask       <= next_mask_nodelay and mask_valid_delayed_by(0) and ((not is_custom) or next_vci_mask);
      masked_end      <= masked_end_delayed_by(EXTRA_MASK_STAGES) and ((not is_custom) or next_vci_mask);

      --Increment masked_offset_offset by vci_lanes on masked VCI until the
      --offset wraps around to the next wavefront
      vci_mask_tracker : process (clk)
      begin  -- process vci_mask_tracker
        if clk'event and clk = '1' then  -- rising clock edge
          if next_mask_shift = '1' then
            masked_offset_offset <= to_unsigned(0, masked_offset_offset'length);
            masked_enables       <= masked_enables_delayed_by(EXTRA_MASK_STAGES-1);
          elsif is_custom = '1' and next_mask_nodelay = '1' then
            masked_offset_offset <= next_masked_offset_offset(masked_offset_offset'range);
            for ilanes in NUM_NARROW_LANES-1 downto 0 loop
              if vci_lanes = NARROW_LANES(ilanes) then
                masked_enables(((VECTOR_LANES-NARROW_LANES(ilanes))*4)-1 downto 0) <=
                  masked_enables((VECTOR_LANES*4)-1 downto NARROW_LANES(ilanes)*4);
                masked_enables((VECTOR_LANES*4)-1 downto (VECTOR_LANES-NARROW_LANES(ilanes))*4) <= (others => '0');
              end if;
            end loop;  -- ilanes
          end if;

          if reset = '1' then           -- synchronous reset (active high)
            masked_offset_offset <= to_unsigned(0, masked_offset_offset'length);
          end if;
        end if;
      end process vci_mask_tracker;

      masked_offset <= masked_offset_delayed_by(EXTRA_MASK_STAGES)(masked_offset_delayed_by(EXTRA_MASK_STAGES)'left downto log2(VECTOR_BYTES)) & std_logic_vector(masked_offset_offset);
    end generate vci_less_than_vector_gen;


    delayers : process (clk)
    begin  -- process delayers
      if clk'event and clk = '1' then   -- rising clock edge
        if next_mask_shift = '1' then
          mask_valid_delayed_by(EXTRA_MASK_STAGES downto 1) <=
            mask_valid_delayed_by(EXTRA_MASK_STAGES-1 downto 0);
          masked_enables_delayed_by(EXTRA_MASK_STAGES downto 1) <=
            masked_enables_delayed_by(EXTRA_MASK_STAGES-1 downto 0);
          masked_offset_delayed_by(EXTRA_MASK_STAGES downto 1) <=
            masked_offset_delayed_by(EXTRA_MASK_STAGES-1 downto 0);
          masked_end_delayed_by(EXTRA_MASK_STAGES downto 1) <=
            masked_end_delayed_by(EXTRA_MASK_STAGES-1 downto 0);
        end if;

        if reset = '1' then             -- synchronous reset (active high)
          mask_valid_delayed_by(EXTRA_MASK_STAGES downto 1)     <= (others => '0');
          masked_enables_delayed_by(EXTRA_MASK_STAGES downto 1) <= (others => (others => '0'));
          masked_offset_delayed_by(EXTRA_MASK_STAGES downto 1)  <= (others => (others => '0'));
          masked_end_delayed_by(EXTRA_MASK_STAGES downto 1)     <= (others => '0');
        end if;
      end if;
    end process delayers;
    mask_exec_slip <= masked_addrs and (not mask_valid_delayed_by(EXTRA_MASK_STAGES)) and (not cooling_down);

    next_mask_nodelay <= process_op_no_exec_slip and masked_addrs and (not cooling_down);
    mask_set_slip     <=
      masked_addrs when mask_set_last_shifter /= std_logic_vector(to_unsigned(0, mask_set_last_shifter'length))
      else '0';
  end generate masked_unit_gen;

  -- purpose: keep track of multiple cycle instructions
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then               -- synchronous reset (active high)
        multicycle <= '0';
      else
        if last_cycle = '1' then
          multicycle <= '0';
        elsif first_cycle = '1' then
          multicycle <= '1';
        end if;
      end if;
    end if;
  end process;

  -- purpose: track address registers, write enable, byte enable
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      if reset = '1' then               -- synchronous reset (active high)
        last_cycle_shifter(0)          <= '0';
        last_cooldown_cycle_shifter(0) <= '0';
        last_column_shifter(0)         <= '0';
        first_column_shifter(0)        <= '0';
        mask_set_shifter(0)            <= '0';
        mask_set_last_shifter(0)       <= '0';
        dest_addr_shifter(0)           <= (others => '0');
        offset_shifter(0)              <= to_unsigned(0, offset_shifter(0)'length);
        addr_a                         <= (others => '0');
        addr_b                         <= (others => '0');
        row_addr_a                     <= (others => '0');
        row_addr_b                     <= (others => '0');
        row_addr_dest                  <= (others => '0');
        mat_addr_a                     <= (others => '0');
        mat_addr_b                     <= (others => '0');
        mat_addr_dest                  <= (others => '0');
        new_row                        <= '0';
        new_mat                        <= '0';
      else
        if hazard = '0' then
          last_cycle_shifter(0)          <= last_cycle;
          last_cooldown_cycle_shifter(0) <= last_cooldown_cycle;
          last_column_shifter(0)         <= last_column;
          if first_cycle = '1' or last_column_shifter(0) = '1' then
            first_column_shifter(0) <= '1';
          else
            first_column_shifter(0) <= '0';
          end if;

          mask_set_shifter(0)      <= '0';
          mask_set_last_shifter(0) <= '0';
          new_row                  <= '0';
          new_mat                  <= '0';
          if first_cycle = '1' then
            row_addr_a                                  <= instruction.a(row_addr_a'range);
            row_addr_b                                  <= instruction.b(ADDR_WIDTH-1 downto 0);
            row_addr_dest                               <= instruction.dest(row_addr_dest'range);
            mat_addr_a                                  <= instruction.a(mat_addr_a'range);
            mat_addr_b                                  <= instruction.b(ADDR_WIDTH-1 downto 0);
            mat_addr_dest                               <= instruction.dest(mat_addr_dest'range);
            addr_a                                      <= instruction.a;
            addr_b                                      <= instruction.b(ADDR_WIDTH-1 downto 0);
            dest_addr_shifter(0)(ADDR_WIDTH-1 downto 0) <= instruction.dest(ADDR_WIDTH-1 downto 0);
            offset_shifter(0)                           <= to_unsigned(0, offset_shifter(0)'length);
            mask_set_shifter(0)                         <= writes_mask;
            mask_set_last_shifter(0)                    <= writes_mask and last_cycle;
            new_row                                     <= current_vl_lt_ep;
            new_mat                                     <= current_vl2d_lte_one and current_vl_lt_ep;
          elsif multicycle = '1' then
            mask_set_shifter(0)      <= writes_mask;
            mask_set_last_shifter(0) <= writes_mask and last_cycle;
            new_row                  <= current_vl_lt_ep;
            new_mat                  <= current_vl2d_lte_one and current_vl_lt_ep;
            if instruction.sv = '0' then
              if new_mat = '1' then
                addr_a(next_mat_addr_a'range) <= next_mat_addr_a;
                row_addr_a                    <= next_mat_addr_a;
                mat_addr_a                    <= next_mat_addr_a;
              elsif new_row = '1' then
                addr_a(next_row_addr_a'range) <= next_row_addr_a;
                row_addr_a                    <= next_row_addr_a;
              else
                addr_a(src_addr_add'range) <= std_logic_vector(unsigned(addr_a(src_addr_add'range)) + unsigned(src_addr_add));
              end if;
            end if;
            if new_mat = '1' then
              addr_b     <= next_mat_addr_b;
              row_addr_b <= next_mat_addr_b;
              mat_addr_b <= next_mat_addr_b;
            elsif new_row = '1' then
              addr_b     <= next_row_addr_b;
              row_addr_b <= next_row_addr_b;
            else
              addr_b <= std_logic_vector(unsigned(addr_b) + unsigned(src_addr_add));
            end if;
            if new_mat = '1' then
              dest_addr_shifter(0)(ADDR_WIDTH-1 downto 0) <= next_mat_addr_dest;
              row_addr_dest                               <= next_mat_addr_dest;
              mat_addr_dest                               <= next_mat_addr_dest;
            elsif new_row = '1' then
              dest_addr_shifter(0)(ADDR_WIDTH-1 downto 0) <= next_row_addr_dest;
              row_addr_dest                               <= next_row_addr_dest;
            elsif instruction.acc = '0' then
              dest_addr_shifter(0)(ADDR_WIDTH-1 downto 0) <= std_logic_vector(unsigned(dest_addr_shifter(0)(ADDR_WIDTH-1 downto 0)) + unsigned(dest_addr_add));
              offset_shifter(0)                           <= offset_shifter(0) + unsigned(dest_addr_add);
            end if;
          end if;

          if masked_addrs = '1' then
            if instruction.sv = '0' then
              addr_a <=
                std_logic_vector(unsigned(instruction.a) + resize(unsigned(masked_offset_src), addr_a'length));
            end if;
            addr_b <=
              std_logic_vector(unsigned(instruction.b(ADDR_WIDTH-1 downto 0)) +
                               resize(unsigned(masked_offset_src), addr_b'length));
            if instruction.acc = '0' then
              dest_addr_shifter(0)(ADDR_WIDTH-1 downto 0) <=
                std_logic_vector(unsigned(instruction.dest(ADDR_WIDTH-1 downto 0)) +
                                 resize(unsigned(masked_offset_dest), ADDR_WIDTH));
            end if;
            offset_shifter(0) <= resize(unsigned(masked_offset), offset_shifter(0)'length);
          end if;
        end if;
      end if;
    end if;
  end process;

  deep_pipeline_gen : if CONNECTED_DEEP_PIPELINE_VCI = true generate
    signal cooldown_countdown : unsigned(imax(1, log2(MAX_VCI_COUNTDOWN+1)-1) downto 0);
  begin
    process (clk)
    begin  -- process
      if clk'event and clk = '1' then   -- rising clock edge
        if hazard = '0' then
          read_shifter(0)     <= '0';
          write_shifter(0)    <= '0';
          we_shifter(0)       <= '0';
          last_cooldown_cycle <= '0';

          if process_op = '1' then
            read_shifter(0)  <= '1';
            write_shifter(0) <= '1';
            we_shifter(0)    <= (not writes_mask) and
                                ((not instruction.acc) or
                                 ((not masked_addrs) and current_vl_lt_ep) or
                                 (masked_addrs and masked_end));
            instr_uses_a <= not instruction.sv;
            if instruction.ve = '1' or instruction.op(OPCODE_BITS-2 downto 0) = OP_VMOV(OPCODE_BITS-2 downto 0) then
              instr_uses_b <= '0';
            else
              instr_uses_b <= '1';
            end if;
          end if;

          if cooling_down = '1' then
            instr_uses_a       <= '0';
            instr_uses_b       <= '0';
            read_shifter(0)    <= '0';
            write_shifter(0)   <= '0';
            we_shifter(0)      <= '0';
            cooldown_countdown <= cooldown_countdown - to_unsigned(1, cooldown_countdown'length);
            if cooldown_countdown = to_unsigned(2, cooldown_countdown'length) then
              last_cooldown_cycle <= '1';
            end if;
            if last_cooldown_cycle = '1' then
              cooling_down <= '0';
            end if;
          elsif last_cycle = '1' and is_custom = '1' and instr_vci_info.deep_pipeline = '1' then
            cooling_down       <= '1';
            cooldown_countdown <= instr_vci_info.countdown(cooldown_countdown'range);
            if instr_vci_info.countdown(cooldown_countdown'range) = to_unsigned(1, cooldown_countdown'length) then
              last_cooldown_cycle <= '1';
            end if;
          end if;
        end if;

        if reset = '1' then             -- synchronous reset (active high)
          last_cooldown_cycle <= '0';
          cooling_down        <= '0';
          instr_uses_a        <= '0';
          instr_uses_b        <= '0';
          read_shifter(0)     <= '0';
          write_shifter(0)    <= '0';
          we_shifter(0)       <= '0';
        end if;
      end if;
    end process;
    
  end generate deep_pipeline_gen;
  no_deep_pipeline_gen : if CONNECTED_DEEP_PIPELINE_VCI /= true generate
    --No deep pipeline VCIs, never cooling down
    last_cooldown_cycle <= '0';
    cooling_down        <= '0';

    process (clk)
    begin  -- process
      if clk'event and clk = '1' then   -- rising clock edge
        if hazard = '0' then
          read_shifter(0)  <= '0';
          write_shifter(0) <= '0';
          we_shifter(0)    <= '0';
          if first_cycle = '1' then
            instr_uses_a <= not instruction.sv;
            if instruction.ve = '1' or instruction.op(OPCODE_BITS-2 downto 0) = OP_VMOV(OPCODE_BITS-2 downto 0) then
              instr_uses_b <= '0';
            else
              instr_uses_b <= '1';
            end if;
            read_shifter(0)  <= '1';
            write_shifter(0) <= '1';
            we_shifter(0)    <= (not writes_mask) and
                                ((not instruction.acc) or
                                 ((not masked_addrs) and current_vl_lt_ep) or
                                 (masked_addrs and masked_end));
          elsif multicycle = '1' then
            read_shifter(0)  <= '1';
            write_shifter(0) <= '1';
            we_shifter(0)    <= (not writes_mask) and
                                ((not instruction.acc) or
                                 ((not masked_addrs) and current_vl_lt_ep) or
                                 (masked_addrs and masked_end));
          end if;
        end if;

        if reset = '1' then             -- synchronous reset (active high)
          instr_uses_a     <= '0';
          instr_uses_b     <= '0';
          read_shifter(0)  <= '0';
          write_shifter(0) <= '0';
          we_shifter(0)    <= '0';
        end if;
      end if;
    end process;

  end generate no_deep_pipeline_gen;

  addr_combi_gen : if COMBI_SCRATCH_PORT_ADDR = true generate
    -- combinational address outputs
    scratch_port_a_addr <= addr_a(scratch_port_a_addr'range);
    scratch_port_b_addr <= addr_b;

    scratch_port_a_addr_ce <= not hazard;
    scratch_port_b_addr_ce <= not hazard;
  end generate addr_combi_gen;

  addr_reg_gen : if COMBI_SCRATCH_PORT_ADDR = false generate
    process (clk)
    begin
      if clk'event and clk = '1' then
        if reset = '1' then
          scratch_port_a_addr <= (others => '0');
          scratch_port_b_addr <= (others => '0');
        else
          if hazard = '0' then
            scratch_port_a_addr <= addr_a(scratch_port_a_addr'range);
            scratch_port_b_addr <= addr_b;
          end if;
        end if;
      end if;
    end process;

    scratch_port_a_addr_ce <= '0';
    scratch_port_b_addr_ce <= '0';
  end generate addr_reg_gen;

  instr_hazard_detection : instr_hazard_detect
    generic map (
      VECTOR_LANES => VECTOR_LANES,

      PIPELINE_STAGES => PIPELINE_STAGES,
      HAZARD_STAGES   => HAZARD_STAGES,

      ADDR_WIDTH => ADDR_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      addr_a       => addr_a(ADDR_WIDTH-1 downto 0),
      instr_uses_a => instr_uses_a,
      addr_b       => addr_b,
      instr_uses_b => instr_uses_b,

      dest_addrs          => dest_addr_shifter,
      current_instruction => current_instruction,
      dest_write_shifter  => write_shifter,

      instr_hazard_pipeline => instr_hazard_pipeline
      );

  dma_hazard_detection : dma_hazard_detect
    generic map (
      VECTOR_LANES => VECTOR_LANES,

      ADDR_WIDTH => ADDR_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      dma_status => dma_status,

      addr_a       => addr_a(ADDR_WIDTH-1 downto 0),
      instr_uses_a => instr_uses_a,
      addr_b       => addr_b,
      instr_uses_b => instr_uses_b,
      addr_dest    => dest_addr_shifter(0)(ADDR_WIDTH-1 downto 0),
      write_dest   => write_shifter(0),

      prev_addr_a       => scalar_a_shifter(0)(ADDR_WIDTH-1 downto 0),
      prev_instr_uses_a => prev_instr_uses_a,
      prev_addr_b       => prev_addr_b,
      prev_instr_uses_b => prev_instr_uses_b,
      prev_addr_dest    => dest_addr_shifter(1)(ADDR_WIDTH-1 downto 0),
      prev_write_dest   => write_shifter(1),

      dma_hazard => dma_hazard
      );
  hazard <= '1' when (instr_hazard = '1' or
                      dma_hazard = '1' or
                      dma_hazard_shifter /= (std_logic_vector(to_unsigned(0, dma_hazard_shifter'length))))
            else '0';
  stall <= hazard;

  current_instruction(0)  <= '1';
  instr_hazard_shifter(0) <= '0';

  -- purpose: shift destination address, write enable, byte enable
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      dma_hazard_shifter(0) <= dma_hazard;
      for istage in 1 to dma_hazard_shifter'left loop
        dma_hazard_shifter(istage) <= dma_hazard_shifter(istage-1);
      end loop;  -- istage
      if hazard = '0' then
        scalar_a_shifter(0)    <= addr_a;
        scalar_a_shifter(1)    <= scalar_a_shifter(0);
        offset_b_shifter(0)    <= addr_b(log2((VECTOR_LANES*4))-1 downto 0);
        prev_addr_b            <= addr_b;
        prev_instr_uses_a      <= instr_uses_a;
        prev_instr_uses_b      <= instr_uses_b;
        offset_b_shifter(1)    <= offset_b_shifter(0);
        element_num_shifter(0) <= element_num;
        element_num_shifter(1) <= element_num_shifter(0);
        if masked_addrs = '0' then
          exec_byteena_shifter(0) <= current_vl_lt;
        else
          exec_byteena_shifter(0) <= masked_enables;
        end if;
        exec_byteena_shifter(1) <= exec_byteena_shifter(0);
        exec_byteena_shifter(2) <= exec_byteena_shifter(1);

        dest_addr_shifter(1)           <= dest_addr_shifter(0);
        dest_addr_shifter(2)           <= dest_addr_shifter(1);
        offset_shifter(1)              <= offset_shifter(0);
        offset_shifter(2)              <= offset_shifter(1);
        read_shifter(1)                <= read_shifter(0);
        read_shifter(2)                <= read_shifter(1);
        write_shifter(1)               <= write_shifter(0);
        write_shifter(2)               <= write_shifter(1);
        last_cycle_shifter(1)          <= last_cycle_shifter(0);
        last_cycle_shifter(2)          <= last_cycle_shifter(1);
        last_cooldown_cycle_shifter(1) <= last_cooldown_cycle_shifter(0);
        last_cooldown_cycle_shifter(2) <= last_cooldown_cycle_shifter(1);
        first_column_shifter(1)        <= first_column_shifter(0);
        first_column_shifter(2)        <= first_column_shifter(1);
        mask_set_shifter(1)            <= mask_set_shifter(0);
        mask_set_shifter(2)            <= mask_set_shifter(1);
        mask_set_last_shifter(1)       <= mask_set_last_shifter(0);
        mask_set_last_shifter(2)       <= mask_set_last_shifter(1);
        we_shifter(1)                  <= we_shifter(0);
        we_shifter(2)                  <= we_shifter(1);
        if first_cycle = '1' then
          current_instruction(1) <= '0';
          current_instruction(2) <= '0';
        else
          current_instruction(1) <= current_instruction(0);
          current_instruction(2) <= current_instruction(1);
        end if;
        instr_hazard_shifter(instr_hazard_shifter'left downto 1) <=
          instr_hazard_shifter(instr_hazard_shifter'left-1 downto 0) or
          instr_hazard_pipeline(instr_hazard_pipeline'left downto 0);
        if ((instr_hazard_shifter(instr_hazard_shifter'left-1 downto 0) or
             instr_hazard_pipeline(instr_hazard_pipeline'left downto 0)) /=
            std_logic_vector(to_unsigned(0, instr_hazard_pipeline'length))) then
          instr_hazard <= '1';
        else
          instr_hazard <= '0';
        end if;
      else
        read_shifter(2)                                          <= '0';
        write_shifter(2)                                         <= '0';
        last_cycle_shifter(2)                                    <= '0';
        last_cooldown_cycle_shifter(2)                           <= '0';
        first_column_shifter(2)                                  <= '0';
        mask_set_shifter(2)                                      <= '0';
        mask_set_last_shifter(2)                                 <= '0';
        we_shifter(2)                                            <= '0';
        instr_hazard_shifter(instr_hazard_shifter'left downto 1) <=
          instr_hazard_shifter(instr_hazard_shifter'left-1 downto 0);
        if (instr_hazard_shifter(instr_hazard_shifter'left-1 downto 0) /=
            std_logic_vector(to_unsigned(0, instr_hazard_shifter'length-1))) then
          instr_hazard <= '1';
        else
          instr_hazard <= '0';
        end if;
      end if;

      scalar_a_shifter(scalar_a_shifter'left downto 2) <=
        scalar_a_shifter(scalar_a_shifter'left-1 downto 1);
      offset_a <=
        scalar_a_shifter(scalar_a_shifter'left-1)(log2((VECTOR_LANES*4))-1 downto 0);
      offset_b_shifter(offset_b_shifter'left downto 2) <=
        offset_b_shifter(offset_b_shifter'left-1 downto 1);
      offset_b <=
        offset_b_shifter(offset_b_shifter'left-1)(log2((VECTOR_LANES*4))-1 downto 0);
      element_num_shifter(element_num_shifter'left downto 2) <=
        element_num_shifter(element_num_shifter'left-1 downto 1);
      exec_byteena_shifter(exec_byteena_shifter'left downto 3) <=
        exec_byteena_shifter(exec_byteena_shifter'left-1 downto 2);

      dest_addr_shifter(dest_addr_shifter'left downto 3) <=
        dest_addr_shifter(dest_addr_shifter'left-1 downto 2);
      offset_shifter(offset_shifter'left downto 3) <=
        offset_shifter(offset_shifter'left-1 downto 2);
      read_shifter(read_shifter'left downto 3) <=
        read_shifter(read_shifter'left-1 downto 2);
      write_shifter(write_shifter'left downto 3) <=
        write_shifter(write_shifter'left-1 downto 2);
      last_cycle_shifter(last_cycle_shifter'left downto 3) <=
        last_cycle_shifter(last_cycle_shifter'left-1 downto 2);
      last_cooldown_cycle_shifter(last_cooldown_cycle_shifter'left downto 3) <=
        last_cooldown_cycle_shifter(last_cooldown_cycle_shifter'left-1 downto 2);
      first_column_shifter(first_column_shifter'left downto 3) <=
        first_column_shifter(first_column_shifter'left-1 downto 2);
      mask_set_shifter(mask_set_shifter'left downto 3) <=
        mask_set_shifter(mask_set_shifter'left-1 downto 2);
      mask_set_last_shifter(mask_set_last_shifter'left downto 3) <=
        mask_set_last_shifter(mask_set_last_shifter'left-1 downto 2);
      we_shifter(we_shifter'left downto 3) <=
        we_shifter(we_shifter'left-1 downto 2);
      if first_cycle = '1' then
        current_instruction(current_instruction'left downto 3) <=
          (others => '0');
      else
        current_instruction(current_instruction'left downto 3) <=
          current_instruction(current_instruction'left-1 downto 2);
      end if;

      -- Reset timing sensitive stages to keep them out of shift registers
      if reset = '1' then               -- synchronous reset (active high)
        instr_hazard                                           <= '0';
        offset_shifter(1)                                      <= (others => '0');
        dest_addr_shifter(STAGE_ACCUM_END)                     <= (others => '0');
        current_instruction(current_instruction'left downto 1) <= (others => '0');
        exec_byteena_shifter(exec_byteena_shifter'left)        <= (others => '0');
        element_num_shifter(element_num_shifter'left)          <= (others => '0');
        we_shifter(STAGE_MUL_START-1)                          <= '0';
        read_shifter(STAGE_MUL_START-1)                        <= '0';
        write_shifter(STAGE_MUL_START-1)                       <= '0';
        scalar_a_shifter(scalar_a_shifter'left)                <= (others => '0');
      end if;
    end if;
  end process;
  scalar_a                 <= scalar_a_shifter(scalar_a_shifter'left);
  exec_byteena             <= exec_byteena_shifter(exec_byteena_shifter'left);
  mask_write_last          <= mask_set_last_shifter(STAGE_MUL_START-1);
  mask_write               <= mask_set_shifter(STAGE_MUL_START-1);
  exec_dest_addr           <= dest_addr_shifter(STAGE_MUL_START-1)(ADDR_WIDTH-1 downto 0);
  mask_writedata_offset    <= std_logic_vector(offset_shifter(STAGE_MUL_START-1));
  exec_read                <= read_shifter(STAGE_MUL_START-1);
  exec_write               <= write_shifter(STAGE_MUL_START-1);
  exec_we                  <= we_shifter(STAGE_MUL_START-1);
  exec_last_cycle          <= last_cycle_shifter(STAGE_MUL_START-1);
  exec_last_cooldown_cycle <= last_cooldown_cycle_shifter(STAGE_MUL_START-1);
  exec_first_column        <= first_column_shifter(STAGE_MUL_START-1);
  in_shift_element         <= element_num_shifter(element_num_shifter'left);

  with size select
    current_vl_bytes <=
    current_vl(log2((VECTOR_LANES*4)) downto 0)          when OPSIZE_BYTE,
    current_vl(log2((VECTOR_LANES*4))-1 downto 0) & '0'  when OPSIZE_HALF,
    current_vl(log2((VECTOR_LANES*4))-2 downto 0) & "00" when others;

  byteena_gen : for gbyte in (VECTOR_LANES*4)-1 downto 0 generate
    current_vl_lt(gbyte) <= '1' when current_vl_lt_ep = '0' or (to_unsigned(gbyte, log2((VECTOR_LANES*4))+1) < unsigned(current_vl_bytes)) else '0';
  end generate byteena_gen;

end architecture rtl;
