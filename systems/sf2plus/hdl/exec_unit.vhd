-- exec_unit.vhd
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

entity exec_unit is
  generic (
    VECTOR_LANES : integer        := 1;
    VCI_INFO_ROM : vci_info_array := DEFAULT_VCI_INFO_ROM;

    MIN_MULTIPLIER_HW : min_size_type := BYTE;

    MULFXP_WORD_FRACTION_BITS : integer range 1 to 31 := 25;
    MULFXP_HALF_FRACTION_BITS : integer range 1 to 15 := 15;
    MULFXP_BYTE_FRACTION_BITS : integer range 1 to 7  := 4;

    CFG_FAM : config_family_type;

    PIPELINE_STAGES : integer := 1;
    STAGE_MUL_START : integer := 1;
    STAGE_MUL_END   : integer := 1;

    ADDR_WIDTH : integer := 1
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    exec_first_cycle         : in std_logic;
    exec_first_column        : in std_logic;
    exec_last_cycle          : in std_logic;
    exec_last_cooldown_cycle : in std_logic;
    exec_read                : in std_logic;
    exec_write               : in std_logic;
    exec_we                  : in std_logic;
    exec_byteena             : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    exec_dest_addr           : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    instruction_pipeline     : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);

    data_a : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    data_b : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);

    accum_first_column : out std_logic;
    accum_byteena      : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    accum_dest_addr    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    exec_out           : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    accum_we           : out std_logic;

    mask_writedata_enables : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);

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

  -- attribute secure_netlist of exec_unit : entity is "OFF";
  -- attribute secure_config  of exec_unit : entity is "OFF";
  -- attribute check_license  of exec_unit : entity is "ipvblox_mxp";

end entity exec_unit;

architecture rtl of exec_unit is
  constant MULTIPLIER_DELAY            : positive := CFG_SEL(CFG_FAM).MULTIPLIER_DELAY;
  constant CONNECTED_DEEP_PIPELINE_VCI : boolean  := connected_deep_pipeline(VCI_INFO_ROM);
  constant MAX_VCI_COUNTDOWN           : natural  := max_countdown(VCI_INFO_ROM);

  signal multiplier_out : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal alu_out        : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal alu_out_reg    : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal alu_byteena    : std_logic_vector((VECTOR_LANES*4)-1 downto 0);

  signal end_uses_custom   : std_logic;
  signal end_p1_uses_mul   : std_logic;
  signal exec_end_vci_info : vci_info_type;

  type   dest_addr_shifter_type is array (natural range <>) of std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal dest_addr_shifter           : dest_addr_shifter_type(MULTIPLIER_DELAY-1 downto 0);
  signal first_column_shifter        : std_logic_vector(MULTIPLIER_DELAY-1 downto 0);
  signal first_cycle_shifter         : std_logic_vector(MULTIPLIER_DELAY-1 downto 0);
  signal last_cycle_shifter          : std_logic_vector(MULTIPLIER_DELAY-1 downto 0);
  signal last_cooldown_cycle_shifter : std_logic_vector(MULTIPLIER_DELAY-1 downto 0);
  signal we_shifter                  : std_logic_vector(MULTIPLIER_DELAY-1 downto 0);
  signal write_shifter               : std_logic_vector(MULTIPLIER_DELAY-1 downto 0);
  signal custom_first_column         : std_logic;
  signal custom_we                   : std_logic;
  signal custom_write                : std_logic;
  signal custom_dest_addr            : std_logic_vector(ADDR_WIDTH-1 downto 0);
begin
  byte_mul_gen : if MIN_MULTIPLIER_HW = BYTE generate
    multiplier_stage : entity work.mul_unit(byte)
      generic map (
        VECTOR_LANES => VECTOR_LANES,

        MULFXP_WORD_FRACTION_BITS => MULFXP_WORD_FRACTION_BITS,
        MULFXP_HALF_FRACTION_BITS => MULFXP_HALF_FRACTION_BITS,
        MULFXP_BYTE_FRACTION_BITS => MULFXP_BYTE_FRACTION_BITS,

        CFG_FAM => CFG_FAM,

        PIPELINE_STAGES => PIPELINE_STAGES,
        STAGE_MUL_START => STAGE_MUL_START,
        STAGE_MUL_END   => STAGE_MUL_END
        )
      port map (
        clk   => clk,
        reset => reset,

        instruction_pipeline => instruction_pipeline,

        data_a => data_a,
        data_b => data_b,

        multiplier_out => multiplier_out
        );
  end generate byte_mul_gen;
  half_mul_gen : if MIN_MULTIPLIER_HW = HALF generate
    multiplier_stage : entity work.mul_unit(half)
      generic map (
        VECTOR_LANES => VECTOR_LANES,

        MULFXP_WORD_FRACTION_BITS => MULFXP_WORD_FRACTION_BITS,
        MULFXP_HALF_FRACTION_BITS => MULFXP_HALF_FRACTION_BITS,
        MULFXP_BYTE_FRACTION_BITS => MULFXP_BYTE_FRACTION_BITS,

        CFG_FAM => CFG_FAM,

        PIPELINE_STAGES => PIPELINE_STAGES,
        STAGE_MUL_START => STAGE_MUL_START,
        STAGE_MUL_END   => STAGE_MUL_END
        )
      port map (
        clk   => clk,
        reset => reset,

        instruction_pipeline => instruction_pipeline,

        data_a => data_a,
        data_b => data_b,

        multiplier_out => multiplier_out
        );
  end generate half_mul_gen;
  word_mul_gen : if MIN_MULTIPLIER_HW = WORD generate
    multiplier_stage : entity work.mul_unit(word)
      generic map (
        VECTOR_LANES => VECTOR_LANES,

        MULFXP_WORD_FRACTION_BITS => MULFXP_WORD_FRACTION_BITS,
        MULFXP_HALF_FRACTION_BITS => MULFXP_HALF_FRACTION_BITS,
        MULFXP_BYTE_FRACTION_BITS => MULFXP_BYTE_FRACTION_BITS,

        CFG_FAM => CFG_FAM,

        PIPELINE_STAGES => PIPELINE_STAGES,
        STAGE_MUL_START => STAGE_MUL_START,
        STAGE_MUL_END   => STAGE_MUL_END
        )
      port map (
        clk   => clk,
        reset => reset,

        instruction_pipeline => instruction_pipeline,

        data_a => data_a,
        data_b => data_b,

        multiplier_out => multiplier_out
        );
  end generate word_mul_gen;


  alu_stage : alu_unit
    generic map (
      VECTOR_LANES => VECTOR_LANES,

      CFG_FAM => CFG_FAM,

      PIPELINE_STAGES => PIPELINE_STAGES,
      STAGE_MUL_START => STAGE_MUL_START
      )
    port map (
      clk   => clk,
      reset => reset,

      exec_byteena         => exec_byteena,
      instruction_pipeline => instruction_pipeline,

      data_a => data_a,
      data_b => data_b,

      mask_writedata_enables => mask_writedata_enables,

      alu_byteena => alu_byteena,
      alu_out     => alu_out
      );

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      end_p1_uses_mul <= op_uses_mul(instruction_pipeline(STAGE_MUL_END).op);
      end_uses_custom <= op_is_custom(instruction_pipeline(STAGE_MUL_END-1).op);
    end if;
  end process;
  exec_out <= multiplier_out when end_p1_uses_mul = '1' else alu_out_reg;

  --Signals to Vector Custom Instructions
  vci_valid <=
    to_onehot(instruction_pipeline(STAGE_MUL_START).op(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0))
    when exec_read = '1' and op_is_custom(instruction_pipeline(STAGE_MUL_START).op) = '1'
    else (others => '0');
  vci_signed <= instruction_pipeline(STAGE_MUL_START).signedness;
  vci_opsize <= instruction_pipeline(STAGE_MUL_START).size;

  vci_vector_start                        <= exec_first_cycle;
  vci_vector_end                          <= exec_last_cycle;
  vci_byte_valid                          <= exec_byteena;
  vci_dest_addr_in(31 downto ADDR_WIDTH)  <= (others => '0');
  vci_dest_addr_in(ADDR_WIDTH-1 downto 0) <= exec_dest_addr;

  --End of exec info is needed for port # and such
  exec_end_vci_info <=
    VCI_INFO_ROM(to_integer(unsigned(instruction_pipeline(STAGE_MUL_END).op(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0))));
  vci_port <= exec_end_vci_info.port_num;

  vci_data_a <= scratchpad_data_to_byte8(data_a);
  vci_flag_a <= scratchpad_data_to_flag(data_a);
  vci_data_b <= scratchpad_data_to_byte8(data_b);
  vci_flag_b <= scratchpad_data_to_flag(data_b);


  --Deep pipeline VCIs need extra logic; shifters
  deep_pipeline_gen : if CONNECTED_DEEP_PIPELINE_VCI = true generate
    signal custom_first_column_shifter : std_logic_vector(MAX_VCI_COUNTDOWN downto 0);
    signal custom_first_column_by_vci  : std_logic_vector(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);
    signal custom_we_shifter           : std_logic_vector(MAX_VCI_COUNTDOWN downto 0);
    signal custom_we_by_vci            : std_logic_vector(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);
    signal custom_write_shifter        : std_logic_vector(MAX_VCI_COUNTDOWN downto 0);
    signal custom_write_by_vci         : std_logic_vector(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);
    signal custom_dest_addr_shifter    : dest_addr_shifter_type(MAX_VCI_COUNTDOWN downto 0);
    signal custom_dest_addr_by_vci     : dest_addr_shifter_type(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);

    signal first_deep_vci   : std_logic;
    signal warming_up       : std_logic;
    signal warmup_countdown : unsigned(imax(0, log2(MAX_VCI_COUNTDOWN+1)-1) downto 0);
  begin
    custom_first_column_shifter(0) <= first_column_shifter(first_column_shifter'left);
    custom_we_shifter(0)           <= we_shifter(we_shifter'left);
    custom_write_shifter(0)        <= write_shifter(write_shifter'left);
    custom_dest_addr_shifter(0)    <= dest_addr_shifter(dest_addr_shifter'left);
    first_deep_vci                 <=
      first_cycle_shifter(first_cycle_shifter'left) and end_uses_custom and exec_end_vci_info.deep_pipeline;
    warming_up <= '1' when warmup_countdown /= to_unsigned(0, warmup_countdown'length)
                  else first_deep_vci;
    process (clk)
    begin  -- process
      if clk'event and clk = '1' then   -- rising clock edge
        if first_deep_vci = '1' then
          warmup_countdown <= exec_end_vci_info.countdown(warmup_countdown'range) -
                              to_unsigned(1, warmup_countdown'length);
        elsif warming_up = '1' then
          warmup_countdown <= warmup_countdown - to_unsigned(1, warmup_countdown'length);
        end if;

        custom_first_column_shifter(custom_first_column_shifter'left downto 1) <=
          custom_first_column_shifter(custom_first_column_shifter'left-1 downto 0);
        custom_we_shifter(custom_we_shifter'left downto 1) <=
          custom_we_shifter(custom_we_shifter'left-1 downto 0);
        custom_write_shifter(custom_write_shifter'left downto 1) <=
          custom_write_shifter(custom_write_shifter'left-1 downto 0);
        --Prevent spurious writebacks
        if ((exec_end_vci_info.deep_pipeline = '1' and last_cooldown_cycle_shifter(last_cooldown_cycle_shifter'left) = '1') or
            (exec_end_vci_info.deep_pipeline = '0' and last_cycle_shifter(last_cycle_shifter'left) = '1')) then
          custom_we_shifter(custom_we_shifter'left downto 1) <=
            (others => '0');
        end if;
        custom_dest_addr_shifter(custom_dest_addr_shifter'left downto 1) <=
          custom_dest_addr_shifter(custom_dest_addr_shifter'left-1 downto 0);
        if reset = '1' then
          warmup_countdown <= to_unsigned(0, warmup_countdown'length);
        end if;
      end if;
    end process;

    select_gen : for gvci in MAX_CUSTOM_INSTRUCTIONS-1 downto 0 generate
      custom_first_column_by_vci(gvci) <=
        custom_first_column_shifter(to_integer(VCI_INFO_ROM(gvci).countdown)) and (not warming_up);
      custom_we_by_vci(gvci) <=
        custom_we_shifter(to_integer(VCI_INFO_ROM(gvci).countdown)) and (not warming_up);
      custom_write_by_vci(gvci) <=
        custom_write_shifter(to_integer(VCI_INFO_ROM(gvci).countdown)) and (not warming_up);
      custom_dest_addr_by_vci(gvci) <=
        custom_dest_addr_shifter(to_integer(VCI_INFO_ROM(gvci).countdown));
    end generate select_gen;

    custom_first_column <= custom_first_column_by_vci(to_integer(unsigned(instruction_pipeline(STAGE_MUL_END).op(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0))));
    custom_we           <= custom_we_by_vci(to_integer(unsigned(instruction_pipeline(STAGE_MUL_END).op(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0))));
    custom_write        <= custom_write_by_vci(to_integer(unsigned(instruction_pipeline(STAGE_MUL_END).op(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0))));
    custom_dest_addr    <= custom_dest_addr_by_vci(to_integer(unsigned(instruction_pipeline(STAGE_MUL_END).op(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0))));
  end generate deep_pipeline_gen;
  no_deep_pipeline_gen : if CONNECTED_DEEP_PIPELINE_VCI /= true generate
    custom_first_column <= first_column_shifter(first_column_shifter'left);
    custom_we           <= we_shifter(we_shifter'left);
    custom_write        <= write_shifter(write_shifter'left);
    custom_dest_addr    <= dest_addr_shifter(dest_addr_shifter'left);
  end generate no_deep_pipeline_gen;

  increase_pipeline_reg : process (clk)
  begin  -- process increase_pipeline_reg
    if clk'event and clk = '1' then     -- rising clock edge
      first_column_shifter(0)                                  <= exec_first_column;
      first_column_shifter(first_column_shifter'left downto 1) <=
        first_column_shifter(first_column_shifter'left-1 downto 0);
      first_cycle_shifter(0)                                 <= exec_first_cycle;
      first_cycle_shifter(first_cycle_shifter'left downto 1) <=
        first_cycle_shifter(first_cycle_shifter'left-1 downto 0);
      last_cycle_shifter(0)                                <= exec_last_cycle;
      last_cycle_shifter(last_cycle_shifter'left downto 1) <=
        last_cycle_shifter(last_cycle_shifter'left-1 downto 0);
      last_cooldown_cycle_shifter(0)                                         <= exec_last_cooldown_cycle;
      last_cooldown_cycle_shifter(last_cooldown_cycle_shifter'left downto 1) <=
        last_cooldown_cycle_shifter(last_cooldown_cycle_shifter'left-1 downto 0);
      we_shifter(0)                                      <= exec_we;
      we_shifter(we_shifter'left downto 1)               <= we_shifter(we_shifter'left-1 downto 0);
      write_shifter(0)                                   <= exec_write;
      write_shifter(write_shifter'left downto 1)         <= write_shifter(write_shifter'left-1 downto 0);
      dest_addr_shifter(0)                               <= exec_dest_addr;
      dest_addr_shifter(dest_addr_shifter'left downto 1) <= dest_addr_shifter(dest_addr_shifter'left-1 downto 0);

      --Normal (not VCI) assignments
      accum_dest_addr    <= dest_addr_shifter(dest_addr_shifter'left);
      accum_byteena      <= alu_byteena;
      alu_out_reg        <= alu_out;
      accum_first_column <= first_column_shifter(first_column_shifter'left);
      accum_we           <= we_shifter(we_shifter'left);

      --VCI assignments (dest addr optional)
      if end_uses_custom = '1' then
        accum_first_column <= custom_first_column;
        accum_we           <= custom_we;

        accum_byteena <= vci_byteenable;
        alu_out_reg <= flag_byte8_to_scratchpad_data(vci_flag_out,
                                                     vci_data_out,
                                                     VECTOR_LANES);

        accum_dest_addr <= custom_dest_addr;
        if exec_end_vci_info.modifies_dest_addr = '1' then
          accum_dest_addr <= vci_dest_addr_out(ADDR_WIDTH-1 downto 0);
        end if;
      end if;

      --Disable byte enables to accumulator if not writing back
      if ((end_uses_custom = '0' and write_shifter(write_shifter'left) = '0') or
          (end_uses_custom = '1' and custom_write = '0')) then
        accum_byteena <= (others => '0');
      end if;
    end if;
  end process increase_pipeline_reg;

end architecture rtl;
