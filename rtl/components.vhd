library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.utils.all;

package rv_components is
  component orca is
    generic (
      REGISTER_SIZE      : integer              := 32;
      RESET_VECTOR       : natural              := 16#00000200#;
      MULTIPLY_ENABLE    : natural range 0 to 1 := 0;
      DIVIDE_ENABLE      : natural range 0 to 1 := 0;
      SHIFTER_MAX_CYCLES : natural;
      COUNTER_LENGTH     : natural              := 64;
      BRANCH_PREDICTORS  : natural              := 0;
      PIPELINE_STAGES    : natural range 4 to 5 := 5;
      FORWARD_ALU_ONLY   : natural range 0 to 1 := 1;
      MXP_ENABLE         : natural range 0 to 1 := 0);
    port(
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;


      --avalon master bus
      avm_data_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_data_byteenable    : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      avm_data_read          : out std_logic;
      avm_data_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => 'X');
      avm_data_write         : out std_logic;
      avm_data_writedata     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_data_waitrequest   : in  std_logic                                  := '0';
      avm_data_readdatavalid : in  std_logic                                  := '0';

      --avalon master bus
      avm_instruction_address       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      avm_instruction_read          : out std_logic;
      avm_instruction_readdata      : in  std_logic_vector(REGISTER_SIZE-1 downto 0) := (others => 'X');
      avm_instruction_waitrequest   : in  std_logic                                  := '0';
      avm_instruction_readdatavalid : in  std_logic                                  := '0';

      global_interrupts : in std_logic_vector(31 downto 0)
      );
  end component orca;

  component orca_wishbone is
    generic (
      REGISTER_SIZE      : integer              := 32;
      RESET_VECTOR       : natural              := 16#00000200#;
      MULTIPLY_ENABLE    : natural range 0 to 1 := 0;
      DIVIDE_ENABLE      : natural range 0 to 1 := 0;
      SHIFTER_MAX_CYCLES : natural              := 8;
      COUNTER_LENGTH     : natural              := 64;
      BRANCH_PREDICTORS  : natural              := 0;
      PIPELINE_STAGES    : natural range 4 to 5 := 5;
      FORWARD_ALU_ONLY   : natural range 0 to 1 := 1;
      MXP_ENABLE         : natural range 0 to 1 := 0);
    port(
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;

      data_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_DAT_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_WE_O    : out std_logic;
      data_SEL_O   : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      data_STB_O   : out std_logic;
      data_ACK_I   : in  std_logic;
      data_CYC_O   : out std_logic;
      data_CTI_O   : out std_logic_vector(2 downto 0);
      data_STALL_I : in  std_logic;

      instr_ADR_O   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_DAT_I   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_STB_O   : out std_logic;
      instr_ACK_I   : in  std_logic;
      instr_CYC_O   : out std_logic;
      instr_CTI_O   : out std_logic_vector(2 downto 0);
      instr_STALL_I : in  std_logic;

      global_interrupts : in std_logic_vector(31 downto 0) := (others => '0')


      );
  end component orca_wishbone;

  component decode is
    generic(
      REGISTER_SIZE       : positive;
      REGISTER_NAME_SIZE  : positive;
      INSTRUCTION_SIZE    : positive;
      SIGN_EXTENSION_SIZE : positive;
      PIPELINE_STAGES     : natural range 1 to 2);
    port(
      clk         : in std_logic;
      reset       : in std_logic;
      stall       : in std_logic;
      flush       : in std_logic;
      instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      valid_input : in std_logic;
      --writeback signals
      wb_sel      : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      wb_data     : in std_logic_vector(REGISTER_SIZE -1 downto 0);
      wb_enable   : in std_logic;

      --output signals
      rs1_data       : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      rs2_data       : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      sign_extension : out std_logic_vector(SIGN_EXTENSION_SIZE -1 downto 0);
      --inputs just for carrying to next pipeline stage
      br_taken_in    : in  std_logic;
      pc_curr_in     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      br_taken_out   : out std_logic;
      pc_curr_out    : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_out      : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      subseq_instr   : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      valid_output   : out std_logic);
  end component decode;

  component execute is
    generic(
      REGISTER_SIZE       : positive;
      REGISTER_NAME_SIZE  : positive;
      INSTRUCTION_SIZE    : positive;
      SIGN_EXTENSION_SIZE : positive;
      RESET_VECTOR        : natural;
      MULTIPLY_ENABLE     : boolean;
      DIVIDE_ENABLE       : boolean;
      SHIFTER_MAX_CYCLES  : natural;
      COUNTER_LENGTH      : natural;
      FORWARD_ALU_ONLY    : boolean;
      MXP_ENABLE          : boolean);
    port(
      clk            : in std_logic;
      scratchpad_clk : in std_logic;
      reset          : in std_logic;
      valid_input    : in std_logic;

      br_taken_in  : in std_logic;
      pc_current   : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction  : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      subseq_instr : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

      rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      sign_extension : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

      wb_sel  : buffer std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
      wb_data : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
      wb_en   : buffer std_logic;


      branch_pred    : out    std_logic_vector(REGISTER_SIZE*2+3-1 downto 0);
      stall_pipeline : buffer std_logic;
      pipeline_empty : in     std_logic;

      instruction_fetch_pc : in std_logic_vector(REGISTER_SIZE-1 downto 0);

      --memory-bus
      address     : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      byte_en     : out std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      write_en    : out std_logic;
      read_en     : out std_logic;
      writedata   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      readdata    : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      waitrequest : in  std_logic;
      datavalid   : in  std_logic;

      mtime_i             : in  std_logic_vector(63 downto 0);
      mip_mtip_i          : in  std_logic;
      mip_msip_i          : in  std_logic;
      mip_meip_i          : in  std_logic;
      interrupt_pending_o : out std_logic);
  end component execute;

  component instruction_fetch is
    generic (
      REGISTER_SIZE     : positive;
      INSTRUCTION_SIZE  : positive;
      RESET_VECTOR      : natural;
      BRANCH_PREDICTORS : natural);
    port (
      clk   : in std_logic;
      reset : in std_logic;
      stall : in std_logic;

      branch_pred : in std_logic_vector(REGISTER_SIZE*2+3-1 downto 0);

      instr_out       : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      pc_out          : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      br_taken        : out std_logic;
      valid_instr_out : out std_logic;

      read_address   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      read_en        : out std_logic;
      read_data      : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      read_datavalid : in  std_logic;
      read_wait      : in  std_logic;

      instruction_fetch_pc : out std_logic_vector(REGISTER_SIZE-1 downto 0);

      interrupt_pending : in std_logic);
  end component instruction_fetch;

  component arithmetic_unit is
    generic (
      INSTRUCTION_SIZE    : integer;
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer;
      MULTIPLY_ENABLE     : boolean;
      DIVIDE_ENABLE       : boolean;
      SHIFTER_MAX_CYCLES  : natural
      );
    port (
      clk               : in  std_logic;
      stall_in          : in  std_logic;
      valid             : in  std_logic;
      rs1_data          : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data          : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction       : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      sign_extension    : in  std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
      program_counter   : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_out          : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_enable       : out std_logic;
      illegal_alu_instr : out std_logic;
      less_than         : out std_logic;
      stall_out         : out std_logic;

      mxp_data1  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      mxp_data2  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      mxp_enable : in  std_logic;
      mxp_result : out std_logic_vector(REGISTER_SIZE-1 downto 0)

      );
  end component arithmetic_unit;

  component branch_unit is
    generic (
      REGISTER_SIZE       : integer;
      INSTRUCTION_SIZE    : integer;
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
      data_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_out_en    : out std_logic;
      is_branch      : out std_logic;
      br_taken_out   : out std_logic;
      new_pc         : out std_logic_vector(REGISTER_SIZE-1 downto 0);  --next pc
      bad_predict    : out std_logic
      );
  end component branch_unit;

  component load_store_unit is
    generic (
      REGISTER_SIZE       : integer;
      SIGN_EXTENSION_SIZE : integer;
      INSTRUCTION_SIZE    : integer);
    port (
      clk            : in     std_logic;
      reset          : in     std_logic;
      valid          : in     std_logic;
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
      write_en       : out    std_logic;
      read_en        : out    std_logic;
      write_data     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
      read_data      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      waitrequest    : in     std_logic;
      readvalid      : in     std_logic);
  end component load_store_unit;

  component true_dual_port_ram_single_clock is
    generic (
      DATA_WIDTH : natural := 8;
      ADDR_WIDTH : natural := 6
      );
    port (
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
  end component true_dual_port_ram_single_clock;

  component byte_enabled_true_dual_port_ram is
    generic (
      BYTES      : natural := 4;
      ADDR_WIDTH : natural);
    port (
      clk    : in  std_logic;
      addr1  : in  natural range 0 to 2**ADDR_WIDTH-1;
      addr2  : in  natural range 0 to 2**ADDR_WIDTH-1;
      wdata1 : in  std_logic_vector(BYTES*8-1 downto 0);
      wdata2 : in  std_logic_vector(BYTES*8-1 downto 0);
      we1    : in  std_logic;
      be1    : in  std_logic_vector(BYTES-1 downto 0);
      we2    : in  std_logic;
      be2    : in  std_logic_vector(BYTES-1 downto 0);
      rdata1 : out std_logic_vector(BYTES*8-1 downto 0);
      rdata2 : out std_logic_vector(BYTES*8-1 downto 0));
  end component byte_enabled_true_dual_port_ram;

  component instruction_rom is
    generic (
      REGISTER_SIZE : integer;
      ROM_SIZE      : integer;
      PORTS         : natural range 1 to 2);
    port (
      clk        : in std_logic;
      instr_addr : in natural range 0 to ROM_SIZE -1;
      data_addr  : in natural range 0 to ROM_SIZE -1;
      instr_re   : in std_logic;
      data_re    : in std_logic;

      data_out        : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_out       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_wait      : out std_logic;
      data_wait       : out std_logic;
      instr_readvalid : out std_logic;
      data_readvalid  : out std_logic);
  end component instruction_rom;

  component single_port_rom is
    generic (
      DATA_WIDTH : natural := 8;
      ADDR_WIDTH : natural := 8
      );
    port (
      clk  : in  std_logic;
      addr : in  natural range 0 to 2**ADDR_WIDTH - 1;
      q    : out std_logic_vector((DATA_WIDTH -1) downto 0)
      );
  end component single_port_rom;

  component dual_port_rom is
    generic (
      DATA_WIDTH : natural := 8;
      ADDR_WIDTH : natural := 8
      );
    port (
      clk    : in  std_logic;
      addr_a : in  natural range 0 to 2**ADDR_WIDTH - 1;
      addr_b : in  natural range 0 to 2**ADDR_WIDTH - 1;
      q_a    : out std_logic_vector((DATA_WIDTH -1) downto 0);
      q_b    : out std_logic_vector((DATA_WIDTH -1) downto 0)
      );
  end component dual_port_rom;


  component register_file
    generic(
      REGISTER_SIZE      : positive;
      REGISTER_NAME_SIZE : positive);
    port(
      clk              : in std_logic;
      stall            : in std_logic;
      valid_input      : in std_logic;
      rs1_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      rs2_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      writeback_sel    : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
      writeback_data   : in std_logic_vector(REGISTER_SIZE -1 downto 0);
      writeback_enable : in std_logic;

      rs1_data : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      rs2_data : out std_logic_vector(REGISTER_SIZE -1 downto 0));
  end component register_file;

  component pc_incr is
    generic (
      REGISTER_SIZE    : positive;
      INSTRUCTION_SIZE : positive);
    port (
      pc          : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr       : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      valid_instr : in  std_logic;
      next_pc     : out std_logic_vector(REGISTER_SIZE-1 downto 0));
  end component pc_incr;

  component wait_cycle_bram is
    generic (
      BYTES       : natural;
      ADDR_WIDTH  : natural;
      WAIT_STATES : natural);
    port (
      clk    : in std_logic;
      addr1  : in natural range 0 to 2**ADDR_WIDTH-1;
      addr2  : in natural range 0 to 2**ADDR_WIDTH-1;
      wdata1 : in std_logic_vector(BYTES*8-1 downto 0);
      wdata2 : in std_logic_vector(BYTES*8-1 downto 0);
      re1    : in std_logic;
      re2    : in std_logic;
      we1    : in std_logic;
      be1    : in std_logic_vector(BYTES-1 downto 0);
      we2    : in std_logic;
      be2    : in std_logic_vector(BYTES-1 downto 0);

      rdata1     : out std_logic_vector(BYTES*8-1 downto 0);
      rdata2     : out std_logic_vector(BYTES*8-1 downto 0);
      wait1      : out std_logic;
      wait2      : out std_logic;
      readvalid1 : out std_logic;
      readvalid2 : out std_logic);
  end component wait_cycle_bram;

  component upper_immediate is
    generic (
      REGISTER_SIZE    : positive;
      INSTRUCTION_SIZE : positive);
    port (
      clk        : in  std_logic;
      valid      : in  std_logic;
      instr      : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      pc_current : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_out   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      data_en    : out std_logic);
  end component upper_immediate;

  component system_calls is
    generic (
      REGISTER_SIZE    : natural;
      INSTRUCTION_SIZE : natural;
      RESET_VECTOR     : natural;
      COUNTER_LENGTH   : natural);
    port (
      clk         : in std_logic;
      reset       : in std_logic;
      valid       : in std_logic;
      rs1_data    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

      finished_instr : in std_logic;

      wb_data : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      wb_en   : out std_logic;


      current_pc    : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      pc_correction : out std_logic_vector(REGISTER_SIZE -1 downto 0);
      pc_corr_en    : out std_logic;

      illegal_alu_instr : in std_logic;

      use_after_load_stall : in std_logic;
      predict_corr         : in std_logic;
      load_stall           : in std_logic;

      mtime_i    : in std_logic_vector(63 downto 0);
      mip_mtip_i : in std_logic;
      mip_msip_i : in std_logic;
      mip_meip_i : in std_logic;

      interrupt_pending_o : out std_logic;
      pipeline_empty      : in  std_logic;

      instruction_fetch_pc : in std_logic_vector(REGISTER_SIZE-1 downto 0);
      br_bad_predict       : in std_logic;
      br_new_pc            : in std_logic_vector(REGISTER_SIZE-1 downto 0));
  end component system_calls;
  component mxp_top is
    generic(
      REGISTER_SIZE    : natural;
      INSTRUCTION_SIZE : natural;
      SLAVE_DATA_WIDTH : natural := 32);
    port(
      clk            : in     std_logic;
      scratchpad_clk : in     std_logic;
      reset          : in     std_logic;
      instruction    : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      valid_instr    : in     std_logic;
      rs1_data       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      rs2_data       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
      instr_running  : buffer std_logic;

      slave_address  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      slave_read_en  : in  std_logic;
      slave_write_en : in  std_logic;
      slave_byte_en  : in  std_logic_vector(SLAVE_DATA_WIDTH/8 -1 downto 0);
      slave_data_in  : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
      slave_data_out : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
      slave_wait     : out std_logic;


      mxp_data1  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      mxp_data2  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      mxp_enable : out std_logic;
      alu_stall  : in  std_logic;
      mxp_result : in  std_logic_vector(REGISTER_SIZE-1 downto 0)

      );
  end component;


  component plic is
    generic (REGISTER_SIZE : integer := 32);
    port (
      mtime_o    : out std_logic_vector(63 downto 0);
      mip_mtip_o : out std_logic;
      mip_msip_o : out std_logic;
      mip_meip_o : out std_logic;

      global_interrupts : in std_logic_vector(31 downto 0);

      -- Avalon bus
      clk                : in  std_logic;
      reset              : in  std_logic;
      plic_address       : in  std_logic_vector(7 downto 0);
      plic_byteenable    : in  std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
      plic_read          : in  std_logic;
      plic_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
      plic_response      : out std_logic_vector(1 downto 0);
      plic_write         : in  std_logic;
      plic_writedata     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
      plic_lock          : in  std_logic;
      plic_waitrequest   : out std_logic;
      plic_readdatavalid : out std_logic);
  end component plic;

  component gateway is
    port (
      clk   : in std_logic;
      reset : in std_logic;

      global_interrupts     : in  std_logic_vector(31 downto 0);
      edge_sensitive_vector : in  std_logic_vector(31 downto 0);
      interrupt_claimed     : in  std_logic_vector(31 downto 0);
      interrupt_complete    : in  std_logic_vector(31 downto 0);
      pending_interrupts    : out std_logic_vector(31 downto 0));
  end component gateway;

end package rv_components;
