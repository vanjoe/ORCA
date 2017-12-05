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
  generic (
    REGISTER_SIZE         : positive;
    SIGN_EXTENSION_SIZE   : positive;
    INTERRUPT_VECTOR      : std_logic_vector(31 downto 0);
    POWER_OPTIMIZED       : boolean;
    MULTIPLY_ENABLE       : boolean;
    DIVIDE_ENABLE         : boolean;
    SHIFTER_MAX_CYCLES    : natural;
    COUNTER_LENGTH        : natural;
    ENABLE_EXCEPTIONS     : boolean;
    ENABLE_EXT_INTERRUPTS : natural range 0 to 1;
    NUM_EXT_INTERRUPTS    : positive range 1 to 32;
    LVE_ENABLE            : natural;
    SCRATCHPAD_SIZE       : integer;
    FAMILY                : string
    );
  port (
    clk            : in std_logic;
    scratchpad_clk : in std_logic;
    reset          : in std_logic;

    flush_pipeline  : out std_logic;
    execute_flushed : out std_logic;
    pipeline_empty  : in  std_logic;
    program_counter : in  unsigned(REGISTER_SIZE-1 downto 0);

    --From previous stage
    valid_input        : in     std_logic;
    pc_current         : in     unsigned(REGISTER_SIZE-1 downto 0);
    instruction        : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_instr       : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_valid       : in     std_logic;
    rs1_data           : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data           : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs3_data           : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    sign_extension     : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    stall_from_execute : buffer std_logic;

    --To PC correction
    to_pc_correction_data    : out    unsigned(REGISTER_SIZE-1 downto 0);
    to_pc_correction_valid   : buffer std_logic;
    from_pc_correction_ready : in     std_logic;

    --To register file
    wb_sel    : buffer std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    wb_data   : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_enable : buffer std_logic;

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

    global_interrupts : in     std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);
    interrupt_pending : buffer std_logic
    );
end entity execute;

architecture behavioural of execute is
  alias rd is instruction (REGISTER_RD'range);
  alias rs1 is instruction(REGISTER_RS1'range);
  alias rs2 is instruction(REGISTER_RS2'range);
  alias rs3 is instruction(REGISTER_RD'range);
  alias opcode is instruction(MAJOR_OP'range);

  signal stall_to_execute : std_logic;
  signal syscall_ready    : std_logic;


  -- various writeback sources
  signal br_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal alu_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ld_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sys_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal br_data_enable     : std_logic;
  signal alu_data_out_valid : std_logic;
  signal ld_data_enable     : std_logic;
  signal sys_data_enable    : std_logic;
  signal less_than          : std_logic;
  signal wb_mux             : std_logic_vector(1 downto 0);

  signal alu_ready : std_logic;

  signal branch_to_pc_correction_valid : std_logic;
  signal branch_to_pc_correction_data  : unsigned(REGISTER_SIZE-1 downto 0);

  signal syscall_to_pc_correction_valid : std_logic;
  signal syscall_to_pc_correction_data  : unsigned(REGISTER_SIZE-1 downto 0);

  signal rs1_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs3_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal writeback_stall_from_lsu : std_logic;
  signal lsu_ready                : std_logic;
  signal load_in_progress         : std_logic;

  signal lve_ready            : std_logic;
  signal lve_executing        : std_logic;
  signal lve_was_executing    : std_logic;
  signal lve_alu_data1        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal lve_alu_data2        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal lve_alu_source_valid : std_logic;

  signal valid_instr : std_logic;
  signal wb_valid    : std_logic;

  constant R_ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

  type fwd_mux_t is (ALU_FWD, NO_FWD);
  signal rs1_mux : fwd_mux_t;
  signal rs2_mux : fwd_mux_t;
  signal rs3_mux : fwd_mux_t;

  signal finished_instr : std_logic;

  alias subseq_rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is subseq_instr(REGISTER_RS1'range);
  alias subseq_rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is subseq_instr(REGISTER_RS2'range);
  alias subseq_rs3 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is subseq_instr(REGISTER_RD'range);

  signal use_after_produce_stall : std_logic;

  signal simd_op_size : std_logic_vector(1 downto 0);
begin
  --These stalls happen during the writeback cycle
  stall_to_execute <= use_after_produce_stall or writeback_stall_from_lsu;
  valid_instr      <= valid_input and (not stall_to_execute);

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

  rs1_data_fwd <= lve_alu_data1 when lve_alu_source_valid = '1' else
                  alu_data_out when rs1_mux = ALU_FWD else
                  rs1_data;
  rs2_data_fwd <= lve_alu_data2 when lve_alu_source_valid = '1' else
                  alu_data_out when rs2_mux = ALU_FWD else
                  rs2_data;
  rs3_data_fwd <= alu_data_out when rs3_mux = ALU_FWD else
                  rs3_data;


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
                bool_to_int(alu_data_out_valid)) <= 1 and reset = '0' report "Multiple Data Enables Asserted" severity failure;
      end if;
    end if;
  end process;

  wb_mux <= "00" when sys_data_enable = '1' else
            "01" when load_in_progress = '1' else
            "10" when br_data_enable = '1' else
            "11";                       --when alu_data_out_valid = '1'

  with wb_mux select
    wb_data <=
    sys_data_out when "00",
    ld_data_out  when "01",
    br_data_out  when "10",
    alu_data_out when others;

  wb_valid <= (sys_data_enable or
               ld_data_enable or
               br_data_enable or
               (alu_data_out_valid and (not lve_was_executing)));

  wb_enable <= wb_valid when wb_sel /= R_ZERO else '0';

  stall_from_execute <= valid_input and (stall_to_execute or
                                         (not lsu_ready) or
                                         (not alu_ready and not lve_was_executing) or
                                         (not lve_ready) or
                                         (not syscall_ready));

  --No forward stall; system calls, loads, and branches aren't forwarded.  Since
  --branches clear the pipeline no need to check for stall here.
  use_after_produce_stall <= sys_data_enable or load_in_progress when wb_sel = rs1 or wb_sel = rs2 or (wb_sel = rs3 and LVE_ENABLE=1) else '0';

  process(clk)
  begin
    if rising_edge(clk) then
      lve_was_executing <= lve_executing;
      if stall_to_execute = '0' then
        rs1_mux <= NO_FWD;
        rs2_mux <= NO_FWD;
        rs3_mux <= NO_FWD;
        wb_sel  <= rd;
      end if;
      if valid_instr = '1' and subseq_valid = '1' then
        if opcode = LUI_OP or opcode = AUIPC_OP or opcode = ALU_OP or opcode = ALUI_OP then
          if rd /= R_ZERO then
            if rd = subseq_rs1 then
              rs1_mux <= ALU_FWD;
            end if;
            if rd = subseq_rs2 then
              rs2_mux <= ALU_FWD;
            end if;
            if rd = subseq_rs3 then
              rs3_mux <= ALU_FWD;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  alu : arithmetic_unit
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIMD_ENABLE         => false,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      POWER_OPTIMIZED     => POWER_OPTIMIZED,
      MULTIPLY_ENABLE     => MULTIPLY_ENABLE,
      DIVIDE_ENABLE       => DIVIDE_ENABLE,
      SHIFTER_MAX_CYCLES  => SHIFTER_MAX_CYCLES,
      FAMILY              => FAMILY
      )
    port map (
      clk                => clk,
      valid_instr        => valid_instr,
      simd_op_size       => simd_op_size,
      stall_from_execute => stall_from_execute,
      rs1_data           => rs1_data_fwd,
      rs2_data           => rs2_data_fwd,
      instruction        => instruction,
      sign_extension     => sign_extension,
      pc_current         => pc_current,
      data_out           => alu_data_out,
      data_out_valid     => alu_data_out_valid,
      less_than          => less_than,
      alu_ready          => alu_ready,

      lve_data1        => lve_alu_data1,
      lve_data2        => lve_alu_data2,
      lve_source_valid => lve_alu_source_valid
      );


  branch : branch_unit
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(
      clk                      => clk,
      reset                    => reset,
      valid                    => valid_instr,
      stall                    => stall_to_execute,
      rs1_data                 => rs1_data_fwd,
      rs2_data                 => rs2_data_fwd,
      pc_current               => pc_current,
      instr                    => instruction,
      less_than                => less_than,
      sign_extension           => sign_extension,
      data_out                 => br_data_out,
      data_enable              => br_data_enable,
      to_pc_correction_data    => branch_to_pc_correction_data,
      to_pc_correction_valid   => branch_to_pc_correction_valid,
      from_pc_correction_ready => from_pc_correction_ready
      );

  ls_unit : load_store_unit
    generic map(
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(
      clk                      => clk,
      reset                    => reset,
      valid                    => valid_instr,
      rs1_data                 => rs1_data_fwd,
      rs2_data                 => rs2_data_fwd,
      instruction              => instruction,
      sign_extension           => sign_extension,
      writeback_stall_from_lsu => writeback_stall_from_lsu,
      lsu_ready                => lsu_ready,
      data_out                 => ld_data_out,
      data_enable              => ld_data_enable,
      load_in_progress         => load_in_progress,

      oimm_address       => lsu_oimm_address,
      oimm_byteenable    => lsu_oimm_byteenable,
      oimm_requestvalid  => lsu_oimm_requestvalid,
      oimm_readnotwrite  => lsu_oimm_readnotwrite,
      oimm_writedata     => lsu_oimm_writedata,
      oimm_readdata      => lsu_oimm_readdata,
      oimm_readdatavalid => lsu_oimm_readdatavalid,
      oimm_waitrequest   => lsu_oimm_waitrequest
      );

  execute_flushed <= (not valid_input) and (not writeback_stall_from_lsu);

  syscall : system_calls
    generic map (
      REGISTER_SIZE         => REGISTER_SIZE,
      INTERRUPT_VECTOR      => INTERRUPT_VECTOR,
      POWER_OPTIMIZED       => POWER_OPTIMIZED,
      ENABLE_EXCEPTIONS     => ENABLE_EXCEPTIONS,
      ENABLE_EXT_INTERRUPTS => ENABLE_EXT_INTERRUPTS,
      NUM_EXT_INTERRUPTS    => NUM_EXT_INTERRUPTS,
      COUNTER_LENGTH        => COUNTER_LENGTH
      )
    port map (
      clk   => clk,
      reset => reset,
      valid => valid_instr,

      syscall_ready => syscall_ready,

      rs1_data    => rs1_data_fwd,
      instruction => instruction,
      data_out    => sys_data_out,
      data_enable => sys_data_enable,

      pc_current               => pc_current,
      to_pc_correction_data    => syscall_to_pc_correction_data,
      to_pc_correction_valid   => syscall_to_pc_correction_valid,
      from_pc_correction_ready => from_pc_correction_ready,

      interrupt_pending => interrupt_pending,
      pipeline_empty    => pipeline_empty,
      global_interrupts => global_interrupts,

      program_counter => program_counter
      );

  enable_lve : if LVE_ENABLE /= 0 generate
  begin
    lve : lve_top
      generic map (
        REGISTER_SIZE    => REGISTER_SIZE,
        SCRATCHPAD_SIZE  => SCRATCHPAD_SIZE,
        POWER_OPTIMIZED  => POWER_OPTIMIZED,
        SLAVE_DATA_WIDTH => REGISTER_SIZE,
        FAMILY           => FAMILY
        )
      port map (
        clk            => clk,
        scratchpad_clk => scratchpad_clk,
        reset          => reset,
        instruction    => instruction,
        valid_instr    => valid_instr,

        rs1_data       => rs1_data_fwd,
        rs2_data       => rs2_data_fwd,
        rs3_data       => rs3_data_fwd,

        slave_address  => sp_address,
        slave_read_en  => sp_read_en,
        slave_write_en => sp_write_en,
        slave_byte_en  => sp_byte_en,
        slave_data_in  => sp_writedata,
        slave_data_out => sp_readdata,
        slave_ack      => sp_ack,

        lve_ready            => lve_ready,
        lve_executing        => lve_executing,
        lve_alu_data1        => lve_alu_data1,
        lve_alu_data2        => lve_alu_data2,
        lve_alu_op_size      => simd_op_size,
        lve_alu_source_valid => lve_alu_source_valid,
        lve_alu_result       => alu_data_out,
        lve_alu_result_valid => alu_data_out_valid
        );
  end generate enable_lve;

  n_enable_lve : if LVE_ENABLE = 0 generate
    lve_ready            <= '1';
    lve_executing        <= '0';
    simd_op_size         <= LVE_WORD_SIZE;
    lve_alu_source_valid <= '0';
    lve_alu_data1        <= (others => '-');
    lve_alu_data2        <= (others => '-');
    sp_readdata          <= (others => '-');
    sp_ack               <= '-';
  end generate n_enable_lve;



  to_pc_correction_valid <= syscall_to_pc_correction_valid or branch_to_pc_correction_valid;
  to_pc_correction_data  <= syscall_to_pc_correction_data when syscall_to_pc_correction_valid = '1' else
                           branch_to_pc_correction_data;
  flush_pipeline <= to_pc_correction_valid;


  -----------------------------------------------------------------------------
  -- This process does some debug printing during simulation,
  -- it should have no impact on synthesis
  -----------------------------------------------------------------------------
--pragma translate_off
  my_print : process(clk)
    variable my_line          : line;   -- type 'line' comes from textio
    variable last_valid_pc    : unsigned(REGISTER_SIZE-1 downto 0);
    type register_list is array(0 to 31) of std_logic_vector(REGISTER_SIZE-1 downto 0);
    variable shadow_registers : register_list := (others => (others => '0'));

    constant DEBUG_WRITEBACK : boolean := false;

  begin
    if rising_edge(clk) then

      if wb_enable = '1' and DEBUG_WRITEBACK then
        write(my_line, string'("WRITEBACK: PC = "));
        hwrite(my_line, std_logic_vector(last_valid_pc));
        shadow_registers(to_integer(unsigned(wb_sel))) := wb_data;
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
        write(my_line, string'("executing pc = "));       -- formatting
        hwrite(my_line, (std_logic_vector(pc_current)));  -- format type std_logic_vector as hex
        write(my_line, string'(" instr =  "));            -- formatting
        hwrite(my_line, (instruction));  -- format type std_logic_vector as hex
        if stall_from_execute = '1' then
          write(my_line, string'(" stalling"));           -- formatting
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
